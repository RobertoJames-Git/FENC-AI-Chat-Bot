import { state } from "./state.js";
import { addUuidToUrl } from "./utility.js"; // This import is duplicated, but one is needed. Let's keep it clean.
import { load_current_convo_from_UUID } from "./api.js"; // This is the function that needs to be imported.



let chatHistoryContainer= document.getElementById('ai_and_user_container');
/*
| Flag                   | Purpose                                                                 |
| ---------------------- | ----------------------------------------------------------------------- |
| **isSidebarOpen**      | Tracks **visibility** (mainly mobile: open vs hidden)                   |
| **isSidebarLocked**    | Tracks **behavior/mode** (desktop: permanent vs overlay)                |
| **isSidebarCollapsed** | Tracks **size/layout** (desktop: collapsed/thin vs expanded/full width) |

*/

let isPortrait = window.innerWidth < window.innerHeight;;
let isSidebarOpen = true;
let isSidebarLocked = true;
let isSidebarCollapsed = false;
const portraitSidebarControl = document.getElementById('portrait_sidebar_control');
const mainContainer = document.getElementById('main_container');
const sidebar = document.getElementById('sidebar');


/*by default sidebar is not open on portrait(mobile) but it is open by default on landscape */
if(isPortrait){
    isSidebarOpen = false;
}
else{
    isSidebarOpen = true;
}


export function applyResponsiveStyles() {
    isPortrait = window.innerWidth < window.innerHeight;

    if(!isPortrait){//landscape 

        /* reset to landscape settings */
        mainContainer.style.gridTemplateColumns='';

        if(state.hasChatHistory){//if coversation history is shown
           mainContainer.style.gridTemplateRows='1fr auto';
        }else{//if coversation history is NOT shown
            mainContainer.style.gridTemplateRows='';
        }

        sidebar.style.display='';
        portraitSidebarControl.style.display='';

        if (isSidebarOpen&& !isSidebarCollapsed){
            sidebar.style='';
            document.getElementById('sidebar-overlay').style.display='none';

        }

        

        /*  expand the sidepanel if it was collapsed in landscape(!isPortrai)
            then going to portrait orientation
            then comping back to landscape  */
        if(!isSidebarCollapsed){
        
            document.getElementById('student_fullname').style.display='inline';
    
            controlSidebar('220px',false,'/static/images/sidebar_close.svg','Close Sidebar','','inline','block');

        }
    

        
    }
    else if(isPortrait){
        isSidebarLocked = false;
        isSidebarCollapsed = false;

        portraitSidebarControl.style.display='flex';

        mainContainer.style.gridTemplateColumns='auto';
        mainContainer.style.gridTemplateRows="40px auto 60%";

        if(state.hasChatHistory){
            mainContainer.style.gridTemplateRows='40px 1fr auto';
        }

        if (!isSidebarOpen){
            sidebar.style.display='none';

        }
    }
    
}


export function manageSidebar() {

	if (isPortrait){
		sidebar.style.display='none';
		document.getElementById('sidebar-overlay').style.display='none';
		return;
	}
	

	//expand the sidepanel if it is collapsed
	if(isSidebarCollapsed){
    
        document.getElementById('student_fullname').style.display='inline';

        controlSidebar('220px',false,'/static/images/sidebar_close.svg','Close Sidebar','','inline','block');
        
		return;//no more changes will take effect
	}


	//reduce width of sidebar for landscape orientation

    controlSidebar('40px',true,'/static/images/sidebar_open.svg','Open Sidebar','center','none','none');



}

function controlSidebar(width,sidebarCollpseState,sidebarIconSrc,sidebarIconTitle,textAlign,sidebarTextStyle,convoHistoryDisplayStyle){
    const sidebarIcon = document.getElementById('sidebar_icon');
    sidebar.style.width=width;
    isSidebarCollapsed=sidebarCollpseState;
	sidebarIcon.src=sidebarIconSrc;
	sidebarIcon.title=sidebarIconTitle;
	document.getElementById('new_chat_container').style.textAlign =textAlign;

	controlSidebarText(sidebarTextStyle);//hide sidebar text
	document.getElementById("conversation_history_container").style.display=convoHistoryDisplayStyle;

    isSidebarOpen=!sidebarCollpseState //keeps track of if sidebar is open or not


}



export function removeWelcomeMessage(){
    
    state.hasChatHistory = true; //indicate that text has been added to the container that shows convo history

    chatHistoryContainer.style.display="block";
    document.getElementById("current_convo_container").style.justifyContent="flex-start";

    if(isPortrait){//if screen is portrait then allow div to support 3 rows
        document.getElementById("main_container").style.gridTemplateRows="50px 1fr auto";
    
    }    
    else{ //if screen is lanscape then we would only support 2 rows
    document.getElementById("main_container").style.gridTemplateRows="1fr auto";    
    

    }

}    

function controlSidebarText(action){
    const sidebar_text = document.querySelectorAll('.sidebar_text');

      // Loop through and hide each one
    sidebar_text.forEach(eachElement => {
      eachElement.style.display = action;
    });
}



export function controlPortraitSidebar() {
    

    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebar-overlay');

    controlSidebar('220px',false,'/static/images/sidebar_close.svg','Close Sidebar','','inline','block');

    // Initial sidebar styles
    sidebar.style.position = 'fixed';
    sidebar.style.top = '0';
    sidebar.style.left = '0';
    sidebar.style.zIndex = '3';
    sidebar.style.height = '98vh';
    sidebar.style.width = '0px';
    sidebar.style.display = 'flex';

    // Apply transition via CSS (if not already in stylesheet)
    sidebar.style.transition = 'width 0.2s ease';
    sidebar.style.overflow = 'hidden';

    // Trigger width change after a short delay
    setTimeout(() => {
        sidebar.style.width = '220px';
    }, 10); // 10ms is enough to allow the browser to register the initial width

    // Show overlay
    overlay.style.display = 'block';


}





export function displayServerError(errorMsg) {
    const container = document.getElementById('errorMsg');
    const content = document.getElementById('errorMsgContent');
  
    content.textContent = errorMsg;
  
    // Reset to hidden state
    container.classList.remove('show');
    container.style.display = 'block';
  
    // Force reflow so the "show" class animation triggers
    void container.offsetHeight;
  
    // Show banner
    container.classList.add('show');
  
    // Hide after 5 sec
    setTimeout(() => {
      container.classList.remove('show');
  
      // Remove from DOM flow after animation ends
      setTimeout(() => {
        container.style.display = 'none';
      }, 500);
    }, 5000);
  }
  




export function addMessageToUI(userRole,messageText) {
    document.getElementById("welcome_message")?.remove();//removes welcome message if it exists
    
    if (messageText === "") return; // Avoid empty messages

    // Create the new div
    const messageDiv = document.createElement("div");
    messageDiv.className = userRole;
    if(userRole === "ai_response"){
    messageDiv.innerHTML = messageText;
    }
    else{
    messageDiv.textContent = messageText;
    }

    // Append to the conversation container
    chatHistoryContainer.appendChild(messageDiv);
    const scrollParent = document.getElementById("current_convo_container");
    scrollParent.scrollTop = scrollParent.scrollHeight;

}




function addEventListenerToLoadPastConversations(){
    const prevConvoElements = document.querySelectorAll('.previous_conversations');

    for (const eachElement of prevConvoElements){

        
        const element_UUID=eachElement.getAttribute("token_uuid");

        eachElement.addEventListener('click',()=>{
            const uuidFromUrl = element_UUID;

            if (!uuidFromUrl){//if uuid in url is invalid
                return;
            }

            //if user reselects the same element then this prevents me from calling the database again for the chat history
            if(state.conversationTokenUUID === uuidFromUrl){
                return;
            }

            //remove previous chat history before showing current chat history
            document.getElementById('ai_and_user_container').innerHTML='';
            addUuidToUrl(element_UUID);
            load_current_convo_from_UUID();
        });
    }
}




addEventListenerToLoadPastConversations();
