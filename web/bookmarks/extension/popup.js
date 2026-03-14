document.addEventListener('DOMContentLoaded', async () => {
  const input = document.getElementById('serverUrl');
  const saveBtn = document.getElementById('save');

  // Load existing setting
  const data = await chrome.storage.local.get("serverUrl");
  if (data.serverUrl) {
    input.value = data.serverUrl;
  } else {
    input.value = "https://localhost"; // Default
  }

  saveBtn.addEventListener('click', async () => {
    const url = input.value.trim().replace(/\/$/, ""); // Remove trailing slash
    await chrome.storage.local.set({ serverUrl: url });
    
    saveBtn.textContent = "Saved!";
    saveBtn.style.background = "#056162";
    
    setTimeout(() => {
      saveBtn.textContent = "Save Settings";
      saveBtn.style.background = "#00a884";
    }, 2000);
  });
});
