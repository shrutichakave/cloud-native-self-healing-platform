const express = require("express");
const cors = require("cors");
const client = require("@prometheus-io/client");
const k8s = require("@kubernetes/client-node");

const app = express();
const port = 3000;

app.use(cors());
client.collectDefaultMetrics();

// Kubernetes API access using the pod's ServiceAccount
const kubeConfig = new k8s.KubeConfig();
kubeConfig.loadFromCluster();
const autoscalingApi = kubeConfig.makeApiClient(k8s.AutoscalingV2Api);
const appsApi = kubeConfig.makeApiClient(k8s.AppsV1Api);

app.get("/", (req, res) => {
  res.json({
    message: "Cloud-Native Self-Healing Platform is running!",
    status: "healthy"
  });
});

app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

// Live Kubernetes autoscaling information
app.get(["/api/autoscaling", "/autoscaling"], async (req, res) => {
  try {
    const [hpaResponse, deploymentResponse] = await Promise.all([
      autoscalingApi.readNamespacedHorizontalPodAutoscaler({
        name: "backend-hpa",
        namespace: "default"
      }),
      appsApi.readNamespacedDeployment({
        name: "backend",
        namespace: "default"
      })
    ]);

    const hpa = hpaResponse.body ?? hpaResponse;
    const deployment = deploymentResponse.body ?? deploymentResponse;

    const cpuMetric = (hpa.spec.metrics || []).find(
      metric =>
        metric.resource &&
        metric.resource.name === "cpu"
    );

    res.set("Cache-Control", "no-store");
    res.json({
      status: hpa.status.conditions?.some(
        condition =>
          condition.type === "AbleToScale" &&
          condition.status === "True"
      ) ? "active" : "checking",
      currentCPUUtilization: hpa.status.currentCPUUtilizationPercentage ?? null,
      targetCPUUtilization:
        cpuMetric?.resource?.target?.averageUtilization ?? null,
      currentReplicas: hpa.status.currentReplicas ?? 0,
      desiredReplicas: hpa.status.desiredReplicas ?? 0,
      readyReplicas: deployment.status.readyReplicas ?? 0,
      minReplicas: hpa.spec.minReplicas ?? 1,
      maxReplicas: hpa.spec.maxReplicas,
      lastScaleTime: hpa.status.lastScaleTime ?? null
    });
  } catch (error) {
    console.error("Autoscaling API error:", error.response?.body || error.body || error.stack || error.message);
    res.status(503).json({
      error: "Unable to retrieve live Kubernetes autoscaling data"
    });
  }
});

// Prometheus metrics
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", client.prometheusContentType);
  res.end(await client.register.metrics());
});

app.listen(port, () => {
  console.log(`Backend running on port ${port}`);
});
