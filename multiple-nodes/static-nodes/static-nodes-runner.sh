#!/bin/sh

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define the path to the docker-compose.yml file
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Quick checking to make sure Docker is running
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
if ! docker info > /dev/null 2>&1; then
    echo "Docker daemon is not running. Please start Docker and try again."
    exit 1
fi
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Step 1: Bring down the Docker Compose services in case they are running
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
echo "Bringing down the Docker Compose services..."
docker-compose -f "$COMPOSE_FILE" down
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# Step 2: Copying the generated json file into every node '.data' in nodes folder
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
SOURCE_FILE_NAME="static-nodes.json"
SOURCE_FILE_DIR="$SCRIPT_DIR/common/config/generated"
SOURCE_FILE="$SOURCE_FILE_DIR/$SOURCE_FILE_NAME"

NODES_DIR="$SCRIPT_DIR/nodes"
DATA_FOLDER_NAME=".data"

# Check if the source file exists
if [ ! -f "$SOURCE_FILE" ]; then
  echo "Source file $SOURCE_FILE does not exist."
  exit 1
fi

# Loop over each subdirectory in the nodes directory
for node_dir in "$NODES_DIR"/*; do
  if [ -d "$node_dir" ]; then
    mkdir -p "$node_dir/$DATA_FOLDER_NAME"
    DESTINATION=$node_dir/$DATA_FOLDER_NAME/$SOURCE_FILE_NAME

    cp "$SOURCE_FILE" "$DESTINATION"
  fi
done
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# Step 3: Run the docker-compose up command
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
echo "Starting the Docker Compose services..."
docker-compose -f "$COMPOSE_FILE" up
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
