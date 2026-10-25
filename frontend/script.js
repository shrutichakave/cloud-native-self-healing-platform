
async function checkHealth() {
    const appStatus = document.getElementById("app-status");
    const serviceStatus = document.getElementById("service-status");
    const result = document.getElementById("result");
    document.getElementById("health-alert").hidden = true;

    try {
        const response = await fetch("/api/health", {
            cache: "no-store"
        });

        if (!response.ok) {
            throw new Error("Backend health check failed");
        }

        const data = await response.json();

         if (data.status === "healthy") {
            appStatus.textContent = "Healthy";
            serviceStatus.textContent = "Healthy";
            serviceStatus.className = "status healthy";
            result.textContent = "Backend is running correctly.";

            // Show green when healthy
            appStatus.closest(".summary-card").classList.remove("unhealthy-card");
            appStatus.closest(".summary-card").classList.add("healthy-card");
        } else {
            showUnhealthy("Backend reported an unhealthy status.");
        }

    } catch (error) {
        showUnhealthy("Backend is unavailable. Check whether the service is running.");
    }
}


function showUnhealthy(message) {
    const appStatus = document.getElementById("app-status");
    const serviceStatus = document.getElementById("service-status");
    const result = document.getElementById("result");
    document.getElementById("health-alert").hidden = false;

    appStatus.textContent = "Unhealthy";
    serviceStatus.textContent = "Unhealthy";
    serviceStatus.className = "status unhealthy";
    result.textContent = message;

    // Turn the application health card light red
    appStatus.closest(".summary-card").classList.add("unhealthy-card");
    const healthCard = appStatus.closest(".summary-card");
    healthCard.classList.remove("healthy-card");
    healthCard.classList.add("unhealthy-card");
}


// Check immediately and repeat every 10 seconds
checkHealth();
setInterval(checkHealth, 10000);
