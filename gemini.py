import google.generativeai as genai
from dotenv import load_dotenv
import os

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("GEMINI_API_KEY not found in .env file")

genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-2.5-pro')

def create_section_paths_dict(base_folder="Sections"):
    section_paths = {}
    key_list = []

    if not os.path.isdir(base_folder):
        return section_paths, key_list

    for dirpath, _, filenames in os.walk(base_folder):
        for filename in filenames:
            if filename.endswith(".txt"):
                full_path = os.path.join(dirpath, filename)
                key_name = os.path.splitext(filename)[0]
                section_paths[key_name] = full_path
                key_list.append("- " + key_name + "\n")
    return section_paths, key_list


def get_gemini_response(user_question: str, chat_history: list) -> str:
    section_paths, key_list = create_section_paths_dict()

    ask_sections_prompt = (
        f"You are a university assistant of UTech Jamaica. Based on the following handbook sections, "
        f"which one(s) are relevant to answering the user's question?\n\n"
        f"Sections:\n{''.join(key_list)}"
        "- Not relevant to UTech or the handbook\n"
        f"User Question: {user_question}\n\n"
        f"Reply with the relevant section names."
    )

    section_response = model.generate_content(ask_sections_prompt)
    section_text = section_response.text.lower()

    included_texts = []
    for key, filepath in section_paths.items():
        if key in section_text and os.path.exists(filepath):
            with open(filepath, "r", encoding="utf-8") as file:
                included_texts.append(f"[{key.replace('_', ' ').title()}]\n{file.read()}")

    history_text = ""
    for msg in chat_history:
        if msg["role"] == "user":
            history_text += f"\nStudent: {msg['text']}"
        elif msg["role"] == "gemini":
            history_text += f"\nGemini: {msg['text']}"

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

    final_response = model.generate_content(combined_prompt)
    return final_response.text
