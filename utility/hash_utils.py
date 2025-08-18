from passlib.context import CryptContext

# Create a password hashing context using bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_text(text: str) -> str:
    """Hash a plain-text """
    return pwd_context.hash(text)

def verify_hash(plain_text: str, hashed_text: str) -> bool:
    """Verify a plain-text password against its hashed version."""
    return pwd_context.verify(plain_text, hashed_text)
