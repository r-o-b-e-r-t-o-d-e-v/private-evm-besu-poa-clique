#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define the path to your docker-compose.yml file
COMPOSE_FILE="$SCRIPT_DIR/static-nodes-json-generator/docker-compose.yml"

# Step 1: Bring down the Docker Compose services in case they are running
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
echo "Bringing down the Docker Compose services..."
docker-compose -f "$COMPOSE_FILE" down
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Step 2: Run the docker-compose up command in detached mode
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
echo "Starting the Docker Compose services..."
docker-compose -f "$COMPOSE_FILE" up -d
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Step 3: Wait for the enodes-collector service to finish
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
echo "Waiting for the enodes-collector service to finish..."

while [ "$(docker inspect -f '{{.State.Status}}' enodes-collector 2>/dev/null)" != "exited" ]; do
    sleep 1
done
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Step 4: Copying the generated json file to the common folder
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
OUTPUT_DIR="$SCRIPT_DIR/static-nodes-json-generator/.output"
TARGET_DIR="$SCRIPT_DIR/common/config/generated"
JSON_FILENAME="static-nodes.json"

mkdir -p "$TARGET_DIR"
cp "$OUTPUT_DIR/$JSON_FILENAME" "$TARGET_DIR/$JSON_FILENAME"

echo "Generated $JSON_FILENAME at $TARGET_DIR/$JSON_FILENAME"

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Step 5: Bring down the Docker Compose services
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
echo "Bringing down the Docker Compose services..."
docker-compose -f "$COMPOSE_FILE" down
echo "All services have been shut down."
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
