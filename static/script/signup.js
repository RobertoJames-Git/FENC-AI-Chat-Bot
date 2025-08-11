
// Attach event listener to the form's submit event
document.querySelector("form").addEventListener("submit", async function (e) {
    e.preventDefault(); // Prevent default form submission (page reload)

    // ==============================
    // Step 1: Clear Previous Error Messages
    // ==============================
    // Loop through all elements with class "validation" and clear text
    document.querySelectorAll(".validation").forEach(span => span.textContent = "");
    //form border will be gray
    document.getElementById("form_container").style.border="2px solid grey";

    // ==============================
    // Step 2: Gather Form Data into an Object
    // ==============================
    const formData = {
        fname: document.getElementById("fnameID").value,
        lname: document.getElementById("lnameID").value,
        email: document.getElementById("emailID").value,
        password: document.getElementById("passwordID").value,
        confirm_password: document.getElementById("confirm_password_ID").value
    };

    try {
        // ==============================
        // Step 3: Send Data to FastAPI Backend
        // ==============================
        const res = await fetch("http://127.0.0.1:8000/signup", {
            method: "POST",                         // Use POST request
            headers: { "Content-Type": "application/json" }, // Sending JSON
            body: JSON.stringify(formData)          // Convert JS object to JSON string
        });

        // ==============================
        // Step 4: Handle Error Response (HTTP Status 400)
        // ==============================
        if (!res.ok) { // If response is NOT successful
            const errors = await res.json(); // Convert JSON errors to JS object

            console.log(errors);

            // Loop through each error key and display it in the matching span
            for (let key in errors) {
                const errorSpan = document.getElementById(key); // Example: fname_error
                if (errorSpan) {
                    //form border will turn red to signify error
                    document.getElementById("form_container").style.border="2px solid red";
                    errorSpan.innerHTML = "<br>" + errors[key]; // Set the error message
                }

            }
        } 
        // ==============================
        // Step 5: Handle Successful Response
        // ==============================
        else {
            const result = await res.json(); // Parse success JSON
            const successMessage = result.success;
            console.log(successMessage);     // Log success message
            alert(successMessage); // Show success alert

            // OPTIONAL: Reset the form after success
            document.querySelector("form").reset();
        }

    } catch (err) {
        // ==============================
        // Step 6: Handle Network/Server Errors
        // ==============================
        console.error("Error:", err);
        alert("Something went wrong. Please try again.");
    }
});