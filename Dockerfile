# Stage 1: Build React Frontend
FROM node:20-alpine AS frontend-builder

# Set working directory for frontend
WORKDIR /app/frontend

# Copy package.json and package-lock.json to leverage Docker cache
COPY frontend/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the frontend source code
COPY frontend/ ./

# Build the frontend for production
RUN npm run build

# Stage 2: Final Python Application for Production
FROM langchain/langgraph-api:3.11

# The backend app looks for the frontend in `backend/frontend/dist` relative
# to its own path. The project root is copied to /deps/backend, so the
# final path for the frontend assets must be /deps/backend/backend/frontend/dist
RUN mkdir -p /deps/backend/backend/frontend

# Copy the built frontend from the builder stage to the correct location
COPY --from=frontend-builder /app/frontend/dist /deps/backend/backend/frontend/dist

# Now, follow the steps from the langgraph-generated Dockerfile
# This adds the entire project context into /deps/backend
ADD . /deps/backend

# Install the python dependencies from backend/pyproject.toml
# The path to the backend project inside the container is /deps/backend/backend
RUN PYTHONDONTWRITEBYTECODE=1 uv pip install --system --no-cache-dir -c /api/constraints.txt -e /deps/backend/backend

# Set environment variables to point to the correct app and graph
# The langgraph-api base image will use these to serve the application
ENV LANGGRAPH_HTTP='{"app": "/deps/backend/src/agent/app.py:app"}'
ENV LANGSERVE_GRAPHS='{"agent": "/deps/backend/src/agent/graph.py:graph"}'

# -- Ensure user deps didn't inadvertently overwrite langgraph-api
RUN mkdir -p /api/langgraph_api /api/langgraph_runtime /api/langgraph_license && touch /api/langgraph_api/__init__.py /api/langgraph_runtime/__init__.py /api/langgraph_license/__init__.py
RUN PYTHONDONTWRITEBYTECODE=1 uv pip install --system --no-cache-dir --no-deps -e /api
# -- End of ensuring user deps didn't inadvertently overwrite langgraph-api --

# -- Removing build deps from the final image --
RUN pip uninstall -y pip setuptools wheel || true
RUN rm -rf /usr/local/lib/python*/site-packages/pip* /usr/local/lib/python*/site-packages/setuptools* /usr/local/lib/python*/site-packages/wheel* && find /usr/local/bin -name "pip*" -delete || true
RUN rm -rf /usr/lib/python*/site-packages/pip* /usr/lib/python*/site-packages/setuptools* /usr/lib/python*/site-packages/wheel* && find /usr/bin -name "pip*" -delete || true

# Set the final working directory
WORKDIR /deps/backend/backend
