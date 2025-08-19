from mysql.connector import Error
from database.database_connection import get_db_connection
from utility.hash_utils import hash_text,verify_hash
from utility.send_mail import send_activation_email
import uuid
import datetime

def email_exist(email: str):
    conn = get_db_connection()
    if conn is None:
        return {"status": "database error", "message": "Unable to check if email is already registered"}

    try:
        cursor = conn.cursor()
        sql = "SELECT COUNT(*) FROM students WHERE email = %s"
        cursor.execute(sql, (email,))
        count = cursor.fetchone()[0]
        cursor.close()
        conn.close()

        if count > 0:
            return {"status": "exists", "message": "Email is already registered"}
        else:
            return {"status": "available", "message": "Email is not registered"}
    except Exception as e:
        return {"status": "error", "message": "Database query failed"}
 

def insert_student(email: str, fname: str, lname: str, plain_password: str) -> list:
    conn = get_db_connection()
    if conn is None:
        return [False, "Database connection failed"]

    try:
        cursor = conn.cursor()

        # Hash password
        hashed_password = hash_text(plain_password)

        # Generate and hash token
        raw_token = uuid.uuid4().hex
        hashed_token = hash_text(raw_token)  # bcrypt hash
        
        # Call stored procedure
        cursor.callproc("insert_student_with_activation", (email, fname, lname, hashed_password, hashed_token))

        conn.commit()
        #send activation email to student
        send_activation_email(fname,lname,email,raw_token)
        
        return [True, "Student and activation record added successfully"]

    except Error as e:
        if "Duplicate entry" in str(e):
            return [False, "Email already exists"]
        print("Database error:", str(e))
        return [False, "Error adding student"]
    finally:
        cursor.close()
        conn.close()




def process_activation(email: str, token: str):
    
    # Establish database connection
    conn = get_db_connection()
    if conn is None:
        return {"status": "error", "message": "Database connection failed"}

    try:
        cursor = conn.cursor(dictionary=True)

        # Fetch activation record for the given email
        cursor.execute("SELECT token, token_sent, is_active FROM student_account_activation WHERE email = %s", (email,))
        record = cursor.fetchone()

        if not record:
            return {"status": "not_found", "message": "Activation record not found"}

        # If account is already active, return early
        if record["is_active"]:
            return {"status": "already_active", "message": "Account already activated"}

        # Check if token has expired (10-minute window)
        token_sent_time = record["token_sent"]
        now = datetime.datetime.now()
        expiry_time = token_sent_time + datetime.timedelta(minutes=10)

        if now > expiry_time:
            # Generate new token and hash it
            new_token = uuid.uuid4().hex
            hashed_new_token = hash_text(new_token)

            # Update token and timestamp in DB
            cursor.execute("UPDATE student_account_activation SET token = %s, token_sent = NOW() WHERE email = %s",
                           (hashed_new_token, email,))
            conn.commit()

            #get fname and lname
            cursor.execute("select fname,lname from students where email = %s",(email,))
            student_info = cursor.fetchone()

            if not student_info:
                return {"status": "error", "message": "Student record not found"}

            # Resend activation email with new token
            send_activation_email(student_info["fname"], student_info["lname"], email, new_token)

            return {"status": "expired", "message": "Token expired. A new link has been sent."}

        # Verify token using bcrypt
        if not verify_hash(token, record["token"]):
            return {"status": "invalid", "message": "Invalid token"}

        # Mark account as active
        cursor.execute("UPDATE student_account_activation SET is_active = TRUE WHERE email = %s", (email,))
        conn.commit()

        return {"status": "success", "message": "Account activated successfully"}

    except Exception as e:
        print("DB error:", str(e))
        return {"status": "error", "message": "Activation failed"}

    finally:
        # Always close DB resources
        cursor.close()
        conn.close()








