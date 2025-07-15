import google.generativeai as genai
from dotenv import load_dotenv
import os

# Load the .env file
load_dotenv()

# Access keys
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise ValueError("GEMINI_API_KEY not found in .env file")

# Configure the Gemini client with the API key
genai.configure(api_key=api_key)

model = genai.GenerativeModel('gemini-2.5-flash')

import os

def chatWithGemini():
    print("📘 Welcome to the UTECH AI Handbook Assistant.")
    print("Ask your question below (type 'exit' or 'done' to quit):\n")

    chat_history = []

    section_paths,key_list = create_section_paths_dict()#retrieve key value pair of all filename/sections and path

    while True:

        user_question = input("👨🏽‍🎓Student: ")

        if user_question.strip().lower() in ["exit", "done"]:
            print("👋 Chat ended. Goodbye!")
            break

        # Step 1: Ask Gemini which sections apply
        ask_sections_prompt = (
            f"You are a university assistant of UTech Jamaica. Based on the following handbook sections, "
            f"which one(s) are relevant to answering the user's question?\n\n"
            f"Sections:\n"
            f"{''.join(key_list)}"+"- Not relevant to utech or the handbook" # Join the list directly, as each item already has a newline
            f"\nUser Question: {user_question}\n\n"
            f"Reply with the relevant section names. Ensure that the question asked is always relevant to utech."
        )
        
        #print(ask_sections_prompt)

        section_response = model.generate_content(ask_sections_prompt)
        section_text = section_response.text.lower()
        #print("\n🤖Gemini (section decision):", section_text) debug

        # Step 2: Match sections mentioned
        included_texts = []
        for key, filepath in section_paths.items():
            if key in section_text:
                if os.path.exists(filepath):
                    with open(filepath, "r", encoding="utf-8") as file:
                        included_texts.append(f"[{key.replace('_', ' ').title()}]\n{file.read()}")

        # Step 3: Build history string
        history_text = ""
        for msg in chat_history:
            if msg["role"] == "user":
                history_text += f"\nStudent: {msg['text']}"
            elif msg["role"] == "gemini":
                history_text += f"\nGemini: {msg['text']}"

        # Step 4: Build final prompt with context
        #print("\n\nIncluded Text:\n" + "\n".join(included_texts) + "\n\n") debug
        if included_texts:
            combined_prompt = (
                "You are a university chat bot assistant of UTECH Jamaica. Below is the conversation history and relevant handbook sections.\n\n"
                f"{history_text}\n\n"
                + "\n\n".join(included_texts)
                + f"\n\nStudent: {user_question}"
            )
        else:
            combined_prompt = (
                "You are a university chat bot assistant of UTECH Jamaica. Below is the conversation history. No specific handbook sections matched this time.\n\n"
                f"{history_text}\n\nStudent: {user_question}"
            )

        # Step 5: Get Gemini's response
        final_response = model.generate_content(combined_prompt)
        print("\n🤖Gemini:", final_response.text)

        # Step 6: Track history
        chat_history.append({"role": "user", "text": user_question})
        chat_history.append({"role": "gemini", "text": final_response.text})


def create_section_paths_dict(base_folder="Sections"):
    section_paths = {}
    key_list=[]
    # Check if the base folder exists
    if not os.path.isdir(base_folder):
        print(f"Error: The base folder '{base_folder}' does not exist.")
        print("Please ensure the 'Sections' folder and its content are in the same directory as this script, or provide the correct path.")
        return section_paths

    # os.walk generates the file names in a directory tree by walking the tree
    # top-down or bottom-up. For each directory in the tree rooted at directory
    # top (including top itself), it yields a 3-tuple (dirpath, dirnames, filenames).
    for dirpath, dirnames, filenames in os.walk(base_folder):
        for filename in filenames:
            # Check if the file is a .txt file
            if filename.endswith(".txt"):
                # Construct the full relative path to the file
                # os.path.join handles correct path separators for different OS
                full_path = os.path.join(dirpath, filename)

                # Get the filename without the extension to use as the key
                # os.path.splitext splits the path into a (root, ext) tuple
                key_name = os.path.splitext(filename)[0]
                
                # Add to the dictionary
                section_paths[key_name] = full_path
                key_list.append("- "+key_name+"\n")

    return section_paths,key_list


chatWithGemini()