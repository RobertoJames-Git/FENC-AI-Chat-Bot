
function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

export function formatMarkdown(text) {
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

  return html.trim();
}


export function addUuidToUrl(currentUUID){

    const newUrl = `/chat/${currentUUID}`;
    changeURL(newUrl);
    
}

function changeURL (newUrl){
    window.history.pushState({}, '', newUrl);//update url with uuid without a page reload

}

export function resetUrl(){

    changeURL('/');

}


export function getUUIDFromUrl() {
    const currentURL = window.location.href;

    if (!currentURL.includes("/chat/")) {
        return null;
    }

    const uuid = currentURL.split('/').pop();

    // If tampered → return null
    // Accepts only a UUID-like pattern: xxxx-xxxx-xxxx-xxxx...
    const pattern = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/; 
    if (!pattern.test(uuid)) {//if pattern is not mtched then uuid is invalid
        resetUrl();//reset url with uuid without a page reload
        return null;
    }

    return uuid;
}
