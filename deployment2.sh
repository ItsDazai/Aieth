#!/bin/bash

set -e  # Exit immediately if any command fails

echo "################################################################################################"
echo "Checking for Docker installation..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Docker not found. Installing Docker..."

  # Update package index and install Docker
  sudo apt update
  sudo apt install -y docker.io

  # Enable and start Docker service
  sudo systemctl enable --now docker
  sudo systemctl start docker

  # Add current user to the Docker group
  sudo usermod -aG docker "$USER"

  # Apply group membership without requiring logout/restart
  exec sg docker newgrp `id -gn`

  echo "Docker installed and configured successfully."
else
  echo "Docker is already installed."
fi

echo "################################################################################################"
echo "Setting up Aieth application..."

# Automatically fetch the current username
USERNAME=$(whoami)

# Get the current working directory
CURRENT_DIR=$(pwd)

# Verify the Aieth directory by checking for "backend" and "frontend" inside it
if [ ! -d "$CURRENT_DIR/backend" ] || [ ! -d "$CURRENT_DIR/frontend" ]; then
  echo "Aieth folder not found in the current directory."
  echo "Searching for Aieth folder in the home directory..."

  # Search for Aieth in the home directory
  AIETH_PATH=$(find /home/$USERNAME -type d -name "Aieth" 2>/dev/null)

  if [ -z "$AIETH_PATH" ]; then
    echo "Aieth folder not found in the home directory. Exiting..."
    exit 1
  fi

  echo "Aieth folder found at: $AIETH_PATH"
else
  AIETH_PATH=$CURRENT_DIR
  echo "Aieth folder found in the current directory: $AIETH_PATH"
fi

# Navigate to the Aieth folder
cd "$AIETH_PATH"

# Fetch the public IP of the VM
VM_IP=$(curl -s https://ifconfig.me)

# Replace localhost with the VM public IP in App.jsx
echo "Updating frontend to use VM IP address..."
sed -i "s|http://localhost:8000|http://$VM_IP:8000|g" frontend/src/App.jsx

# Remove existing frontend image if it exists
if docker images frontend-app | grep -q "frontend-app"; then
  echo "Stopping and removing frontend container..."
  docker container stop frontend-container || true
  docker container rm frontend-container || true

  echo "Removing existing frontend image..."
  docker system prune -y
  docker image rm frontend-app || true
else
  echo "No existing frontend image found."
fi

# Build the frontend image
echo "Building frontend image..."
cd frontend
docker build -t frontend-app .
cd ..

# Remove existing backend image if it exists
if docker images backend-app | grep -q "backend-app"; then
  echo "Stopping and removing backend container..."
  docker container stop backend-container || true
  docker container rm backend-container || true

  echo "Removing existing backend image..."
  docker image rm backend-app || true
else
  echo "No existing backend image found."
fi

# Build the backend image
echo "Building backend image..."
cd backend
docker build -t backend-app .
cd ..

# Create Docker network if it doesn't exist
if ! docker network ls | grep -q "app-network"; then
  echo "Creating 'app-network'..."
  docker network create app-network
else
  echo "'app-network' already exists."
fi

# Run the frontend container
echo "Running frontend container..."
docker run -d \
  --name frontend-container \
  --network app-network \
  -p 8080:80 \
  -e BACKEND_URL=http://$VM_IP:8000 \
  frontend-app

# Run the backend container
echo "Running backend container..."
docker run -d \
  --name backend-container \
  --network app-network \
  -p 8000:8000 \
  backend-app

# Display running containers
echo "################################################################################################"
echo "Deployment complete. Running containers:"
docker ps
