#!/bin/sh

# Installing curl and bash
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
apk update
apk add --no-cache curl
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

echo ""

# input variables
ALL_ARGS="$@"

MAX_RETRIES=3
RETRY_SLEEP=3
INITIAL_DELAY=5

# Grabbing the 'delay' parameter
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
for arg in $ALL_ARGS; do
  if [ "${arg%%=*}" = "delay" ]; then
    INITIAL_DELAY="${arg#*=}"  # Extract the value after '='
  fi
done
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

echo "Applying an initial delay of $INITIAL_DELAY"
sleep $INITIAL_DELAY

# Grabbing the 'nodes' parameter
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
for arg in $ALL_ARGS; do
  case "$arg" in nodes=*)
    NODES_ARGS="${arg#nodes=}"
    ;;
  esac
done

# Convert the comma-separated nodes into an array
node_array=$(echo "$NODES_ARGS" | tr ',' ' ')
echo "Nodes to get the enodes from: $node_array"
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Defining some functions
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
obtain_enode_id() {
  url="$1"
  curl -s --max-time 5 -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' "$url" | grep -o '"enode":"[^"]*' | sed 's/"enode":"enode:\/\/\([^@]*\)@.*/\1/'
}

build_enode() {
  ENODE_ID="$1"
  IP_ADDRESS="$2"
  echo "enode://$ENODE_ID@$IP_ADDRESS:30303"
}
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# Iterate over each node
for node in $node_array; do
  echo "Processing node: $node"

  num_retries=0
  found_enode=false

  while [ $num_retries -le $MAX_RETRIES ] && [ "$found_enode" = "false" ]; do
    url="http://$node"
    enode_id=$(obtain_enode_id "$url")

    echo "enode_id: $enode_id"

    if [ -z "$enode_id" ] || [ "$enode_id" = "null" ]; then   # If no enode_id...
      if [ $num_retries -eq $MAX_RETRIES ]; then
        echo "Couldn't get enode for $url"
        echo ""
        exit 1
      else
        sleep $RETRY_SLEEP
        echo "retrying..."
      fi
    else  # If enode_id...
      ip_address=$(echo "$node" | cut -d ':' -f 1)   # Gets the host part of the bootnode (bootnode expected value pattern is <host>:<port>)


      found_enode=true  # Skip the while
      enode_ids="$enode_ids $(build_enode "$enode_id" "$ip_address")"   # Adds the enode to a list
    fi

    num_retries=$(($num_retries + 1))
  done
done
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

echo "ENODE IDS::$enode_ids"

# Generates static-nodes.json
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"

[ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"

JSON_FILE_PATH="$OUTPUT_DIR/static-nodes.json"

echo "[" > "$JSON_FILE_PATH"

if [ -n "$enode_ids" ]; then

  # Split the enode_ids by space and iterate over each one
  for enode_id in $enode_ids; do
    echo "  \"$enode_id\"," >> "$JSON_FILE_PATH"
  done

  # Remove the last comma
  sed -i '$ s/,$//' "$JSON_FILE_PATH"
fi

echo "]" >> "$JSON_FILE_PATH"

echo "Generated static-nodes.json at: $JSON_FILE_PATH"
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

echo ""
exit 0
