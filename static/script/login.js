// Wait until the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("verify_credentials");

    // Attach submit event listener to the form using its ID
    form.addEventListener("submit", async (event) => {
        event.preventDefault(); // Prevent default form submission

        // Clear previous validation messages
        document.getElementById("email_error").textContent = "";
        document.getElementById("password_error").textContent = "";
        document.getElementById("timeout_message").style.display = 'none';
        document.getElementById("timeout_message").innerHTML = "";

        // Extract values from input fields
        const email = document.getElementById("emailID").value.trim();
        const password = document.getElementById("passwordID").value.trim();

        try {
            // Send POST request to backend
            const response = await fetch("/verify_login", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({ email, password })
            });

            const result = await response.json();

            if (!response.ok) {
                // If response is not OK, display errors from backend
                if (result.email_error) {
                    document.getElementById("email_error").innerHTML = "<br>" + result.email_error;
                }
                if (result.password_error) {
                    document.getElementById("password_error").innerHTML = "<br>" + result.password_error;
                }

                if(result.status && result.status =="timeout"){
                    document.getElementById("timeout_message").style.display = 'block';
                    document.getElementById("timeout_message").innerHTML = result.message + result.time_left +" s";
                }
            } else {
                // If login is successful, redirect or show success message
                alert(result.message); // You can replace this with a redirect if needed
                window.location.href = "/"; // redirect to index
            }

        } catch (error) {
            console.error("Login request failed:", error);
            document.getElementById("email_error").innerHTML = "<br>"+ error.message;
            document.getElementById("password_error").innerHTML = "<br>"+ error.message;
        }
    });
});
