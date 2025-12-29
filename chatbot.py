import os
import requests
from dotenv import load_dotenv

load_dotenv()

# Configuration
API_KEY = os.getenv("AI_API_KEY") # The key you just generated
WORKSPACE_SLUG = os.getenv("WORKSPACE_SLUG") # The slug for your workspace
BASE_URL = os.getenv("BASE_URL") # Standard local port for AnythingLLM

def get_ai_response(user_question: str, chat_history: list) -> str:
    url = f"{BASE_URL}/workspace/{WORKSPACE_SLUG}/chat"
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    # Format history for the prompt
    formatted_history = ""
    for entry in chat_history:
        role = "Student" if entry['role'] == "user" else "Assistant"
        formatted_history += f"{role}: {entry['text']}\n"

    # Combine history with the new question
    full_prompt = f"""
    The following is a conversation history between a student and an AI assistant:
    {formatted_history}
    
    Using the history and the university handbook, please answer the student's new question.
    Student: {user_question}
    """
    
    payload = {
        "message": full_prompt,
        "mode": "query" # Stays strictly to handbook
    }


    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        return response.json().get("textResponse", "I'm sorry, I couldn't find an answer.")
    except Exception as e:
        print(f"Error connecting to AnythingLLM: {e}")
        return "System error: The knowledge base is currently unavailable."