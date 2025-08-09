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
