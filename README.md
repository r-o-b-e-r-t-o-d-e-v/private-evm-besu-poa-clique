# Private EVM | Hyperledger Besu | PoA (Clique)

---

## Overview

This project is aimed to launch a private EVM based blockchain by deploying
a few nodes using Docker technology.

The client nodes are handled by using Hyperledger Besu that runs a PoA
consensus protocol implemented with Clique.

---

## Structure

- Dockerfile:
There is a Dockerfile we can use to create a Docker image. It makes use of
the official Hyperledger Besu image and its task is to run a node with the
custom genesis block.

- genesis.json:
This file helps us customizing some of the characteristics the blockchain
and the consensus protocol will have.

---

## Running the node

### Creating the Docker image

First thing we have to do is creating the Docker file. For this we should
run the command:
```
docker build --no-cache -t <image_name> .
```

Example
```
docker build --no-cache -t private-evm-besu-poa-clique .
```

### Run a Docker container

Then, we can run a container using the previous image:
```
docker run -d -p 8545:8545 -p 8546:8546 --name <container_name> <image_name>
```
or we want to mount a directory to persist the blockchain after dropping the container:
```
docker run -d -p 8545:8545 -p 8546:8546 -v <path_to_directory_to_persist>:/besu/data --name <container_name> <image_name>
```

With that commands we are exposing the ports 8545 for HTTP and 8546 for WS.

Example:
```
docker run -d -p 8545:8545 -p 8546:8546 -v $(pwd)/.data:/besu/data --name private-evm-besu-poa-clique-container private-evm-besu-poa-clique
docker run -d -p 8545:8545 -p 8546:8546 --name private-evm-besu-poa-clique-container private-evm-besu-poa-clique
```

### Is it working?
To quickly check if the node is up and running here are some commands we use to
quickly check everything went fine:
```
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

```
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x8fa8f365E8B3B66E050F2e0c7221de96fc535D3A", "latest"],"id":1}'
```

## Data
The genesis.json already has some data related to the initial validator of the node.

  | Keys           | Values                                                              |
  |----------------|---------------------------------------------------------------------|
  | Public address | 0x8fa8f365E8B3B66E050F2e0c7221de96fc535D3A                          |
  | Private key    | $0x8c4027a5500f53b005949b1834b148cc3fad6bbf64e7981985afc9e0650b8ee0 |

This validator address can and should be changed for a personal one generated from
an external utility. Although for testing purposes it can still be relied on.

Initially the genesis.json is allocating 100 ETH in this account.
