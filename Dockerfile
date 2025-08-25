# Stage 1: Build React Frontend
FROM node:20-alpine AS frontend-builder

# Set working directory for frontend
WORKDIR /app/frontend

# Copy frontend package files and install dependencies
COPY frontend/package.json ./
COPY frontend/package-lock.json ./
RUN npm install

# Copy the rest of the frontend source code
COPY frontend/ ./

# Build the frontend
RUN npm run build

# Stage 2: Python Backend for Cloud Run
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir \
    "langserve" \
    "langgraph>=0.2.6" \
    "langchain>=0.3.19" \
    "langchain-google-genai" \
    "langgraph-sdk>=0.1.57" \
    "langgraph-cli" \
    "langgraph-api" \
    "fastapi" \
    "google-genai"

# Copy backend source code
COPY backend/ /app/backend

# Copy built frontend from builder stage
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

# Add pip's binary directory to PATH
ENV PATH="/root/.local/bin:$PATH"

# Add application source to PYTHONPATH and set up LangGraph variables
ENV PYTHONPATH="/app/backend/src"
ENV LANGGRAPH_HTTP='{"app": "/app/backend/src/agent/app.py:app"}'
ENV LANGSERVE_GRAPHS='{"agent": "/app/backend/src/agent/graph.py:graph"}'
ENV LANGCHAIN_TRACING_V2="false"

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Start the application using langserve as a python module
# The host and port will be managed by Cloud Run's environment variables.
# langserve by default listens on port 8080, which is what Cloud Run expects.
CMD ["python", "-m", "langserve.cli", "up", "--host", "0.0.0.0", "--port", "8080"]
