import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv("FRONTEND_URL")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
AI_MODEL_URL = os.getenv("AI_MODEL_URL")
AI_MODEL_NAME = os.getenv("AI_MODEL_NAME")


class ChatRequest(BaseModel):
    prompt: str


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.post("/chat")
async def chat(request: ChatRequest):
    async with httpx.AsyncClient() as client:
        api_endpoint = f"{AI_MODEL_URL}/api/chat"

        response = await client.post(
            api_endpoint,
            json={
                "model": os.getenv("AI_MODEL_NAME"),
                "messages": [{"role": "user", "content": request.prompt}],
                "stream": False
            },
            timeout=10.0
        )
        response.raise_for_status()
        data = response.json()
        content = data["message"]["content"]
        return {"response": content}
