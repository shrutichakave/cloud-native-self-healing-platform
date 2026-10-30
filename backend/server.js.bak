
const express = require("express");
const cors = require("cors");
const client = require("@prometheus-io/client");

const app = express();
const port = 3000;

// Allow frontend requests
app.use(cors());

// Collect Node.js metrics for Prometheus
client.collectDefaultMetrics();

// Home page
app.get("/", (req, res) => {
  res.json({
    message: "Cloud-Native Self-Healing Platform is running!",
    status: "healthy"
  });
});

// Check if the backend is healthy
app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

// Send metrics to Prometheus
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", client.prometheusContentType);
  res.end(await client.register.metrics());
});

// Start the backend server
app.listen(port, () => {
  console.log(`Backend running on port ${port}`);
});
