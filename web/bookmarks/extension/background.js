const DEFAULT_SERVER_URL = "https://localhost";

chrome.commands.onCommand.addListener((command) => {
  if (command === "submit-bookmark") {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      const activeTab = tabs[0];
      if (activeTab) {
        handleSubmission(activeTab.url, activeTab.title);
      }
    });
  }
});

async function getServerUrl() {
  const data = await chrome.storage.local.get("serverUrl");
  return data.serverUrl || DEFAULT_SERVER_URL;
}

async function handleSubmission(url, title) {
  try {
    const serverUrl = await getServerUrl();
    
    // 1. Fetch the submit page to get a CSRF token
    const getResponse = await fetch(`${serverUrl}/submit`);
    if (!getResponse.ok) throw new Error(`Failed to reach server at ${serverUrl}`);

    const html = await getResponse.text();

    // Parse CSRF token from the hidden input
    const csrfMatch = html.match(/name="csrf_token" value="([^"]+)"/);
    if (!csrfMatch) throw new Error("CSRF token not found. Please log in to your Bookmarks site.");
    const token = csrfMatch[1];

    // 2. Perform the POST submission
    const formData = new URLSearchParams();
    formData.append("title", title);
    formData.append("url", url);
    formData.append("csrf_token", token);

    const postResponse = await fetch(`${serverUrl}/submit`, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: formData.toString(),
      redirect: "manual"
    });

    if (postResponse.status === 0 || postResponse.ok || postResponse.status === 303) {
      showNotification("Success", `Bookmarked: ${title}`);
    } else {
      throw new Error(`Submission failed: ${postResponse.status}`);
    }

  } catch (error) {
    console.error("Bookmark Error:", error);
    showNotification("Error", error.message);
  }
}

function showNotification(title, message) {
  chrome.notifications.create({
    type: "basic",
    iconUrl: "icon-128.png",
    title: title,
    message: message,
    priority: 2
  });
}
