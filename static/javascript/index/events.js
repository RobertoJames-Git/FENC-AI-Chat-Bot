import { controlSidebar,controlPortraitSidebar,applyResponsiveStyles } from "./ui.js";
import { sendQuestion } from "./api.js";

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


console.log("Run")

// Reapply styles on window resize
window.addEventListener('resize', applyResponsiveStyles);

const sendArrow = document.getElementById("send_arrow");
sendArrow.addEventListener('click',sendQuestion);

const sidebarIcon = document.getElementById("sidebar_icon")
sidebarIcon.addEventListener('click',controlSidebar)

const sidebarIconPortrait = document.getElementById('sidebar_icon_portrait');
sidebarIconPortrait.addEventListener('click',controlPortraitSidebar)


document.addEventListener("DOMContentLoaded", function () {
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
  });
  

  
applyResponsiveStyles();