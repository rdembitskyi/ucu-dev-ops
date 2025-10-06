FROM python:3.11-slim

# Install uv
RUN pip install --no-cache-dir uv

# Create non-root user
RUN useradd -m -s /bin/bash appuser

# Set working directory
WORKDIR /app

# Copy requirements file
COPY api_app/requirements.txt ./

# Install dependencies system-wide using uv
RUN uv pip install --system --no-cache -r requirements.txt

# Copy application files and set ownership
COPY --chown=appuser:appuser api_app/ ./

# Switch to non-root user
USER appuser

# Expose port 8000
EXPOSE 8000

# Start FastAPI app with uvicorn
CMD ["fastapi", "dev", "main.py", "--host", "0.0.0.0", "--port", "8000"]
