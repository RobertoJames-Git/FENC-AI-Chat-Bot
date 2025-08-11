from mysql.connector import Error
from database.database_connection import get_db_connection

def insert_student(email: str, fname: str, lname: str, hashed_password: str) -> list:
    conn = get_db_connection()
    if conn is None:
        return [False, "Database connection failed"]

    try:
        cursor = conn.cursor()
        cursor.execute("""INSERT INTO students (email, fname, lname, password)
                    VALUES (%s, %s, %s, %s)""", (email, fname, lname, hashed_password))
        conn.commit()
        return [True, "Student added successfully"]
    except Error as e:
        # Handle duplicate email or other DB errors
        if "Duplicate entry" in str(e):
            return [False, "Email already exists"]
        
        print ("Database error: "+str(e))
        return [False, "Error adding student"]
    finally:
        cursor.close()
        conn.close()