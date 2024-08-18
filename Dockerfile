# Use an official Hyperledger Besu image as a base
FROM hyperledger/besu:24.7.1

# Set up the working directory
WORKDIR /besu

# Creating config folder
RUN mkdir config

# Copy the genesis file into the container
COPY genesis.json /besu/genesis.json

# **NOTE:: The file with the private key MUST be called 'key'. Otherwise, it will throw an error saying the file content is not valid (This is not stated in the documentation as of 2024.Aug.18)
COPY .env/secret /besu/config/key

# Initialize the blockchain with the genesis block
CMD ["--genesis-file=/besu/genesis.json", "--data-path=/besu/data", "--network-id=880", "--node-private-key-file=/besu/config/key", "--rpc-http-enabled", "--rpc-http-api=ETH,NET,CLIQUE", "--rpc-http-cors-origins=all", "--rpc-ws-enabled", "--host-allowlist=*", "--sync-mode=FULL"]
