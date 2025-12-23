import { manageSidebar,controlPortraitSidebar,applyResponsiveStyles,newChat } from "./ui.js";
import { load_current_convo_from_UUID, logout, sendQuestion } from "./api.js";
import { state } from "./state.js";
import { addUuidToUrl } from "./utility.js";

export const textarea = document.getElementById('userInput');
document.addEventListener('DOMContentLoaded', () => {

    if (textarea) {
        textarea.addEventListener('input', () => {
            // Count lines by splitting on newline characters
            const lines = textarea.value.split(/\r\n|\r|\n/).length;

            // resize the text area
            textarea.style.height = 'auto';
            textarea.style.height = `${textarea.scrollHeight}px`;

            // Show scrollbar if more than 7 lines
            if (lines > 7) {
                textarea.style.overflow = 'visible';
            } else {
                textarea.style.overflow = 'hidden';
            }
        });
    }
});

const nameContainer = document.getElementById("name_container");
const popupMenu = document.getElementById("popup_menu");

nameContainer.addEventListener("click", () => {
  //check if popup is visible and if it is make it not visible
  //else if it is not visible then make it visible
  if (popupMenu.style.display === "block") {
    popupMenu.style.display = "none";
  } else {
    popupMenu.style.display = "block";
  }

});

// hide when clicking outside
document.addEventListener("click", (e) => {
  if (!nameContainer.contains(e.target) && !popupMenu.contains(e.target)) {
    popupMenu.style.display = "none";
  }
});



// Reapply styles on window resize
window.addEventListener('resize', applyResponsiveStyles);

const sendArrow = document.getElementById("send_arrow");
sendArrow.addEventListener('click',sendQuestion);

const sidebarIcon = document.getElementById("sidebar_icon")
sidebarIcon.addEventListener('click',manageSidebar)

const sidebarIconPortrait = document.getElementById('sidebar_icon_portrait');
sidebarIconPortrait.addEventListener('click',controlPortraitSidebar)


document.addEventListener("DOMContentLoaded", logout);


const overlay = document.getElementById('sidebar-overlay');
overlay.addEventListener('click',manageSidebar);


const newChatContainer = document.getElementById('new_chat_container');
newChatContainer.addEventListener('click',newChat)

window.addEventListener('popstate',()=>{
    /* check if the user is in root directory
        because the user can continously click the back button until
        there is no chat UUID in the url to read
    */
    if (window.location.pathname === "/") {//root directory
        newChat();//modify UI for new chat
        return;
    }

    //if the url has a UUID then that chat history is loaded
    load_current_convo_from_UUID()

});


export function clickToLoadChat(element) {
    // We change this to accept the element directly for easier use with delegation
    const uuidFromUrl = element.dataset.tokenUuid; 

    if (!uuidFromUrl) return;

    if (state.conversationTokenUUID === uuidFromUrl) return;

    document.getElementById('ai_and_user_container').innerHTML = '';
    addUuidToUrl(uuidFromUrl);
    
    // Pass the UUID directly to the function
    load_current_convo_from_UUID(uuidFromUrl);
}


function loadPastConversationOnClick(){


    // add listener on the parent container
    const convoHistoryContainer = document.getElementById('conversation_history_container');
    
    if (convoHistoryContainer) {
        convoHistoryContainer.addEventListener('click', (event) => {
            // Find if the click was on (or inside) a .previous_conversations div
            const targetElement = event.target.closest('.previous_conversations');
            
            if (targetElement) {
                clickToLoadChat(targetElement);
            }
        });
    }
}




loadPastConversationOnClick()
applyResponsiveStyles() 

