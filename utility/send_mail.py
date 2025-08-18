import smtplib
from email.message import EmailMessage
from dotenv import load_dotenv
import os

# Load environment variables from .env
load_dotenv()

EMAIL_HOST = os.getenv("EMAIL_HOST")
EMAIL_PORT = int(os.getenv("EMAIL_PORT"))
EMAIL_ADDRESS = os.getenv("EMAIL_ADDRESS")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD")

def send_activation_email(fname: str, lname: str, to_email: str, token: str) -> bool:
    """Send account activation email with token link."""
    try:
        msg = EmailMessage()
        msg["Subject"] = "Activate Your FENC Chatbot Account"
        msg["From"] = EMAIL_ADDRESS
        msg["To"] = to_email

        # Activation link
        activation_link = f"http://127.0.0.1:8000/activate?token={token}&email={to_email}"

        # HTML content with inline styles
        html_content = f"""
        <html lang="en">
          <body style="font-family: sans-serif; line-height: 1.6; padding: 20px;">
            <p>
                Hello <b>{fname} {lname}</b>,<br>
                You're one step away from activating your account. We're also excited to introduce our new chatbot designed to help you get answers to frequently asked questions.
            </p>
            <p>
                Please activate your account by clicking the link below:
            </p>
            <p style="text-align: center;">
                <a href="{activation_link}" 
                    style="background-color: #1964da; color: white; padding: 10px 20px; 
                            text-decoration: none; border-radius: 5px; display: inline-block;">
                    Click to activate your account
                </a>
            </p>

            <p>
                This link is <b>only valid for 10 minutes</b>. If you click it after that time, it will no longer work, but don't worry a new activation link will be sent to your email upon clicking the expired link.<br><br>
                If you did not request this, please ignore this message.
            </p>
            <p>
                Best regards<br>
            </p>
          </body>
        </html>
        """

        # Add HTML content to email
        msg.set_content("Please use an HTML-compatible email client to view this message.")
        msg.add_alternative(html_content, subtype="html")

        # Send email using SMTP
        with smtplib.SMTP(EMAIL_HOST, EMAIL_PORT) as server:
            server.starttls()
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.send_message(msg)

        return True

    except Exception as e:
        print(f"Failed to send email: {e}")
        return False


