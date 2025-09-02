from fastapi import FastAPI, Request,HTTPException,Response
from fastapi.responses import HTMLResponse, FileResponse,JSONResponse,RedirectResponse
from datetime import datetime, timedelta
from fastapi.staticfiles import StaticFiles
from gemini import get_gemini_response
from google.api_core.exceptions import ResourceExhausted
from fastapi.middleware.cors import CORSMiddleware
from utility.hash_utils import verify_hash
from database.database_actions import process_activation, insert_student, email_exist, get_hashed_password_and_fullname, account_is_active
from starlette.middleware.sessions import SessionMiddleware
import re 
from dotenv import load_dotenv
import os
from fastapi.templating import Jinja2Templates



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

templates = Jinja2Templates(directory="templates")

# Serve static files (CSS, JS)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Serve index.html at root
@app.get("/", response_class=HTMLResponse)
async def get_index(request: Request):

    #retrieve user email and fullname from session
    email = request.session.get("student_email")
    fullname = request.session.get("fullname")

    #if any of them are empty then the user is redirected to the login page
    if email is None or fullname is None:
        return RedirectResponse(url="/static/login.html")

    result=fullname.split()
    fname=result[0]
    lname=result[1]
    return templates.TemplateResponse("index.html", {
        "request": request,
        "email": email,
        "fname": fname,
        "lname": lname
    })



@app.post("/ask")
async def ask_question(request: Request):
    data = await request.json()
    question = data.get("question").strip()
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
    email = data.get("email","").lower().strip()#put email in lowercase
    password = data.get("password","")
    confirm_password = data.get("confirm_password","")

    # ==============================
    # VALIDATION RULES
    # ==============================

    # First Name validation
    if not fname:
        errors["fname_error"] = "First name is required"
    elif not fname.isalpha(): #ensure lname contains only letters
        errors["fname_error"] = "First name must contain only letters"

    # Last Name validation
    if not lname:
        errors["lname_error"] = "Last name is required"
    elif not lname.isalpha(): #ensure lname contains only letters
        errors["lname_error"] = "Last name must contain only letters"

    # Email validation
    if not email:
        errors["email_error"] = "Email is required"
    elif not re.match(r"^[\w\.-]+@students\.utech\.edu\.jm$", email):
        # Pattern ensures the email ends with @students.utech.edu.jm
        errors["email_error"] = "Must be a valid UTECH student email"
    else:
        email_result = email_exist(email)  # Only check existence if format is valid
        if email_result["status"] == "exists" or email_result["status"] == "error":
            errors["email_error"] = email_result["message"]

        else:
            email_split = email.split("@")
            email_username = email_split[0]#username for the email ***@students.xyz.....

            if (len(email_username)<=3): 
                errors["email_error"]="Email is invalid"


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
    
    result = insert_student(email, fname, lname, password)

    #check if an error occurred from adding the user to the database and send it to the frontend
    if not result[0]:
        return JSONResponse(content={"error": result[1]}, status_code=400)

    
    # Example: Save email to session
    request.session["student_email"] = email

    # If no errors, Redirect
    return JSONResponse(content={"redirect": "/static/mail.html"}, status_code=200)





@app.post("/activate_account")
async def activate_account(request: Request):
    data = await request.json()
    email = data.get("email").strip()
    token = data.get("token").strip()

    if not email or not token:
        return JSONResponse(content={"message":"Missing email or token"},status_code=400)

    now = datetime.now()

    # Check for active lockout
    lockout_until = request.session.get("activation_lockout_until")
    if lockout_until:
        try:
            lockout_time = datetime.fromisoformat(lockout_until)
            if now < lockout_time:
                return JSONResponse(
                    content={"message": "Too many attempts. Please wait 1 minute before trying again."},
                    status_code=429
                )
        except ValueError:
            # Malformed lockout timestamp — clear it
            request.session.pop("activation_lockout_until", None)

    # Attempt tracking
    window_start = request.session.get("activation_window_start")
    attempt_count = request.session.get("activation_attempt_count", 0)

    if window_start:
        try:
            start_time = datetime.fromisoformat(window_start)
            if now - start_time < timedelta(minutes=1):
                if attempt_count >= 5:
                    # Set lockout for 1 minute
                    request.session["activation_lockout_until"] = (now + timedelta(minutes=1)).isoformat()
                    return JSONResponse(
                        content={"message": "Too many attempts. Please wait 1 minute before trying again."},
                        status_code=429
                    )
                else:
                    request.session["activation_attempt_count"] = attempt_count + 1
            else:
                # Window expired — reset
                request.session["activation_window_start"] = now.isoformat()
                request.session["activation_attempt_count"] = 1
        except ValueError:
            # Malformed timestamp — reset
            request.session["activation_window_start"] = now.isoformat()
            request.session["activation_attempt_count"] = 1
    else:
        # First attempt — initialize
        request.session["activation_window_start"] = now.isoformat()
        request.session["activation_attempt_count"] = 1

    # Proceed with activation logic
    result = process_activation(email, token)

    if result["status"] == "error":
        return JSONResponse(content={"message":result["message"]}, status_code=500)
    elif result["status"] == "not_found":
        return JSONResponse(content={"message":result["message"]}, status_code=404)
    elif result["status"] in ["invalid", "expired"]:
        return JSONResponse(content={"message":result["message"]}, status_code=401)

    
    return JSONResponse(content={"message":result["message"]}, status_code=200)
 

@app.get("/activate", response_class=HTMLResponse)
async def serve_activate_page():
    return FileResponse("static/activate.html")

 


@app.post("/verify_login")
async def verify_login(request: Request):

    # Attempt to parse incoming JSON payload
    try:
        data = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")

    # Dictionary to collect validation errors
    errors = {}

    # Extract and sanitize input fields
    email = data.get("email", "").strip()
    password = data.get("password", "").strip()

    # Validate email format and domain
    if not email:
        errors["email_error"] = "Email is required"
    elif not re.match(r"^[\w\.-]+@students\.utech\.edu\.jm$", email):
        errors["email_error"] = "Must be a valid UTECH student email"

    # Validate password presence and length
    if not password:
        errors["password_error"] = "Password is required"
    elif len(password) < 8:
        errors["password_error"] = "Password is invalid"

    # If any validation errors exist, return them immediately
    if errors:
        return JSONResponse(content=errors, status_code=400)


        #initalize session to 5 if it does not exist
    if "student_login_attempt" not in request.session:
        request.session["student_login_attempt"] = 5
    # Retrieve login attempt count and lockout timestamp from session
    user_attempts = request.session.get("student_login_attempt", 5)
    lockout_start = request.session.get("student_login_lockout_start")
    

    # If user has exhausted attempts, check if cooldown is still active
    if user_attempts <= 1:
        if lockout_start:
            try:
                # Parse stored timestamp and calculate remaining cooldown
                lockout_time = datetime.fromisoformat(lockout_start)
                now = datetime.now()
                cooldown_duration = timedelta(minutes=5)#set cooldown duration to 5 minutes
                time_left = (lockout_time + cooldown_duration - now).total_seconds()

                # If cooldown is still active, return timeout response
                if time_left > 1:
                    return JSONResponse(content={"status": "timeout","message": "Too many requests. Try again in ","time_left": int(time_left)}, status_code=429)
                else:
                    # Cooldown expired — reset attempts and clear lockout
                    request.session["student_login_attempt"] = 5
                    request.session.pop("student_login_lockout_start", None)
            except ValueError:
                # If timestamp is malformed, reset everything defensively
                request.session["student_login_attempt"] = 5
                request.session.pop("student_login_lockout_start", None)

    # Attempt to retrieve credentials from database
    credentials_error = "Email and / or password is incorrect"
    result = get_hashed_password_and_fullname(email)


    # Handle invalid credentials
    if result["status"] == "invalid_credentials":
        request.session["student_login_attempt"] -= 1

        # If attempts hit zero, start cooldown timer
        if request.session["student_login_attempt"] <= 1:
            request.session["student_login_lockout_start"] = datetime.now().isoformat()

        # Return generic error to avoid revealing which field was wrong
        errors["email_error"] = credentials_error
        errors["password_error"] = credentials_error
        errors["login_attempts"] = request.session["student_login_attempt"]
        return JSONResponse(content=errors, status_code=401)

    # Handle database errors gracefully
    elif result["status"] == "db_error":
        request.session["student_login_attempt"] -= 1
        errors["email_error"] = result["message"]
        errors["password_error"] = result["message"]
        errors["login_attempts"] = request.session["student_login_attempt"]
        return JSONResponse(content=errors, status_code=500)

    # Verify password against stored hash
    hashed_password = result["hash_pwd"]
    if verify_hash(password, hashed_password):

        #check if acccount is active
        result=account_is_active(email)

        if result["status"] == False: #check if account was activated
            errors["email_error"] = result["message"]
            errors["password_error"] = result["message"]
            return JSONResponse(content=errors, status_code=401)
        
        elif result["status"] == "error":#database error
            errors["email_error"] = result["message"]
            errors["password_error"] = result["message"]
            return JSONResponse(content=errors, status_code=500)


        # Successful login — clear session tracking and store user info
        request.session.pop("student_login_attempt", None)
        request.session.pop("student_login_lockout_start", None)
        request.session["student_email"] = email
        request.session["fullname"] = result["fullname"]
        return JSONResponse(content={"message": "Login Successful"}, status_code=200)

    # Password mismatch — decrement attempts and possibly start cooldown
    request.session["student_login_attempt"] -= 1
    if request.session["student_login_attempt"] <= 0:
        request.session["student_login_lockout_start"] = datetime.now().isoformat()

    errors["email_error"] = credentials_error
    errors["password_error"] = credentials_error
    errors["login_attempts"] = request.session["student_login_attempt"]
    return JSONResponse(content=errors, status_code=401)




@app.post("/logout")
def logout(response: Response):
    response.delete_cookie("session")  # clears the session cookie
    return {"message": "Logged out", "redirect":"static/login.html"}






