import { addUuidToUrl } from "./utility.js"; // This import is duplicated, but one is needed. Let's keep it clean.
import { state,load_current_convo_from_UUID } from "./api.js"; // This is the function that needs to be imported.


let hasChatHistory =false;
let isOrientedPortrait =false;
let portraitOpenSidebar=false;
let chatHistoryContainer= document.getElementById('ai_and_user_container');


export function removeWelcomeMessage(){
    
    hasChatHistory = true; //indicate that text has been added to the container that shows convo history

    chatHistoryContainer.style.display="block";
    document.getElementById("current_convo_container").style.justifyContent="flex-start";

    if(isOrientedPortrait){//if screen is portrait then allow div to support 3 rows
        document.getElementById("main_container").style.gridTemplateRows="50px 1fr auto";
    
    }
    else{ //if screen is lanscape then we would only support 2 rows
    document.getElementById("main_container").style.gridTemplateRows="1fr auto";
    

    }

}

export function applyResponsiveStyles() {


	const isNarrowScreen_960 = window.innerWidth <= 960;
	const isNarrowScreen_750 = window.innerWidth <= 750;
	let sidebar = document.getElementById("sidebar");
	const isPortrait = window.matchMedia("(orientation: portrait)").matches;
	const main_container = document.getElementById('main_container');
	const userItems = document.getElementById('user_interaction_items');
	const aiContainer = document.getElementById('ai_and_user_container');
	const userContainer = document.getElementById('user_interaction_container');
	const currentConvoContainer = document.getElementById('current_convo_container');
	const portrait_sidebar_control = document.getElementById('portrait_sidebar_control');

	function narrowLandscapeScreen(){
		
		userItems.style.width = 'auto';
		// Get actual pixel width of userItems
		const actualWidth = userItems.offsetWidth;
		// Apply adjusted width to aiContainer
		aiContainer.style.width = (actualWidth - 20) + 'px';
		// Apply padding
		userContainer.style.padding = '0px 20px';


	}


    // reset element that may be potentially changed
    main_container.style.gridTemplateColumns = "";
    main_container.style.gridTemplateRows = "";
    currentConvoContainer.style.padding = "";
	portrait_sidebar_control.style.display='none';

	if(!portraitOpenSidebar){
		sidebar.style.display='';
	}


	//check if container with current ai and user history has content in it and 
	// change screen elements accordingly
	if(hasChatHistory){
		
		main_container.style.gridTemplateRows="1fr auto";

	}
	else{ //if the continer with current convo historyy is blank
		main_container.style.gridTemplateRows='40% 60%';

	}

	

	if(isPortrait||isNarrowScreen_750){

		if(!portraitOpenSidebar){
		sidebar.style.display='none';
		}

		main_container.style.gridTemplateColumns='auto';
		narrowLandscapeScreen();
		portrait_sidebar_control.style.display='flex';

		if(hasChatHistory){ // if container with current convo history is populated
			
			main_container.style.gridTemplateRows="50px 1fr auto";

		}
		else{ //if the container with current convo history is blank

			main_container.style.gridTemplateRows="50px auto 60%";

		}

		

		isOrientedPortrait=true;

		console.log("Portrait or less than or equl 750");

	}
	//check if windows size is equal to or smaller than 960px
	else if (isNarrowScreen_960) {

		narrowLandscapeScreen();
		isOrientedPortrait=false;

		closePortraitSidebar()
		sidebar.style.display="";
		console.log("less than or equl 950");
	}
	else {//landscape
		// Reset styles for wider screens
		userItems.style.width = '';
		aiContainer.style.width = '';

		userContainer.style.padding = '';
		aiContainer.style.padding = '';
		currentConvoContainer.style.padding = '0px';
				isOrientedPortrait=false;
		console.log("else portion");
	}
  
}




function controlSidebarText(action){
    const sidebar_text = document.querySelectorAll('.sidebar_text');

      // Loop through and hide each one
    sidebar_text.forEach(eachElement => {
      eachElement.style.display = action;
    });
}


function expandSidebar(){

	let sidebar = document.getElementById("sidebar");
	let sidebarIcon = document.getElementById('sidebar_icon');
	sidebar.style.width="220px";
	controlSidebarText("inline");//display sidebar text
	document.getElementById("conversation_history_container").style.display='block';//show chat history

	document.getElementById('student_fullname').style.display='inline';
	document.getElementById('new_chat_container').style.textAlign ="";
	sidebarIcon.src="/static/images/sidebar_close.svg"; //change image to represent if the sidebar eill expand or collapse
	sidebarIcon.title="Close Sidebar";//user sees appropriate title when they hover
}

export function controlSidebar() {

	let sidebar = document.getElementById("sidebar");
	let sidebarIcon = document.getElementById('sidebar_icon');


	if (isOrientedPortrait){
		sidebar.style.display='none';
		document.getElementById('sidebar-overlay').style.display='none';
		return;
	}
	

	//expand the sidepanel
	if(sidebar.style.width=="40px"){

		expandSidebar();

		return;//no more changes will take effect
	}


	//reduce width of sidebar 
	sidebar.style.width="40px";
	sidebarIcon.src="/static/images/sidebar_open.svg";
	sidebarIcon.title="Open Sidebar";
	document.getElementById('new_chat_container').style.textAlign ='center';

	controlSidebarText("none");//hide sidebar text
	document.getElementById("conversation_history_container").style.display='none';


}




export function controlPortraitSidebar() {

  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebar-overlay');

  expandSidebar();

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
  portraitOpenSidebar = true;

  overlay.onclick = () => {
      closePortraitSidebar();
  };
}


function closePortraitSidebar() {
    document.getElementById('sidebar').classList.remove('open');
    document.getElementById('sidebar-overlay').classList.remove('show');
    portraitOpenSidebar = false;
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

        
        console.log(eachElement);
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
