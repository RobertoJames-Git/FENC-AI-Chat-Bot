from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from gemini import get_gemini_response
from google.api_core.exceptions import ResourceExhausted
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from utility.password_utils import hash_password,verify_password
from database import database_actions as database_operation
from pydantic import BaseModel, EmailStr, Field

import re  # For email pattern matching

app = FastAPI()

# This allows my frontend 
# to send requests to my backend without being blocked by the browser.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Allow all origins (for development only, restrict in production)
    allow_methods=["*"],   # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],   # Allow all HTTP headers
)

# Pydantic models for request body validation
class AskQuestionRequest(BaseModel):
    question: str

class SignupRequest(BaseModel):
    fname: str
    lname: str
    email: EmailStr # FastAPI will validate this is a valid email format
    password: str = Field(..., min_length=8)
    confirm_password: str


# Handle chat questions
chat_history = []
 
# Serve static files (CSS, JS)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Serve index.html at root
@app.get("/", response_class=HTMLResponse)
async def get_index():
    return FileResponse("index.html")



@app.post("/ask")
async def ask_question(request_data: AskQuestionRequest):
    question = request_data.question.strip() # Trim whitespace here
    

    try:
        response = get_gemini_response(question, chat_history)
    except ResourceExhausted as e:
        print ("Resource Exhausted : ",e.details)
        return {"error": "You've hit the quota limit. Please try again later."}

    chat_history.append({"role": "user", "text": question})
    chat_history.append({"role": "gemini", "text": response})
    
    #Debug
    print("User: ",question)
    print("AI: ",response,"\n")

    return {"response": response}



# ==============================
# Signup Endpoint - Validation Only 
# ==============================
@app.post("/signup")
async def signup(request_data: SignupRequest):
    """
    This endpoint accepts JSON data from the signup form,
    validates each field, and returns JSON with error messages
    if any field is invalid.
    """

    # Dictionary to store validation errors
    errors = {}

    # Extract and clean input fields (remove spaces from start/end)
    fname = request_data.fname.strip()
    lname = request_data.lname.strip()
    email = request_data.email.strip()
    password = request_data.password
    confirm_password = request_data.confirm_password

    # ==============================
    # VALIDATION RULES
    # ==============================

    # First Name validation
    if not fname:
        errors["fname_error"] = "First name is required"

    # Last Name validation
    if not lname:
        errors["lname_error"] = "Last name is required"

    # Email validation
    if not email:
        errors["email_error"] = "Email is required"
    elif not re.match(r"^[\w\.-]+@students\.utech\.edu\.jm$", email):
        # Pattern ensures the email ends with @students.utech.edu.jm
        errors["email_error"] = "Must be a valid UTech student email"

    # Password validation
    if not password:
        errors["password_error"] = "Password is required"
    elif len(password) < 8:
        errors["password_error"] = "Password must be at least 8 characters"
    elif not re.search(r"[A-Za-z]", password):
        errors["password_error"] = "Password must contain at least one letter"
    elif not re.search(r"\d", password):
        errors["password_error"] = "Password must contain at least one number"
    elif not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
        errors["password_error"] = "Password must contain at least one symbol"
        
    # Confirm Password validation
    # Check if password has data in it and its not
    if password and password != confirm_password:
        errors["confirm_password_error"] = "Passwords do not match"

    # ==============================
    # RETURNING ERRORS OR SUCCESS
    # ==============================

    # If there are errors, return them with HTTP status 400 (Bad Request)
    if errors:
        return JSONResponse(content=errors, status_code=400)
    
        # Hash password and insert student
    hashed_password = hash_password(password)
    result = database_operation.insert_student(email, fname, lname, hashed_password)

    if not result[0]:#check if an error occurred and send it to the frontend
        return{ result[0]:result[1]}
    
    # If no errors, return success message
    return {"success": result[1]}