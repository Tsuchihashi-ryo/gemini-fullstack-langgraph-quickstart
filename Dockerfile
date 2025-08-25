# Stage 1: Build React Frontend
FROM node:20-alpine AS frontend-builder

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

# Install uv for fast package installation
RUN pip install uv

# Copy frontend build from the first stage
# The backend expects the frontend to be in ../frontend/dist relative to app.py
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

# Copy backend code
COPY backend/ /app/backend

# Install Python dependencies using uv
# We install langgraph-cli[inmem] to use the in-memory backend,
# suitable for stateless environments like Cloud Run.
# We also install the backend package in editable mode.
RUN uv pip install --system "langgraph-cli[inmem]" && \
    uv pip install --system -e /app/backend

# Cloud Run provides the PORT environment variable, which will be used by langgraph.
# We expose 8080 as a default.
EXPOSE 8080

# Set the entrypoint to run the application using the langgraph CLI.
# --host 0.0.0.0 makes it accessible from outside the container.
# --port $PORT is not explicitly needed as langgraph up reads the PORT env var by default.
# The app is defined in backend/src/agent/app.py and the graph in backend/src/agent/graph.py
# The langgraph cli will discover these from the pyproject.toml config.
ENV LANGGRAPH_HTTP='{"app": "agent.app:app"}'
ENV LANGSERVE_GRAPHS='{"agent": "agent.graph:graph"}'
ENV PYTHONUNBUFFERED=1

# We need to set the PYTHONPATH to include the src directory
ENV PYTHONPATH="/app/backend/src:${PYTHONPATH}"

CMD ["langgraph", "up", "--port", "8080"]
