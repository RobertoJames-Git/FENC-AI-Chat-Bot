import mysql.connector
from mysql.connector import Error

def get_db_connection():
    try:
        conn = mysql.connector.connect(
            host="localhost",        
            user="root", 
            password="", 
            database="user_chatbot_db"  
        )
        return conn
    except Error as e:
        print("Error connecting to Database:", e)
        return None
    

get_db_connection()