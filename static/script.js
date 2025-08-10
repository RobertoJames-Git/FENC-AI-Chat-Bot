document.addEventListener('DOMContentLoaded', () => {
    const textarea = document.getElementById('userInput');

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


function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}



function formatMarkdown(text) {
  // 1) Sanitize, then convert bold/italic
  text = escapeHtml(text)
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/(^|[^*])\*(?!\s)([^*]+?)\*(?!\*)/g, '$1<em>$2</em>');

  const lines = text.split('\n');
  let html = '';
  const stack = [];           // tracks open <ul> levels
  const indentSize = 4;       // assumes 4 spaces = one nested level

  lines.forEach(raw => {
    const match = raw.match(/^(\s*)\* (.+)/);

    if (match) {
      const indent = match[1].length;
      const content = match[2].trim();
      const level = Math.floor(indent / indentSize);

      // 2) Close deeper lists if we backed up
      while (stack.length > level + 1) {
        html += '</li></ul>';
        stack.pop();
      }

      // 3) Open new nested lists if we went deeper
      while (stack.length < level + 1) {
        html += '<ul>';
        stack.push(true);
      }

      // 4) If we're still in the same list level, close previous <li>
      if (html.endsWith('</li>')) {
        html += '</li>';
      }

      // 5) Add this item
      html += `<li>${content}`;
    }
    else {
      // 6) close any open lists before dumping a paragraph
      while (stack.length) {
        html += '</li></ul>';
        stack.pop();
      }
      const trimmed = raw.trim();
      if (trimmed) html += `<p>${trimmed}</p>`;
    }
  });

  // 7) close any final open lists
  while (stack.length) {
    html += '</li></ul>';
    stack.pop();
  }

  return html;
}




async function sendQuestion() {
    const userInput = document.getElementById("userInput").value.trim();//retrieve what the user entered in the input
    
    //do not send a request to the backend if user input is empty
    if(userInput==""){
    return;
    }

    document.getElementById("userInput").value = ""; //clear inpur field after user sends question

    insertUserMessage("user",userInput);//add users message to the container above the textbox
    document.getElementById("ai_and_user_container").style.display="block";
    document.getElementById("current_convo_container").style.justifyContent="flex-start";
    document.getElementById("main_container").style.gridTemplateRows="1fr auto";
    
    //scroll to the bottom of the page
    const container = document.getElementById("current_convo_container");
    container.scrollTop = container.scrollHeight;
    
    //add loading icon
    const loadingIcon = document.createElement('div');//create div
    loadingIcon.id='loading_icon'; //add class to div
    //add loading icon to div with ai and user conversation
    document.getElementById("ai_and_user_container").appendChild(loadingIcon);

    const res = await fetch("/ask", {
    method: "POST",
    headers: {
        "Content-Type": "application/json"
    },
    body: JSON.stringify({ question: userInput })
    });
    const data = await res.json();
    console.log(data);
    
    if(data.response){
    formattedResponse = formatMarkdown(data.response);
    }
    else{
        insertUserMessage("ai_response_error",data.error);
    }

    //remove loading icon
    loadingIcon.remove()

    insertUserMessage("ai_response",formattedResponse.trim());

}






function insertUserMessage(userRole,messageText) {
    document.getElementById("welcome_message")?.remove();//removes welcome message if it exists
    if (messageText === "") return; // Avoid empty messages

    // Create the new div
    const userDiv = document.createElement("div");
    userDiv.className = userRole;
    if(userRole === "ai_response"){
    userDiv.innerHTML = messageText;
    }
    else{
    userDiv.textContent = messageText;
    }

    // Append to the conversation container
    const convoContainer = document.getElementById("ai_and_user_container");
    convoContainer.appendChild(userDiv);
    const scrollParent = document.getElementById("current_convo_container");
    scrollParent.scrollTop = scrollParent.scrollHeight;

}
