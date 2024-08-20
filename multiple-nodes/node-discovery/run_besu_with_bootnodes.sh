#!/bin/bash

# Handles an initial delay based on a delay variable (Default value is 3)
declare INITIAL_DELAY=3
for arg in "$@"; do
    # Check if the argument starts with "delay="
    if [[ $arg == delay=* ]]; then
        # Extract the value after the equals sign
        INITIAL_DELAY="${arg#delay=}"
    fi
done
echo "Initial delay of $INITIAL_DELAY"
sleep $INITIAL_DELAY


declare -r RETRY_SLEEP=3
declare -r MAX_RETRIES=3
declare -r SKIP_MISSING_BOOTNODES=true

# Filter to keep only Besu arguments
function filter_besu_args() {
  for arg in "$1"; do
      if [[ $arg == --* ]]; then
          filtered_args+=("$arg")
      fi
  done
  echo $filtered_args
}

function print_warning_skipped_bootnode() {
  URL=$1
  echo ""
  echo "*** *** *** *** *** *** *** ***"
  echo "          WARNING!"
  echo "--- --- --- --- --- --- --- ---"
  echo "Couldn't get enode url for $URL"
  echo "This bootnode will be skipped"
  echo "*** *** *** *** *** *** *** ***"
  echo ""
}

echo ""

# Process the bootnodes argument into an array
for arg in "$@"; do
  if [[ $arg == bootnodes=* ]]; then
    bootnodes=${arg#bootnodes=}
    IFS=',' read -r -a bootnode_array <<< "$bootnodes"
  fi
done


# Prints the bootnodes
echo "Solving bootnodes:"
if [ ${#bootnode_array[@]} -eq 0 ]; then
  echo "No bootnodes were defined."
else
  successful_enodes=()
  for bootnode in "${bootnode_array[@]}"; do

    echo "Attempting to get enode for $bootnode"

    declare num_retries=0
    declare found_enode=false
    declare ENODE_ID=""
    declare URL=""
    while [ $num_retries -le $MAX_RETRIES ] && [ $found_enode = "false" ]; do
      URL="http://$bootnode"
      ENODE_ID=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' "$URL" | grep -o '"enode":"[^"]*' | sed 's/"enode":"enode:\/\/\([^@]*\)@.*/\1/')

      echo "ENODE_ID: $ENODE_ID"

      if [ -z "$ENODE_ID" ] || [ -z "${ENODE_ID+x}" ] || [ "$ENODE_ID" = "null" ]; then
        if [ $num_retries -eq $MAX_RETRIES ]; then
          if [ $SKIP_MISSING_BOOTNODES = "true" ]; then
            print_warning_skipped_bootnode $URL
          else
            echo "Couldn't get enode url for $URL"
            exit 1
          fi
        else
          sleep $RETRY_SLEEP
          echo "retrying..."
        fi
      else
        found_enode=true
        ip_address=$(echo "$bootnode" | cut -d ':' -f 1)
        successful_enodes+=("enode://$ENODE_ID@$ip_address:30303")

      fi

      ((num_retries++))
    done

  done

  if [ ${#successful_enodes[@]} -eq 0 ] && [ $SKIP_MISSING_BOOTNODES != "true" ]; then
    echo "No enodes were found..."
    exit 1
  else
    # Filter all args to keep only Besu specific ones
    BESU_ARGUMENTS=$(filter_besu_args $@)

    # Converts successful_enodes array into string with comma separated values
    IFS=',' enodes="${successful_enodes[*]}"

    echo "Starting Besu node..."
    echo "With args:: $BESU_ARGUMENTS"
    echo "With enodes:: $enodes"

    # Run Besu node
    /opt/besu/bin/besu --bootnodes="$enodes" "$BESU_ARGUMENTS"
    exit 0
  fi

fi
