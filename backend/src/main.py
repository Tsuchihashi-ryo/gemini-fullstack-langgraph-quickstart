from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from langserve import add_routes
from src.agent.graph import graph
from src.agent.app import create_frontend_router

# Create the main FastAPI app
app = FastAPI(
    title="LangGraph Research Agent",
    version="1.0",
    description="An agent that researches a topic and generates a report.",
)

# Add the LangServe routes for the graph
add_routes(
    app,
    graph,
    path="/agent",
    enable_feedback_endpoint=True,
    enable_public_trace_link_endpoint=True,
    playground_type="chat",
)

# Mount the frontend application
# This assumes the frontend has been built and is located in ../frontend/dist
app.mount(
    "/",
    create_frontend_router(build_dir="../../frontend/dist"),
    name="frontend",
)
