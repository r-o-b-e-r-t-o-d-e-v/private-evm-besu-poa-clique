#!/bin/bash

# input variables
declare -r ALL_ARGS=("$@")

# const variables
declare INITIAL_DELAY=3
declare -r MAX_RETRIES=3
declare -r RETRY_SLEEP=3
declare -r SKIP_MISSING_BOOTNODES=true

echo ""

# Initial delay
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Handles an initial delay based on a delay variable (Default value is 3)
#   | Check if the argument starts with "delay="
#   | Extract the value after the equals sign
for arg in "${ALL_ARGS[@]}"; do
    if [[ $arg == delay=* ]]; then
        INITIAL_DELAY="${arg#delay=}"
    fi
done
echo "Initial delay of $INITIAL_DELAY seconds"
sleep $INITIAL_DELAY
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Filter Besu args
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Filter all args to keep only Besu specific ones
#   | Check if the argument starts with "--"
for arg in "${ALL_ARGS[@]}"; do
  if [[ $arg == --* ]]; then
    BESU_ARGUMENTS+=("$arg")
  fi
done
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# Process bootnodes arg
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Process the bootnodes argument into an array
for arg in "${ALL_ARGS[@]}"; do
  if [[ $arg == bootnodes=* ]]; then
    BOOTNODES_ARGS=${arg#bootnodes=}
    IFS=',' read -r -a BOOTNODES_ARGS_ARRAY <<< "$BOOTNODES_ARGS"
  fi
done
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Defining some functions
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
function obtain_enode_id() {
  url=$1
  echo $(curl -s -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' "$url" | grep -o '"enode":"[^"]*' | sed 's/"enode":"enode:\/\/\([^@]*\)@.*/\1/')
}

function build_enode() {
  ENODE_ID=$1
  IP_ADDRESS=$2
  echo "enode://$ENODE_ID@$IP_ADDRESS:30303"
}

function run_besu() {
  declare -r BESU_ARGUMENTS=$1
  declare -r ENODES=$2

  echo "Starting Besu node..."
  echo "With args:: $BESU_ARGUMENTS"
  echo "With bootnodes:: $ENODES"

  /opt/besu/bin/besu --bootnodes="$ENODES" "$BESU_ARGUMENTS"
}

function print_warning_skipped_bootnode() {
  url=$1
  echo ""
  echo "*** *** *** *** *** *** *** ***"
  echo "          WARNING!"
  echo "--- --- --- --- --- --- --- ---"
  echo "Couldn't get enode for $url"
  echo "This bootnode will be skipped"
  echo "*** *** *** *** *** *** *** ***"
  echo ""
}
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Finish if no bootnodes
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
echo "Solving bootnodes:"
if [ ${#BOOTNODES_ARGS_ARRAY[@]} -eq 0 ]; then
  echo "No bootnodes were defined."

  if [ $SKIP_MISSING_BOOTNODES != "true" ]; then
    echo "Defining bootnodes is required."
    echo ""
    exit 1
  fi

  run_besu "$BESU_ARGUMENTS"
  echo ""
  exit 0
fi
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Process bootnodes
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
declare successful_enodes=()

for bootnode in "${BOOTNODES_ARGS_ARRAY[@]}"; do
  echo "Attempting to get enode for $bootnode"

  declare num_retries=0
  declare found_enode=false

  while [ $num_retries -le $MAX_RETRIES ] && [ $found_enode = "false" ]; do
    url="http://$bootnode"
    enode_id=$(obtain_enode_id $url)

    echo "enode_id: $enode_id"

    if [ -z "$enode_id" ] || [ -z "${enode_id+x}" ] || [ "$enode_id" = "null" ]; then   # If no enode_id...
      if [ $num_retries -eq $MAX_RETRIES ]; then
        if [ $SKIP_MISSING_BOOTNODES = "true" ]; then
          print_warning_skipped_bootnode $url
        else
          echo "Couldn't get enode for $url"
          echo ""
          exit 1
        fi
      else
        sleep $RETRY_SLEEP
        echo "retrying..."
      fi
    else  # If enode_id...
      ip_address=$(echo "$bootnode" | cut -d ':' -f 1)   # Gets the host part of the bootnode (bootnode expected value pattern is <host>:<port>)

      found_enode=true  # Skip the while
      successful_enodes+=($(build_enode $enode_id $ip_address))   # Adds the enode to a enodes list
    fi

    ((num_retries++))
  done
done
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---


# Process enodes
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
if [ ${#successful_enodes[@]} -eq 0 ]; then
  echo "No enodes were found."
  if [ $SKIP_MISSING_BOOTNODES != "true" ]; then
    echo ""
    exit 1
  fi
  echo "Skipping all bootnodes..."
else
  # Converts successful_enodes array into string with comma separated values
  IFS=',' enodes="${successful_enodes[*]}"

  # Run Besu node
  run_besu "$BESU_ARGUMENTS" "$enodes"
fi
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

echo ""
exit 0
