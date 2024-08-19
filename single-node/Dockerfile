# Use an official Hyperledger Besu image as a base
FROM hyperledger/besu:24.7.1

# Set up the working directory
WORKDIR /besu

# Creating config folder
RUN mkdir config

# Copy the genesis file into the container
COPY genesis.json /besu/genesis.json

# Copy the besu.config.toml file into the container
COPY besu.config.toml /besu/config/besu.config.toml

# **NOTE:: The file with the private key MUST be called 'key'. Otherwise, it will throw an error saying the file content is not valid (This is not stated in the documentation as of 2024.Aug.18)
COPY .env/secret /besu/config/key

# Initialize the blockchain with a config file
CMD ["--config-file=/besu/config/besu.config.toml"]
