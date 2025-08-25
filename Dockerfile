# Stage 1: Build React Frontend
FROM node:20-alpine AS frontend-builder

WORKDIR /app/frontend

COPY frontend/package.json ./
COPY frontend/package-lock.json ./
RUN npm install

COPY frontend/ ./
RUN npm run build

# Stage 2: Python Backend for Cloud Run
FROM python:3.11-slim

WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir \
    "uvicorn" \
    "langserve" \
    "sse-starlette" \
    "langgraph>=0.2.6" \
    "langchain>=0.3.19" \
    "langchain-google-genai" \
    "langgraph-sdk>=0.1.57" \
    "fastapi" \
    "google-genai"

# Copy backend source code
COPY backend/ /app/backend

# Copy built frontend from builder stage
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

# Set the python path to include the backend's 'src' directory
ENV PYTHONPATH="/app/backend/src"

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Start the application using uvicorn, pointing to main.py
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
