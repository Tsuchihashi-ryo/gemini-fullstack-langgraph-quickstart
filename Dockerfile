# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Install necessary tools for installing Node.js and running make
RUN apt-get update && apt-get install -y curl make

# Install Node.js and npm (using nodesource repository)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

# Set the working directory in the container
WORKDIR /app

# Copy the entire project to the working directory
COPY . .

# Install Python dependencies from the backend's pyproject.toml
RUN pip install -e ./backend

# Install frontend dependencies from the frontend's package.json
RUN npm install --prefix frontend

# Expose ports for frontend (5173) and backend (8000) development servers
EXPOSE 5173 8000

# Set the default command to run the development server for both services
CMD ["make", "dev"]
