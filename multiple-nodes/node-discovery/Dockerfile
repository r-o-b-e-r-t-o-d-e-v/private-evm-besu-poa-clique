# Use an official Hyperledger Besu image as a base
FROM hyperledger/besu:24.7.1

USER root

# Install curl
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

USER besu
