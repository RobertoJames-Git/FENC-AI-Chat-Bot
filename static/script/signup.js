
// Attach event listener to the form's submit event
document.querySelector("form").addEventListener("submit", async function (e) {

    const container = document.getElementById('form_container');
    document.getElementById('right_column_content').style.display="none";

    const loadingDiv = document.createElement('div');//create loading icon
    const loadingMsg = document.createElement('p');

    //style loading message and add text
    loadingMsg.id="loadingMsg";
    loadingMsg.textContent="Checking your info...";
    loadingMsg.style.textAlign='center';
    loadingMsg.style.marginTop="10px";

    //style loading circle
    loadingDiv.id="loading_icon";
    
    //set fixed height
    container.style.height="550px";
    
    //add loading icon to container so its visible to user
    container.appendChild(loadingDiv);
    container.appendChild(loadingMsg);


    function removeLoadingIcon(){

    container.removeChild(loadingDiv); //after you get response from backend remove loading icon
    container.removeChild(loadingMsg); 
    container.style.display="block";
    container.style.height="auto";//allow container heigh to expand to display validation errors
    document.getElementById('right_column_content').style.display="block";//display from content


    }


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
    const formData = {//get form details
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
        
        removeLoadingIcon();

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
            // Always redirect if signup is successful
            window.location.href = result.redirect;
        }

    } catch (err) {
        // ==============================
        // Step 6: Handle Network/Server Errors
        // ==============================
        removeLoadingIcon();
        console.error("Error:", err);
        alert("Something went wrong. Please try again.");
    }
});


