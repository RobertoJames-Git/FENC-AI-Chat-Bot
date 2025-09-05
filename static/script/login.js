// Wait until the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("verify_credentials");

    // Attach submit event listener to the form using its ID
    form.addEventListener("submit", async (event) => {

        const container = document.getElementById('form_container');
        document.getElementById('right_column_content').style.display="none";

        const loadingDiv = document.createElement('div');//create loading icon
        const loadingMsg = document.createElement('p');

        //style loading message and add text
        loadingMsg.id="loadingMsg";
        loadingMsg.textContent="Verifying credentials...";
        loadingMsg.style.textAlign='center';
        loadingMsg.style.marginTop="10px";

        //style loading circle
        loadingDiv.id="loading_icon";
        
        //set fixed height
        container.style.height="334px";
        
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

        event.preventDefault(); // Prevent default form submission

        // Clear previous validation messages
        document.getElementById("email_error").textContent = "";
        document.getElementById("password_error").textContent = "";
        document.getElementById("timeout_message").style.display = 'none';
        document.getElementById("time_left").style.display = 'none';
        document.getElementById("time_left").innerHTML = "";

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
                removeLoadingIcon();
                // If response is not OK, display errors from backend
                if (result.email_error) {
                    document.getElementById("email_error").innerHTML = "<br>" + result.email_error;
                }
                if (result.password_error) {
                    document.getElementById("password_error").innerHTML = "<br>" + result.password_error;
                }

                if(result.status && result.status =="timeout"){
                    document.getElementById("timeout_message").style.display = 'block';
                    document.getElementById("time_left").style.display = 'inline';
                    startCountdown(result.time_left,result.message);

                }
            } else {
                // If login is successful, redirect to chatbt
                window.location.href = "/"; // redirect to index
            }

        } catch (error) {

            removeLoadingIcon();
            console.error("Login request failed:", error);
            document.getElementById("email_error").innerHTML = "<br>"+ error.message;
            document.getElementById("password_error").innerHTML = "<br>"+ error.message;
        }
    });
});




function startCountdown(secondsLeft,message) {
  const countdownElement = document.getElementById("time_left");
  let timerInterval; // outer scope, so clearInterval works

  const updateTimer = () => {
    if (!countdownElement) return; // safety check

    if (secondsLeft <= 0) {
        document.getElementById("timeout_message").style.display = 'none';
        document.getElementById("time_left").style.display = 'none';
        document.getElementById("time_left").innerHTML = "";
      clearInterval(timerInterval); 
      return;
    }

    const minutes = Math.floor(secondsLeft / 60);
    const seconds = secondsLeft % 60;

    countdownElement.innerHTML = `${message} ${minutes}:${seconds.toString().padStart(2, '0')}`;
    secondsLeft--;
  };

  updateTimer(); 
  timerInterval = setInterval(updateTimer, 1000);
}



