
import asyncpg
import asyncio

DATABASE_CONFIG = {
    "host": "localhost",
    "user": "postgres",        
    "password": "password",
    "database": "user_chatbot_db"
}

# Create a connection pool for reuse
pool = None

async def init_db_pool():
    global pool
    if pool is None:
        pool = await asyncpg.create_pool(
            host=DATABASE_CONFIG["host"],
            user=DATABASE_CONFIG["user"],
            password=DATABASE_CONFIG["password"],
            database=DATABASE_CONFIG["database"],
            min_size=1,
            max_size=5
        )
    return pool

async def get_db_connection():
    global pool
    if pool is None:
        await init_db_pool()
    
    return pool
