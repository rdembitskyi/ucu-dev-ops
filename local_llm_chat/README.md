# Local LLM Chat Application

A containerized chat application that runs a local language model using Docker Compose(via Docker Model Runner). The application consists of a React frontend, FastAPI backend, and a local LLM model runner.

## Architecture Overview

```
React Frontend (:5173) → FastAPI Backend (:8000) → Model Runner (SmolLM2)
```

### Components

1. **chat-frontend**: React application built with Vite and served via Nginx
   - Port: 5173
   - Sends user prompts to the backend API

2. **chat-app**: FastAPI backend service
   - Proxies requests to the model runner
   - Exposes `/chat` endpoint for chat completions

3. **Model Runner**: Local LLM inference engine
   - Model: SmolLM2 360M (4-bit quantized)
   - Context size: 4096 tokens
   - OpenAI-compatible API endpoint
   - Managed automatically via Docker Compose models feature

## Quick Start

### Prerequisites

- Docker
- Docker Compose with model support

### Running the Application

1. Clone the repository and navigate to the project directory:
```bash
cd local_llm_chat
```

2. Start all services with a single command:
```bash
docker-compose up --build
```

This command will:
- Build the FastAPI backend container
- Build the React frontend container
- Pull and configure the SmolLM2 model
- Start all services and wire them together

3. Access the application:
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs

### Stopping the Application

```bash
docker-compose down
```

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
