# Todo App - EKS Deployment Guide

This guide walks you through deploying the Todo application on Amazon EKS with blue-green deployment strategy.

## Prerequisites

- AWS CLI configured with credentials
- kubectl installed
- Docker installed

## Step 1: Create EKS Cluster

## Step 2: Configure kubectl

```bash
# Update kubeconfig to connect to your cluster
aws eks update-kubeconfig --name todo-app-cluster --region eu-central-1

# Verify connection
kubectl get nodes
```

## Step 3: Build and Push Docker Images

```bash
# Get your AWS Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Login to ECR
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com

# Create ECR repository (if not exists)
aws ecr create-repository --repository-name rd/todo-app --region eu-central-1 || echo "Repository already exists"

# Build and push backend (AMD64 architecture for EKS nodes)
cd backend
docker buildx build --platform linux/amd64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/rd/todo-app:backend-latest --push .

# Build and push frontend
cd ../frontend
docker buildx build --platform linux/amd64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/rd/todo-app:frontend-latest --push .

cd ..
```

## Step 4: Deploy Static Resources

Deploy namespace, services, configmaps, secrets, and MongoDB:

```bash
# 1. Namespace
kubectl apply -f k8s/todo-namespace.yaml

# 2. ConfigMaps
kubectl apply -f k8s/backend-configmap.yaml
kubectl apply -f k8s/frontend-configmap.yaml

# 3. Secrets (update with your MongoDB credentials)
kubectl apply -f k8s/mongodb-secret.yaml

# 4. MongoDB StatefulSet and Service
kubectl apply -f k8s/mongodb-set.yaml
kubectl apply -f k8s/mongodb-service.yaml

# 5. Backend and Frontend Services
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-service.yaml

```

### Verify Static Resources

```bash
# Check all resources
kubectl get all -n todo-app

# Should see:
# - service/backend (ClusterIP)
# - service/frontend (LoadBalancer)
# - service/mongodb (ClusterIP)
# - statefulset/mongodb
# - pod/mongodb-0
```

## Step 5: Blue-Green Deployment

### Initial Deployment (v1)

```bash
# Deploy version 1
./blue_green_deploy.sh "" v1

# This will:
# - Create backend-v1 and frontend-v1 deployments
# - Wait for pods to be ready
# - Configure services to route traffic to v1
```

### Get Frontend URL

```bash
# Get the LoadBalancer URL
kubectl get service frontend -n todo-app

# Wait for EXTERNAL-IP to be assigned (takes 2-3 minutes)
# Then open http://<EXTERNAL-IP> in your browser
```

### Deploy New Version (v2)

When you want to deploy a new version:

```bash
# 1. Update your code and rebuild images with new tag or same tag
docker buildx build --platform linux/amd64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/rd/todo-app:backend-latest --push ./backend
docker buildx build --platform linux/amd64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.eu-central-1.amazonaws.com/rd/todo-app:frontend-latest --push ./frontend

# 2. Run blue-green deployment
./blue_green_deploy.sh v1 v2

# This will:
# - Deploy backend-v2 and frontend-v2 alongside v1 (both running)
# - Wait for v2 to be ready
# - Switch service traffic from v1 to v2 (instant cutover)
# - Delete v1 deployments
```

## Step 6: Verify Deployment

```bash
# Check deployment status
kubectl get deployments -n todo-app

# Check pods
kubectl get pods -n todo-app

# Check which version is active
kubectl get service backend -n todo-app -o jsonpath='{.spec.selector.version}'

# View logs
kubectl logs -n todo-app -l app=backend --tail=50
kubectl logs -n todo-app -l app=frontend --tail=50
```

## Blue-Green Deployment Explained

### How it Works

1. **Deploy Green (new version)**: New deployments are created alongside existing ones
   - `backend-v1` and `backend-v2` run simultaneously
   - `frontend-v1` and `frontend-v2` run simultaneously

2. **Test Green**: Verify v2 is healthy before switching traffic

3. **Switch Traffic**: Service selectors are updated instantly
   ```yaml
   selector:
     app: backend
     version: v2  # Changed from v1
   ```

4. **Cleanup Blue**: Old version deployments are deleted

### Script Usage

```bash
./blue_green_deploy.sh <old-version> <new-version>

# Examples:
./blue_green_deploy.sh "" v1      # Initial deployment
./blue_green_deploy.sh v1 v2      # Deploy v2, switch from v1
```

## Kustomize Structure

The deployment uses Kustomize for managing different versions:

```
k8s/deployments/
├── base/                          # Base deployment manifests
│   ├── kustomization.yaml
│   ├── backend-deployment.yaml
│   └── frontend-deployment.yaml
└── overlays/                      # Version-specific overlays
    ├── v1/
    │   └── kustomization.yaml     # Adds -v1 suffix and version: v1 label
    └── v2/
        └── kustomization.yaml     # Adds -v2 suffix and version: v2 label
```

## Cleanup

To delete everything:

```bash
# Delete all deployments
kubectl delete deployments --all -n todo-app

# Delete all resources in namespace
kubectl delete namespace todo-app

# Delete EKS cluster
eksctl delete cluster --name todo-app-cluster --region eu-central-1
```