
// Function to extract email and token from URL and send POST request
async function activateAccount() {
// Parse query parameters from the current page URL
const params = new URLSearchParams(window.location.search);
const email = params.get("email");
const token = params.get("token");

// Basic validation: ensure both parameters are present
if (!email || !token) {
    console.error("Missing email or token in URL");
    return;
}

try {
    // Send POST request to FastAPI backend with email and token
    const response = await fetch("http://127.0.0.1:8000/activate_account", {
    method: "POST",
    headers: {
        "Content-Type": "application/json"
    },
    body: JSON.stringify({ email, token })
    });

    // Parse JSON response from backend
    const result = await response.json();
    const loading_div = document.getElementById("loading_icon")
    loading_div.remove();

    const backend_msg = document.getElementById("msg_from_backend")

    // Log result based on response status
    if (!response.ok) {
    console.error("Activation failed: " + result);
    backend_msg.style.color='white';
    backend_msg.style.backgroundColor='rgb(100,80,80)';
    backend_msg.style.padding ='10px';
    backend_msg.style.borderRadius ='5px';
    backend_msg.style.borderLeft='20px solid red';
    backend_msg.innerHTML=result.message;


    } else {
    console.log("Activation successful:" , result);
    backend_msg.style.color='white';
    backend_msg.style.backgroundColor='rgb(80,100,80)';
    backend_msg.style.padding ='10px';
    backend_msg.style.borderRadius ='5px';
    backend_msg.style.borderLeft='20px solid green';
    backend_msg.innerHTML=result.message;

    }
} catch (err) {
    // Handle network or server errors
    console.error("Network error:", err);
}
}

// Automatically run activation logic when page loads
window.onload = activateAccount;
