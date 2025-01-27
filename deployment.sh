#!/bin/bash

# Navigate to the Aieth folder
cd /home/azureuser/github/Aieth

# Check and remove the existing frontend image if it exists, then rebuild it
if docker images frontend-app | grep -q "frontend-app"; then
  echo "Stopping and removing frontend container..."
  docker container stop frontend-container || true
  docker container rm frontend-container || true

  echo "Removing existing frontend image..."
  docker system prune
  docker image rm frontend-app || true
else
  echo "Frontend image not found."
fi

echo "Building frontend image..."
cd frontend
docker build -t frontend-app .
cd ..

# Check and remove the existing backend image if it exists, then rebuild it
if docker images backend-app | grep -q "backend-app"; then
  echo "Stopping and removing backend container..."
  docker container stop backend-container || true
  docker container rm backend-container || true

  echo "Removing existing backend image..."
  docker image rm backend-app || true
else
  echo "Backend image not found."
fi

echo "Building backend image..."
cd backend
docker build -t backend-app .
cd ..

# Check if the Docker network 'app-network' exists, create it if not
if ! docker network ls | grep -q "app-network"; then
  echo "Creating 'app-network' network..."
  docker network create app-network
else
  echo "'app-network' already exists."
fi

# Run the frontend container
echo "Running the frontend container..."
docker run -d \
  --name frontend-container \
  --network app-network \
  -p 8080:80 \
  -e BACKEND_URL=http://backend-container:8000 \
  frontend-app

# Run the backend container
echo "Running the backend container..."
docker run -d \
  --name backend-container \
  --network app-network \
  -p 8000:8000 \
  backend-app

# Verify that the containers are running
docker ps
