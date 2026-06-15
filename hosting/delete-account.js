const form = document.querySelector("#deletion-form");
const submitButton = document.querySelector("#submit-button");
const statusElement = document.querySelector("#form-status");

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  submitButton.disabled = true;
  statusElement.className = "status";
  statusElement.textContent = "";

  const formData = new FormData(form);
  const payload = Object.fromEntries(formData.entries());

  try {
    const response = await fetch("/api/account-deletion-request", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(payload),
    });
    const result = await response.json();
    if (!response.ok) {
      throw new Error(result.error || "Unable to submit the request.");
    }
    form.reset();
    statusElement.className = "status success";
    statusElement.textContent =
      "Request received. We will verify the account before deletion.";
  } catch (error) {
    statusElement.className = "status error";
    statusElement.textContent =
      error.message || "Unable to submit the request. Please try again.";
  } finally {
    submitButton.disabled = false;
  }
});
