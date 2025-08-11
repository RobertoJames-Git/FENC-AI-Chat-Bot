import google.generativeai as genai
import pathlib
from dotenv import load_dotenv
import os
import time

# Load the .env file
load_dotenv()

# Access keys
api_key = os.getenv("GEMINI_API_KEY")

# --- Configuration and File Loading (outside the loop, only done once) ---

# Configure the API key.
if not api_key:
    print("ERROR: GEMINI_API_KEY is not set in your .env file or environment variables.")
    exit() # Exit if no API key is found

genai.configure(api_key=api_key)

# Retrieve and encode the PDF bytes
filepath = pathlib.Path('Student Handbook 2024-25.pdf')

pdf_content = None # Initialize to None
try:
    # Read the PDF content as bytes
    pdf_content = {
        "mime_type": "application/pdf",
        "data": filepath.read_bytes()
    }
    print(f"PDF file '{filepath.name}' loaded successfully. Ready to answer questions.")
    print("Type 'exit' or 'quit' to end the session.")

except FileNotFoundError:
    print(f"ERROR: The file '{filepath}' was not found. Please ensure the PDF is in the correct directory.")
    exit() # Exit if the PDF is not found, as we can't answer questions without it.
except Exception as e:
    print(f"CRITICAL ERROR: An unexpected error occurred while loading the PDF: {e}")
    exit()

# --- Main loop for continuous user input ---

# Initialize the generative model outside the loop to avoid re-initializing it for each query.
# If your model needs state or conversation history, you might use genai.GenerativeModel("model_name").start_chat()
# But for single-turn Q&A, the current approach is fine.
model = genai.GenerativeModel("gemini-1.5-flash")


while True:
    try:
        user_input = input("\nYour question about the handbook (or 'exit' to quit): ").strip()
        start = time.perf_counter()

        if user_input.lower() in ['exit', 'quit']:
            print("Exiting session. Goodbye!")
            break # Exit the while loop

        if not user_input:
            print("Please enter a question.")
            continue # Go back to the start of the loop to ask for input again

        # Combine the PDF content and the user's prompt for the model
        contents_for_model = [
            pdf_content, # The pre-loaded PDF content
            {"text": user_input} # The user's current question
        ]

        print("Thinking... (This may take a moment for larger documents)")
        response = model.generate_content(contents_for_model)

        print("\n--- AI Response ---")
        end = time.perf_counter()

        # Calculate the difference
        duration = end - start
        # Get the absolute value
        duration = abs(duration)
        # Remove decimal places (convert to integer)
        duration = int(duration)

        print(response.text+"Duration: "+str(duration)+"s")
        print("-------------------\n")

    except Exception as e:
        print(f"An error occurred during response generation: {e}")
        print("Please try your question again or type 'exit' to quit.")