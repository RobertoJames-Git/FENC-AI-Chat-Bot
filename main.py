from fastapi import FastAPI, Request,HTTPException
from fastapi.responses import HTMLResponse, FileResponse,JSONResponse
from fastapi.staticfiles import StaticFiles
from gemini import get_gemini_response
from google.api_core.exceptions import ResourceExhausted
from fastapi.middleware.cors import CORSMiddleware
from utility.hash_utils import hash_text
from database.database_actions import process_activation, insert_student
from starlette.middleware.sessions import SessionMiddleware
import re 
from dotenv import load_dotenv
import os

# Load environment variables from .env
load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")

app = FastAPI()

# This allows my frontend 
# to send requests to my backend without being blocked by the browser.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Allow all origins (for development only, restrict in production)
    allow_methods=["*"],   # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],   # Allow all HTTP headers
)

app.add_middleware(
    SessionMiddleware,
    secret_key=SECRET_KEY,  # Keep this secure
    max_age=3600  # session expires in 1 hour
)

# Handle chat questions
chat_history = []
 
# Serve static files (CSS, JS)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Serve index.html at root
@app.get("/", response_class=HTMLResponse)
async def get_index():
    return FileResponse("index.html")



@app.post("/ask")
async def ask_question(request: Request):
    data = await request.json()
    question = data.get("question")
    if not question:
        return {"error": "Missing question"}
    

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
async def signup(request: Request):

    try:
        # Parse request body (JSON expected)
        data = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
    
    # Dictionary to store validation errors
    errors = {}

    # Extract and clean input fields (remove spaces from start/end)
    fname = data.get("fname","").strip()
    lname = data.get("lname","").strip()
    email = data.get("email","").strip()
    password = data.get("password","")
    confirm_password = data.get("confirm_password","")

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
    elif re.search(r"\s", password):
        errors["password_error"] = "Password must not contain spaces"

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
    
    # Hash password and insert student to database
    hashed_password = hash_text(password)
    result = insert_student(email, fname, lname, hashed_password)

    #check if an error occurred from adding the user to the database and send it to the frontend
    if not result[0]:
        return JSONResponse(content={"error": result[1]}, status_code=400)

    
    # Example: Save email to session
    request.session["student_email"] = email

    # If no errors, Redirect
    return JSONResponse(content={"redirect": "/email_alert"}, status_code=200)



@app.get("/activate_account")
async def activate_account(request: Request):
    # Extract query parameters from the URL
    email = request.query_params.get("email")
    token = request.query_params.get("token")


    print(email)
    # Validate presence of required parameters
    if not email or not token:
        raise HTTPException(status_code=400, detail="Missing email or token")

    # Delegate activation logic to database_actions
    result = process_activation(email, token)

    # return message if database connection fails,
    if result["status"] == "error":
        raise HTTPException(status_code=500, detail=result["message"])
    elif result["status"] == "not_found":
        raise HTTPException(status_code=404, detail=result["message"])
    elif result["status"] == "invalid":
        raise HTTPException(status_code=401, detail=result["message"])

    # Return success, expired, or already_active responses
    return JSONResponse(content=result, status_code=200)




