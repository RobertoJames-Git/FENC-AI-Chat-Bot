# database_actions.py
from database.database_connection import get_db_connection
from utility.hash_utils import hash_text, verify_hash
from utility.send_mail import send_activation_email
import uuid
import datetime

database_conn_error_msg = "Unable to connect to database"

async def email_exist(email: str):
    pool = await get_db_connection()
    if pool is None:
        return {"status": "database error", "message": database_conn_error_msg}

    try:
        async with pool.acquire() as conn:
            count = await conn.fetchval(
                "SELECT COUNT(*) FROM student WHERE email = $1",
                email
            )

        if count > 0:
            return {"status": "exists", "message": "Email is already registered"}
        else:
            return {"status": "available", "message": "Email is not registered"}
    except Exception as e:
        return {"status": "error", "message": f"Database query failed: {str(e)}"}



async def account_is_active(email: str):
    pool = await get_db_connection()
    if pool is None:
        return {"status": "database error", "message": database_conn_error_msg}

    try:
        async with pool.acquire() as conn:
            count = await conn.fetchval(
                "SELECT COUNT(*) FROM student_account_activation WHERE is_active = TRUE AND email = $1;",
                email
            )

        if count > 0:
            return {"status": True, "message": "Account is active"}
        else:
            return {"status": False, "message": "Go to your email and activate your account"}
    except Exception as e:
        print("Database Query failed:", str(e))
        return {"status": "error", "message": "Failed to verify credentials"}


async def insert_student(email: str, fname: str, lname: str, plain_password: str) -> list:
    pool = await get_db_connection()
    if pool is None:
        return [False, database_conn_error_msg]

    try:
        async with pool.acquire() as conn:
            # Hash password
            hashed_password = hash_text(plain_password)

            # Generate and hash token
            raw_token = uuid.uuid4().hex
            hashed_token = hash_text(raw_token)

            # Call stored procedure (Postgres syntax: SELECT function_name(...))
            await conn.execute(
                "SELECT insert_student_with_activation($1, $2, $3, $4, $5);",
                email, fname, lname, hashed_password, hashed_token
            )

            # Send activation email
            send_activation_email(fname, lname, email, raw_token)

        return [True, "Student and activation record added successfully"]

    except Exception as e:
        if "duplicate key" in str(e).lower():
            return [False, "Email already exists"]
        print("Database error:", str(e))
        return [False, "Error adding student"]


async def get_hashed_password_and_fullname(email: str):
    pool = await get_db_connection()
    if pool is None:
        return {"status": "db_error", "message": database_conn_error_msg}

    try:
        async with pool.acquire() as conn:
            record = await conn.fetchrow(
                "SELECT fname, lname, password FROM student WHERE email = $1;",
                email
            )

        if record is None:
            return {"status": "invalid_credentials", "message": "Email and/or password is incorrect"}

        return {
            "status": "success",
            "fullname": f"{record['fname']} {record['lname']}",
            "hash_pwd": record['password']
        }

    except Exception as e:
        print("Database error:", str(e))
        return {"status": "db_error", "message": "Database query failed"}



async def process_activation(email: str, token: str):
    pool = await get_db_connection()
    if pool is None:
        return {"status": "error", "message": database_conn_error_msg}

    try:
        async with pool.acquire() as conn:
            # Fetch activation record
            record = await conn.fetchrow(
                "SELECT token, token_sent, is_active FROM student_account_activation WHERE email = $1;",
                email
            )

            if not record:
                return {"status": "not_found", "message": "Activation record not found"}

            # Already active
            if record["is_active"]:
                return {"status": "already_active", "message": "Account already activated"}

            # Check expiry (10 minutes)
            token_sent_time = record["token_sent"]
            now = datetime.datetime.now()
            expiry_time = token_sent_time + datetime.timedelta(minutes=10)

            if now > expiry_time:
                # Generate new token + hash
                new_token = uuid.uuid4().hex
                hashed_new_token = hash_text(new_token)

                # Update DB with new token
                await conn.execute(
                    "UPDATE student_account_activation SET token = $1, token_sent = NOW() WHERE email = $2;",
                    hashed_new_token, email
                )

                # Get student info
                student_info = await conn.fetchrow(
                    "SELECT fname, lname FROM student WHERE email = $1;",
                    email
                )

                if not student_info:
                    return {"status": "error", "message": "Student record not found"}

                # Verify old token
                if not verify_hash(token, record["token"]):
                    return {"status": "invalid", "message": "Invalid token"}

                # Resend activation email
                send_activation_email(student_info["fname"], student_info["lname"], email, new_token)

                return {"status": "expired", "message": "Token expired. A new link has been sent."}

            # Mark account as active
            await conn.execute(
                "UPDATE student_account_activation SET is_active = TRUE WHERE email = $1;",
                email
            )

            return {"status": "success", "message": "Account activated successfully"}

    except Exception as e:
        print("DB error:", str(e))
        return {"status": "error", "message": "Activation failed"}



async def store_new_conversation(email, user_message, ai_message):
    pool = await get_db_connection()
    if pool is None:
        return {"status": "db_error", "message": database_conn_error_msg}

    try:
        token_uuid = str(uuid.uuid4())

        async with pool.acquire() as conn:
            # Call stored procedure or function in Postgres
            row = await conn.fetchrow(
                "SELECT * FROM store_new_conversation($1, $2, $3, $4);",
                email, token_uuid, user_message, ai_message
            )

        if row:
            convo_timestamp = row["convo_timestamp"].strftime("%b %d • %I:%M %p")
            return {
                "status": "success",
                "token_uuid": row["token_uuid"],
                "convo_timestamp": convo_timestamp
            }
        else:
            return {"status": "db_error", "message": "No result returned from procedure"}

    except Exception as e:
        print("Database Query failed:", str(e))
        return {"status": "db_error", "message": "Failed to add conversation"}


async def add_to_chat_history(email, token_UUID, user_message, ai_message):
    pool = await get_db_connection()
    if pool is None:
        return {"status": "db_error", "message": "Unable to connect to Database"}

    try:
        async with pool.acquire() as conn:
            # Get conversation_id for token_UUID
            record = await conn.fetchrow(
                "SELECT conversation_id FROM conversation WHERE token_UUID = $1 AND email = $2;",
                token_UUID, email
            )

            if not record:
                return {
                    "status": "invalid_uuid",
                    "message": "Token UUID does not exist or does not belong to current user"
                }

            conversation_id = record["conversation_id"]

            # Insert user message
            await conn.execute(
                "INSERT INTO chat_history (conversation_id, role, message) VALUES ($1, $2, $3);",
                conversation_id, "user", user_message
            )

            # Insert AI response
            await conn.execute(
                "INSERT INTO chat_history (conversation_id, role, message) VALUES ($1, $2, $3);",
                conversation_id, "AI", ai_message
            )

        return {"status": "success", "message": "Chat added to database"}

    except Exception as e:
        print("Database Query failed:", str(e))
        return {"status": "db_error", "message": "Failed to add conversation"}   



async def get_conversation_token_UUID(email: str):
    pool = await get_db_connection()
    if pool is None:
        return {"status": "db_error", "message": database_conn_error_msg}

    try:
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT token_UUID, started_at
                FROM conversation
                WHERE email = $1
                  AND deleted_at IS NULL
                ORDER BY started_at DESC;
                """,
                email
            )

        if not rows:
            return {"status": "no_conversation", "message": "No chat history yet"}

        token_UUIDs = [row["token_uuid"] for row in rows]
        started_at = [row["started_at"] for row in rows]

        return {"status": "success", "token_UUIDs": token_UUIDs, "started_at": started_at}

    except Exception as e:
        print("Database query Failed", str(e))
        return {"status": "db_error", "message": "Failed to retrieve conversation history"}


async def get_current_convo(email: str, current_convo_UUID: str):
    pool = await get_db_connection()
    if pool is None:
        return {"status": "db_error", "message": database_conn_error_msg}

    try:
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT a.role, a.message
                FROM chat_history AS a
                INNER JOIN conversation AS b
                  ON a.conversation_id = b.conversation_id
                WHERE b.email = $1
                  AND b.token_UUID = $2
                  AND b.deleted_at IS NULL
                ORDER BY a.created_at ASC;
                """,
                email, current_convo_UUID
            )

        if rows:
            # rows is a list of asyncpg.Record objects
            messages = [{"role": row["role"], "message": row["message"]} for row in rows]
            return {"status": "success", "message": messages}
        else:
            return {"status": "no_records", "message": "Unable to retrieve conversation"}

    except Exception as e:
        print("Database query Failed", str(e))
        return {"status": "db_error", "message": "Failed to retrieve conversation history"}
    



    