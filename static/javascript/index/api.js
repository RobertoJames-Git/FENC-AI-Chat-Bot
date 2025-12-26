import { textarea } from "./events.js";
import { displayServerError, addMessageToUI, removeWelcomeMessage,updateConversationList, updatePromptCountOnUI } from "./ui.js";
import { addUuidToUrl, formatMarkdown,getUUIDFromUrl } from "./utility.js";
import { state } from "./state.js";


export async function sendQuestion() {
    const userInput=textarea.value.trim();//retrieve what the user entered in the input
    
    //do not send a request to the backend if user input is empty
    if(userInput==""){
        return;
    }

    textarea.value = ""; //clear input field after user sends question
    textarea.style.height='auto';
    addMessageToUI("user",userInput);//add users message to the container above the textbox

    removeWelcomeMessage();

    //add loading icon
    const loadingIcon = document.createElement('div');//create div
    loadingIcon.id='loading_icon'; //add class to div
    //add loading icon to div with ai and user conversation
    document.getElementById("ai_and_user_container").appendChild(loadingIcon);

    //scroll to the bottom of the page
    const container = document.getElementById("current_convo_container");
    container.scrollTop = container.scrollHeight;
    

    const res = await fetch("/ask", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ question: userInput, token_uuid : state.conversationTokenUUID})
    });

    const data = await res.json();

    console.log(data);
    
    let formattedResponse ="";

    if(data.response){

        if (state.conversationTokenUUID ==null){//means the chat is new so add it to the chats list 
            
            updateConversationList(data.token_uuid,data.convo_timestamp);
            
        }

        state.conversationTokenUUID = data.token_uuid; //retrieve the uuid and add it to url
        //retrieve the uuid and update url with uuid without a page reload
        addUuidToUrl(data.token_uuid);


        //The AI may return data with astericks and other symbols and this function
        // removes those symbols and use them as indicator to know when to style the text or create a list
        formattedResponse = formatMarkdown(data.response);


    }
    else { // if the Server returns errors then they are displayed

        displayServerError(data.detail);
        loadingIcon.remove()
        return;
    }

    //update the number of questions asked
    updatePromptCountOnUI(data.num_questions_asked)

    //remove loading icon
    loadingIcon.remove()
    addMessageToUI("ai_response",formattedResponse.trim());

    
}



export function load_current_convo_from_UUID(tokenUUID){


    if(!tokenUUID){//if a value was not passed because of a page load then the uuid is retrieved from the url
        tokenUUID = getUUIDFromUrl();
    }

    
    if (!tokenUUID){
        return null;
    }

    fetch(`/current_convo/${tokenUUID}`)
    .then(async response=>{

        if(!response.ok){
            const errData = await response.json();
            throw new Error(errData.detail);
        }

        return response.json();
    })
    .then(data =>{

        removeWelcomeMessage();

        // display user and AI message on the page
        for (const eachElement of data.message) {
            console.log(eachElement);
        
            if (eachElement.role.toLowerCase() === "user") {
                addMessageToUI("user", eachElement.message);
            } else {
                addMessageToUI("ai_response", formatMarkdown(eachElement.message));
            }
        }
        //Update the UUID of the current message so that when other messages are sent they are appended to the current convo history in the database
        state.conversationTokenUUID = tokenUUID;


    })
    .catch(error=>{
        //if an error occurred during api request then the message will be shown to users
        displayServerError(error);
    })
    
}




export function  logout() {
    const logoutDiv = document.getElementById("logout_container");
  
    if (logoutDiv) {

      logoutDiv.addEventListener("click", async function () {
        try {
          const response = await fetch("/logout", {
            method: "POST",
            headers: {
              "Content-Type": "application/json"
            }
          });
  
          const data = await response.json();
  
          if (data.redirect) {
            window.location.href = "/" + data.redirect;
          } else {
            alert("Logout successful, but no redirect provided.");
          }
        } catch (error) {
          console.error("Logout failed:", error);
          alert("An error occurred while logging out.");
        }
      });
    }
}


//check if the user access the page with a UUID in their url and retrive the chat history
load_current_convo_from_UUID();