from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from gemini import get_gemini_response
from google.api_core.exceptions import ResourceExhausted

app = FastAPI()

# Allow CORS for testing (adjust origin for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
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
