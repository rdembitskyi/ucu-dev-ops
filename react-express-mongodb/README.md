# Kubernetes Deployment Guide

This guide explains how to deploy the React-Express-MongoDB Todo application to Kubernetes (Minikube).

## Application Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    User's Browser                        │
└────────────────────────┬────────────────────────────────┘
                         ↓
                 http://localhost:3000
                         ↓
┌─────────────────────────────────────────────────────────┐
│              Frontend Service (NodePort)                 │
│              Port: 3000 → Container: 3000                │
└────────────────────────┬────────────────────────────────┘
                         ↓
            ┌────────────┴────────────┐
            ↓                         ↓
    ┌──────────────┐          ┌──────────────┐
    │  Frontend    │          │  Frontend    │
    │  Pod         │   ...    │  Pod         │
    │  (React)     │          │  (React)     │
    │  Port: 3000  │          │  Port: 3000  │
    └──────────────┘          └──────────────┘
            │
            ↓
┌─────────────────────────────────────────────────────────┐
│              Backend Service (ClusterIP)                 │
│              Port: 3001 → Container: 3001                │
└────────────────────────┬────────────────────────────────┘
                         ↓
            ┌────────────┴────────────┐
            ↓                         ↓
    ┌──────────────┐          ┌──────────────┐
    │  Backend     │          │  Backend     │
    │  Pod         │   ...    │  Pod         │
    │  (Express)   │          │  (Express)   │
    │  Port: 3001  │          │  Port: 3001  │
    └──────┬───────┘          └──────┬───────┘
           │                         │
           └────────┬────────────────┘
                    ↓
         mongodb://admin:***@mongo:27017/TodoApp
                    ↓
┌─────────────────────────────────────────────────────────┐
│              MongoDB Service (ClusterIP)                 │
│              Port: 27017 → Container: 27017              │
└────────────────────────┬────────────────────────────────┘
                         ↓
                 ┌───────────────┐
                 │   MongoDB     │
                 │   Pod         │
                 │   Port: 27017 │
                 └───────┬───────┘
                         ↓
                 ┌───────────────┐
                 │ Persistent    │
                 │ Volume        │
                 │ (128Mi)       │
                 └───────────────┘
```

## Components

### 1. **Frontend (React)**
- **Service Type**: NodePort (externally accessible)
- **Port**: 3000
- **Features**:
  - Todo list UI
  - Proxies API requests to backend
  - Environment variable: `REACT_APP_BACKEND_URL`

### 2. **Backend (Express/Node.js)**
- **Service Type**: ClusterIP (internal only)
- **Port**: 3001
- **Features**:
  - RESTful API (`GET /api`, `POST /api/todos`)
  - Connects to MongoDB with authentication
  - Configuration via ConfigMap and Secret

### 3. **MongoDB**
- **Service Type**: ClusterIP (internal only)
- **Port**: 27017
- **Features**:
  - Persistent storage (512Mi)
  - Authentication enabled
  - Credentials stored in Kubernetes Secret

## Prerequisites

1. **Minikube** installed and running
   ```bash
   minikube start
   ```

2. **kubectl** configured to use Minikube
   ```bash
   kubectl config use-context minikube
   ```

3. **Docker** (for building images)

## Quick Start

### Step 1: Configure Docker to use Minikube

```bash
eval $(minikube docker-env)
```

This ensures images are built inside Minikube's Docker daemon.

### Step 2: Build Docker Images

**Frontend:**
```bash
cd react-express-mongodb/frontend
docker build --target development -t todo-frontend:latest .
```

**Backend:**
```bash
cd ../backend
docker build --target development -t todo-backend:latest .
```

**Verify images:**
```bash
docker images | grep todo
```

### Step 3: Deploy to Kubernetes

Apply all manifests in order:

```bash
cd ../k8s

# 1. Create namespace
kubectl apply -f 00-todo-namespace.yaml

# 2. Create secrets (MongoDB credentials)
kubectl apply -f mongodb-secret.yaml

# 3. Create ConfigMaps
kubectl apply -f backend-configmap.yaml

# 4. Create MongoDB storage and deployment
kubectl apply -f mongodb-pvc.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f mongodb-service.yaml

# 5. Create backend
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml

# 6. Create frontend
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

**Or apply all at once:**
```bash
kubectl apply -f k8s/
```

### Step 4: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n todo-app

# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# backend-xxx                 1/1     Running   0          2m
# frontend-xxx                1/1     Running   0          2m
# mongodb-xxx                 1/1     Running   0          2m

# Check services
kubectl get svc -n todo-app

# Check logs
kubectl logs -n todo-app -l app=backend --tail=20
kubectl logs -n todo-app -l app=frontend --tail=20
```

### Step 5: Access the Application

**Get the frontend URL:**
```bash
minikube service frontend -n todo-app --url
 kubectl port-forward -n todo-app service/backend 3001:3001 # required for macOS with Minikube Docker driver

```

**Open in browser:**
```bash
# Example output: http://192.168.49.2:30123
# Copy and paste into your browser
```

## Configuration

### Environment Variables

**Backend (from ConfigMap):**
- `NODE_ENV`: "development"
- `PORT`: "3001"

**Backend (from Secret):**
- `MONGODB_URI`: "mongodb://admin:password123@mongo:27017/TodoApp?authSource=admin"

**MongoDB (from Secret):**
- `MONGO_INITDB_ROOT_USERNAME`: "admin"
- `MONGO_INITDB_ROOT_PASSWORD`: "password123"
- `MONGO_INITDB_DATABASE`: "TodoApp"

### Modifying Configuration

**Change MongoDB credentials:**
```bash
# Edit the secret
kubectl edit secret mongodb-secret -n todo-app

# Or update the file and reapply
vim k8s/mongodb-secret.yaml
kubectl apply -f k8s/mongodb-secret.yaml
kubectl rollout restart deployment backend mongodb -n todo-app
```

**Change backend port:**
```bash
# Edit ConfigMap
kubectl edit configmap backend-config -n todo-app

# Restart deployment
kubectl rollout restart deployment backend -n todo-app
```

## Kubernetes Resources

### Namespace: `todo-app`
All resources are deployed in this namespace for isolation.

### Secrets
- **mongodb-secret**: Stores MongoDB credentials and connection URI
  - ⚠️ **Security Note**: In production, use Sealed Secrets or external secret management (Vault, AWS Secrets Manager)

### ConfigMaps
- **backend-config**: Non-sensitive backend configuration
  - `NODE_ENV`, `PORT`

### PersistentVolumeClaim
- **mongodb-pvc**: 512Mi storage for MongoDB data
  - Access Mode: ReadWriteOnce
  - Persists data across pod restarts

### Deployments
- **frontend**: React application (1 replica)
- **backend**: Express API server (1 replica)
- **mongodb**: MongoDB database (1 replica)

### Services
- **frontend**: NodePort (external access)
- **backend**: ClusterIP (internal only)
- **mongo**: ClusterIP (internal only)

## Scaling

### Scale frontend:
```bash
kubectl scale deployment frontend --replicas=3 -n todo-app
```

### Scale backend:
```bash
kubectl scale deployment backend --replicas=3 -n todo-app
```

**Note**: MongoDB should remain at 1 replica unless configured as a replica set.

## Troubleshooting

### Pods not starting?
```bash
# Check pod status
kubectl get pods -n todo-app

# Describe pod for events
kubectl describe pod <pod-name> -n todo-app

# Check logs
kubectl logs <pod-name> -n todo-app
```