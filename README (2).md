# Cloud-Native Self-Healing Platform

## 1. Project Overview

I developed the **Cloud-Native Self-Healing Platform** to demonstrate how DevOps and cloud-native technologies can be used to automate application deployment, recover from failures, scale applications and monitor system health.

I used AWS, Terraform, Docker, Jenkins and Kubernetes to build and deploy the application. I also integrated Trivy for container image security scanning, Prometheus for monitoring and Grafana for dashboard visualization.

### Main objectives

- Automate application build and deployment.
- Provision AWS infrastructure using Terraform.
- Containerize frontend and backend applications using Docker.
- Store container images in Amazon ECR.
- Deploy applications on Amazon EKS.
- Demonstrate Kubernetes self-healing.
- Automatically scale backend pods using HPA.
- Monitor application and cluster metrics using Prometheus and Grafana.

## 2. Technologies Used

| Technology | Purpose |
|---|---|
| AWS EC2 | Hosting Jenkins |
| AWS IAM | Managing permissions |
| AWS VPC | Cloud networking |
| Amazon ECR | Storing Docker images |
| Amazon EKS | Managed Kubernetes |
| Terraform | Infrastructure as Code |
| Docker | Containerization |
| Jenkins | CI/CD automation |
| Kubernetes | Container orchestration |
| Trivy | Container image security scanning |
| Metrics Server | CPU and memory metrics |
| Prometheus | Metrics collection and storage |
| Grafana | Monitoring dashboards |
| HPA | Automatic pod scaling |

## 3. Project Architecture

### Application deployment workflow

1. I maintain the application source code in GitHub.
2. Jenkins retrieves the source code from the repository.
3. Jenkins builds frontend and backend Docker images.
4. Trivy scans the images for security vulnerabilities.
5. Jenkins authenticates with Amazon ECR using its IAM role.
6. Jenkins pushes the images to ECR.
7. Jenkins deploys the application to Amazon EKS.
8. Kubernetes manages the application pods and services.
9. Kubernetes replaces deleted or failed Deployment-managed pods.
10. HPA scales backend replicas based on CPU utilization.

### Monitoring workflow

Kubernetes metrics and monitoring targets → Prometheus → Grafana

## 4. AWS Environment Configuration

| Configuration | Project value |
|---|---|
| AWS Account ID | 290993050816 |
| AWS Region | ap-south-1 |
| EKS Cluster | self-healing-eks |
| EKS Node Group | self-healing-eks-nodes |
| Jenkins EC2 | self-healing-jenkins |
| Jenkins Instance ID | i-0b730ce0834f89de0 |
| Jenkins IAM Role | JenkinsECRAccessRole |
| Backend ECR | self-healing-backend |
| Frontend ECR | self-healing-frontend |

### ECR image locations

**Backend**
```text
290993050816.dkr.ecr.ap-south-1.amazonaws.com/self-healing-backend:v2
```

**Frontend**
```text
290993050816.dkr.ecr.ap-south-1.amazonaws.com/self-healing-frontend:v2
```

## 5. Infrastructure Provisioning Using Terraform

I used Terraform to provision the AWS infrastructure.

The infrastructure includes:

- VPC and public subnets.
- Internet Gateway and route tables.
- IAM roles and policy attachments.
- Amazon ECR repositories.
- Amazon EKS cluster.
- EKS managed node group.

### Terraform commands

```bash
cd ~/cloud-native-self-healing-platform/terraform
terraform init
terraform validate
terraform plan
terraform apply
```

I used `terraform plan` to review infrastructure changes before applying them.

The earlier Terraform apply completed with:

```text
15 resources added
0 resources changed
0 resources destroyed
```

The current Terraform state lists 17 resource addresses. These are current state entries and should not be confused with the earlier apply result.

The latest plan showed one in-place EKS configuration change and no resources to add or destroy. That planned change should be reviewed before applying it.

## 6. Docker Containerization

I used Docker to package the frontend and backend applications into separate container images.

The backend Dockerfile uses Node.js:

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY server.js .
EXPOSE 3000
CMD ["node", "server.js"]
```

I built the frontend and backend images independently and used version tags to identify the images.

## 7. Amazon ECR

I used Amazon Elastic Container Registry to store the Docker images.

The two repositories are:

- `self-healing-backend`
- `self-healing-frontend`

Jenkins pushes the images to ECR, and the EKS worker nodes retrieve the images when Kubernetes deploys the application.

## 8. Amazon EKS and Kubernetes

I deployed the application on Amazon Elastic Kubernetes Service.

Cluster name:

```text
self-healing-eks
```

Node group:

```text
self-healing-eks-nodes
```

To connect to the cluster:

```bash
aws eks update-kubeconfig --region ap-south-1 --name self-healing-eks
```

Useful commands:

```bash
kubectl get nodes
kubectl get pods
kubectl get deployments
kubectl get services
```

### Kubernetes Services

- **Frontend Service:** LoadBalancer, which provides external access to the frontend.
- **Backend Service:** ClusterIP, which provides internal cluster communication.

### Frontend application URL

```text
http://a1310bd6ae2f849c7a4a07003cd2a2b2-1308337589.ap-south-1.elb.amazonaws.com
```

## 9. Jenkins CI/CD Pipeline

I configured Jenkins to automate the application deployment process.

### Pipeline stages

1. Checkout source code from GitHub.
2. Verify required project files.
3. Build the backend Docker image.
4. Scan the backend image using Trivy.
5. Build the frontend Docker image.
6. Scan the frontend image using Trivy.
7. Authenticate with Amazon ECR.
8. Push backend and frontend images to ECR.
9. Deploy the images to Amazon EKS.
10. Verify Kubernetes deployment rollouts.

The Jenkins pipeline completed successfully with:

```text
Finished: SUCCESS
```

I configured Jenkins to use the EC2 instance profile role `JenkinsECRAccessRole` for AWS access instead of hardcoding AWS access keys.

**Jenkins status:** The Jenkins EC2 instance is currently stopped to reduce running compute costs. It can be started again when a live CI/CD demonstration is required. Its public IP may change after restarting if it does not have an Elastic IP.

## 10. Kubernetes Self-Healing

One of the main features I implemented is Kubernetes self-healing.

Kubernetes Deployments maintain the desired number of application replicas. If a Deployment-managed pod is deleted or fails, Kubernetes creates a replacement.

### Testing self-healing

I used:

```bash
kubectl get pods
```

I deleted a backend pod:

```bash
kubectl delete pod BACKEND_POD_NAME
```

Then I watched the pods:

```bash
kubectl get pods -w
```

I observed Kubernetes create a replacement backend pod automatically.

**Result:** Self-healing was successfully demonstrated.

## 11. Horizontal Pod Autoscaler

I configured HPA to scale the backend application according to CPU utilization.

### Backend HPA configuration

| Setting | Value |
|---|---|
| Minimum replicas | 2 |
| Maximum replicas | 5 |
| CPU target | 70% |

To check HPA:

```bash
kubectl get hpa
```

To check resource usage:

```bash
kubectl top pods
```

### Autoscaling test

I used a BusyBox load generator to send requests to the backend service.

```bash
kubectl run load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://backend-service:3000/ >/dev/null 2>&1; done"
```

I monitored HPA:

```bash
kubectl get hpa -w
```

During testing, backend replicas increased up to 4. After I removed the load generator, the replica count returned to 2.

**Result:** HPA scaling and scale-down were successfully demonstrated.

## 12. Kubernetes Metrics Server

I installed Metrics Server to provide CPU and memory usage information to Kubernetes.

I used it for:

- `kubectl top pods`
- `kubectl top nodes`
- Horizontal Pod Autoscaler

Commands:

```bash
kubectl get deployment metrics-server -n kube-system
kubectl top pods
kubectl top nodes
```

Metrics Server is different from Prometheus. Metrics Server provides resource metrics for Kubernetes, while Prometheus collects and stores time-series monitoring data.

## 13. Prometheus Monitoring

I deployed Prometheus using the Prometheus Community `kube-prometheus-stack` Helm chart.

Namespace:

```text
monitoring
```

Helm release:

```text
monitoring
```

To check monitoring pods:

```bash
kubectl get pods -n monitoring
```

To access Prometheus locally:

```bash
kubectl port-forward \
  -n monitoring \
  svc/monitoring-kube-prometheus-prometheus \
  9090:9090
```

I opened:

```text
http://localhost:9090
```

I used the following PromQL query to check scrape target status:

```promql
up
```

## 14. Grafana Dashboard

I connected Grafana to Prometheus as its data source.

My CloudCare dashboard contains seven monitoring panels:

1. CPU usage.
2. Memory usage.
3. Pod count.
4. Pod health.
5. Backend pod creation timestamp.
6. Backend pod count.
7. Backend replica count.

To access Grafana locally:

```bash
kubectl port-forward \
  -n monitoring \
  svc/monitoring-grafana \
  3000:80
```

I opened:

```text
http://localhost:3000
```

I used port forwarding to access Grafana without exposing the dashboard as a public AWS service.

## 15. Project Testing and Results

I performed the following tests during development and verification.

| Test | Result |
|---|---|
| Terraform infrastructure provisioning | Successful |
| Docker image builds | Successful |
| ECR image push | Successful |
| Jenkins CI/CD pipeline | SUCCESS |
| EKS worker node health | Verified |
| Frontend and backend deployment | Verified |
| Kubernetes self-healing | Successful |
| HPA scaling under load | Successful |
| HPA scale-down | Successful |
| Metrics Server | Verified |
| Prometheus | Verified |
| Grafana | Verified |

### Latest application health verification

During my latest check:

- Both EKS worker nodes were `Ready`.
- Two backend pods were `Running`.
- Two frontend pods were `Running`.
- All four application pods showed `1/1 Ready`.
- All four application pods showed zero restarts.
- The frontend website was accessible.
- Backend HPA showed 2 replicas, with CPU usage at 8% against a 70% target.
- Prometheus, Grafana, Alertmanager and other monitoring components were running.

## 16. Useful Kubernetes Commands

```bash
kubectl get nodes
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get hpa
kubectl describe hpa
kubectl top pods
kubectl top nodes
kubectl get pods -w
kubectl get pods -n monitoring
```

## 17. Project Demonstration

For my project evaluation, I demonstrate the following:

1. Introduce the project and its objectives.
2. Show the GitHub repository.
3. Explain Terraform infrastructure provisioning.
4. Show the Jenkins EC2 instance and IAM role.
5. Show the successful Jenkins pipeline.
6. Show the ECR repositories and image tags.
7. Show the EKS cluster and worker nodes.
8. Open the frontend application.
9. Demonstrate Kubernetes self-healing.
10. Explain HPA and the autoscaling test.
11. Open Prometheus and run the `up` query.
12. Open Grafana and explain the dashboard panels.
13. Summarize the project results.

## 18. Cost Management

AWS resources can incur charges while running.

I stopped the Jenkins EC2 instance when it was not needed to reduce compute costs. The EKS cluster and its worker nodes remain available for application testing and project evaluation.

Stopping an EC2 instance does not necessarily remove all charges. Attached storage and public IP resources may still incur costs.

After the evaluation, I will review the AWS resources and remove only those that are no longer required.

I will not run `terraform destroy` before the project evaluation.

## 19. Conclusion

Through this project, I implemented a cloud-native DevOps workflow using AWS and open-source technologies.

I used Terraform to provision infrastructure, Docker to containerize applications, Jenkins to automate CI/CD, Amazon ECR to store images and Amazon EKS with Kubernetes to deploy and manage applications.

I also demonstrated Kubernetes self-healing, HPA-based autoscaling and monitoring using Prometheus and Grafana.

**The Cloud-Native Self-Healing Platform demonstrates how automation, container orchestration, self-healing, autoscaling and monitoring can work together to improve application reliability and simplify deployment management.**