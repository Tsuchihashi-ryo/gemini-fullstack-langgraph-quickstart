# Use an official Python runtime as a parent image
FROM python:3.11-slim

WORKDIR /app

COPY . .

# Set the working directory in the container
WORKDIR /app/backend

# Install any needed packages specified in requirements.txt
RUN pip install .



# Stage 1: Build React Frontend
FROM node:20-alpine AS frontend-builder

# Set working directory for frontend
WORKDIR /app/frontend
RUN npm install


WORKDIR /app

# Define environment variables (Cloud Runは自動でPORTを注入しますが、記述していても問題ありません)
# ENV GOOGLE_CLOUD_PROJECT "rd-rag" # Cloud Runの環境変数として設定する方が一般的
# ENV GOOGLE_CLOUD_REGION "us-central1" # 同上
ENV PORT 5173
EXPOSE 5173

RUN make dev
