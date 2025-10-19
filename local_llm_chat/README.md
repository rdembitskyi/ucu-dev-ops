# Local LLM Chat Application

A containerized chat application that runs a local language model. 
The application consists of a React frontend and FastAPI backend, deployable with either Docker Compose or Kubernetes.

## Architecture Overview

```
React Frontend (:5173) → FastAPI Backend (:8000) → Local LLM
```

### Components

1. **chat-frontend**: React application built with Vite and served via Nginx
   - Port: 5173
   - Sends user prompts to the backend API

2. **chat-backend**: FastAPI backend service
   - Port: 8000
   - Proxies requests to Ollama
   - Exposes `/chat` endpoint for chat completions

3. **Ollama**: Local LLM inference engine (runs separately on host)
   - Port: 11434
   - Supports various models (gemma3:1b, llama2, etc.)
   - OpenAI-compatible API endpoint

## Deployment Options

### Option 1: Docker Compose (Simpler)

#### Prerequisites
- Docker
- Docker Compose
- Ollama installed locally

#### Running with Docker Compose

1. Install and start Ollama:
```bash
# Install Ollama (macOS)
brew install ollama

# Start Ollama service
ollama serve

# Pull a model (in another terminal)
ollama pull gemma3:1b
```

2. Start the application:
```bash
cd local_llm_chat
docker-compose up --build
```

3. Access the application:
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs

4. Stop the application:
```bash
docker-compose down
```

---

### Option 2: Kubernetes

#### Prerequisites
- Docker
- Minikube
- kubectl
- Ollama installed locally

#### Running with Kubernetes

1. Install and start Ollama:
```bash
# Install Ollama (macOS)
brew install ollama

# Start Ollama service
ollama serve

# Pull a model (in another terminal)
ollama pull gemma3:1b
# Or use any other model: ollama pull llama2, ollama pull mistral, etc.
```

2. Start Minikube:
```bash
minikube start
```

3. Build Docker images in Minikube's environment:
```bash
# Point Docker CLI to Minikube's Docker daemon
eval $(minikube docker-env)

# Build backend image
docker build -t chat-backend:latest -f Dockerfile.app .

# Build frontend image
docker build -t chat-frontend:latest -f Dockerfile.frontend .

# Verify images are built
docker images | grep chat
```

4. Deploy to Kubernetes:
```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Wait for pods to be ready
kubectl get pods -n llm-chat -w
```

5. Set up port forwarding (required for macOS with Minikube Docker driver):
```bash
# In terminal 1 - Backend
kubectl port-forward -n llm-chat svc/chat-backend 8000:8000

# In terminal 2 - Frontend
kubectl port-forward -n llm-chat svc/chat-frontend 5173:5173
```

**Note on Ingress:** Ingress is configured in `k8s/ingress.yaml` but not used by default due to Minikube networking limitations on macOS with Docker driver. On cloud Kubernetes (GKE, EKS, AKS), Ingress works out-of-the-box with real Load Balancers.

6. Access the application:
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:8000

7. Stop the application:
```bash
# Stop port-forwards (Ctrl+C in both terminals)

# Delete Kubernetes resources
kubectl delete -f k8s/

# Stop Minikube (optional)
minikube stop
```

#### Kubernetes Architecture

The application deploys two pods:
- **chat-backend** pod (FastAPI)
- **chat-frontend** pod (Nginx serving React app)

Services expose these pods:
- **chat-backend** service (NodePort 30800)
- **chat-frontend** service (NodePort 30173)

Configuration is managed via:
- **ConfigMap** (`backend-configmap.yaml`) - stores environment variables
- **Namespace** (`llm-chat`) - isolates resources

## Project Structure

```
local_llm_chat/
├── docker-compose.yml          # Orchestrates all services
├── Dockerfile.app              # Backend FastAPI container
├── Dockerfile.frontend         # Frontend React container
├── api_app/
│   ├── main.py                # FastAPI application entry point
│   ├── requirements.txt       # Python dependencies
│   └── __init__.py
└── chat_frontend/
    ├── package.json           # Node.js dependencies
    ├── nginx.conf             # Nginx configuration for production
    └── src/                   # React source code
```

## API Endpoints

### POST /chat
Send a chat message to the LLM.

**Request:**
```json
{
  "prompt": "Your message here"
}
```

**Response:**
```json
{
  "response": "LLM's response here"
}
```


## Network Architecture

All services communicate through a dedicated Docker bridge network (`llm-chat-network`). The backend automatically receives model endpoint configuration via environment variables managed by Docker Compose.
