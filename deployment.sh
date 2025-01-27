#!/bin/bash

# Automatically fetch the VM username using whoami
USERNAME=$(whoami)

# Get the current directory where the script is executed
CURRENT_DIR=$(pwd)

# Verify the Aieth directory by checking if we are inside it
if [ ! -d "$CURRENT_DIR" ] || [ ! -d "$CURRENT_DIR/backend" ] || [ ! -d "$CURRENT_DIR/frontend" ]; then
  echo "Aieth folder not found in the current directory."
  echo "Searching for Aieth folder in the home directory..."
  
  # Search for the Aieth folder in the user's home directory if not found in the current directory
  AIETH_PATH=$(find /home/$USERNAME -type d -name "Aieth" 2>/dev/null)

  if [ -z "$AIETH_PATH" ]; then
    echo "Aieth folder not found in home directory."
    exit 1
  fi
  
  echo "Aieth folder found at: $AIETH_PATH"
else
  AIETH_PATH=$CURRENT_DIR
  echo "Aieth folder found in the current directory: $AIETH_PATH"
fi

# Navigate to the Aieth folder
cd "$AIETH_PATH"

# Fetch the public IP address of your VM
VM_IP=$(curl -s https://ifconfig.me)

# Replace localhost with the VM public IP in the App.jsx file before building the image
echo "Updating App.jsx with VM IP address..."
sed -i "s|http://localhost:8000|http://$VM_IP:8000|g" frontend/src/App.jsx

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
  -e BACKEND_URL=http://$VM_IP:8000 \
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
