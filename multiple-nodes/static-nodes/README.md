# Multiple Nodes: Static Nodes Example

---

# Table of contents
- [Overview](#overview)
- [Workflow](#workflow)
- [Structure](#structure)
  - [Nodes folders](#nodes-folders)
  - [Common folder](#common-folder)
  - [Static nodes JSON generator folder](#static-nodes-json-generator-folder)
    - [docker-compose](#docker-compose)
    - [static-nodes-generator-script](#static-nodes-generator-script)
  - [static-nodes-generator-orchestrator-script](#static-nodes-generator-orchestrator-script)
  - [docker-compose](#docker-compose-1)
  - [static-nodes-runner-script](#static-nodes-runner-script)
- [Static nodes JSON file generation](#static-nodes-json-file-generation)
- [Running the blockchain](#running-the-blockchain)
- [Initial state of the chain](#initial-state-of-the-chain)
  - [Validators](#validators)
  - [Peering](#peering)

---

## Overview

In this example you will find a blockchain of up to 5 nodes. The goal here is to
show how they can peer up by using only static-nodes and no p2p discovering.

In order to run this example you should already have Docker installed.

---

## Workflow

This is a two-step process since to use static nodes you need to previously know
the enode of every node in the chain that you want to connect (as stated in the 
official Besu documentation, is recommended to use the same static-nodes.json
file for each node).

### Step 1

In the step 1 we are running the blockchain nodes with a minimal setup so that
Besu generates their enodes. Once the nodes are all up and running, there is a
script that will collect the enodes and generating the required static-nodes.json
file.

### Step 2

In the step 2 we are doing the actual blockchain setup, once the static-nodes.json
file is ready to be used, the nodes can be run and will peer up with the other
nodes in the file.

---

## Structure

The file structure is as follows:

### Nodes folders

There are plain folders that will hold data of each specific node. However,
these folders are ignored by git so If you cloned the repository in local
you won't see them directly. Let's dig in:

- .data: The data folder is a bridge between the docker container and the
  project. It will hold the data related to the blockchain. There is no need
  to manually create it, it will be automatically handled by Docker volumes.

- .env/key: This is a file that contains the private key of the node. With
  this file we have two options. You can manually generate your desired
  private key with any tool you like, then paste it removing the '0x' prefix.
  The second approach is avoiding self intervention, letting Docker handle
  it automatically. This will make Besu to create a PK for you but the
  drawback is it won't give you the address or passphrase corresponding to
  the PK, so you need this information to use it in any other place, like
  setting the node as a validator, maybe the first approach is more convenient.

### Common folder

This folder have a couple of files: `config/besu.config.toml` and `config/genesis.json`
which are shared by all the nodes in the chain.

The _besu.config.toml_ contains the Besu specific paramaters that will be used when
starting the node.

The _genesis.json_ file contains information needed by to deploy the genesis block,
as well as some parameters for Clique config.

Apart from this, there is another file (`static-nodes.json`) that will be
generated when running the [static-nodes-generator-orchestrator.sh](#static-nodes-generator-orchestrator-script)
script.

This file will be placed under the folder `/generated` and is ignored by git due
to the nature of its creation being automatically done via script.

### Static nodes JSON generator folder

  #### docker-compose
  
  This docker-compose.yml is used to run the nodes of the blockchain with
  a minimal setup. Then, when the nodes are ready, it runs another service
  that simply call the shell script to generate the static-nodes.json file
  with the enodes of the nodes.
  
  #### static-nodes-generator-script
  
  This script handles the enodes collecting and after that will generate a
  static-nodes.json file in a temporal folder called `/.output`.

### static-nodes-generator-orchestrator-script

This script is quite simply by useful, taking the static-nodes.json
generation process to the next level of automation.

It will orchestrate the whole generation process by doing:
1. Running up the docker-compose.yml that will setup the nodes (remember
   this step is already triggering the enode collection and json file
   creation).
2. Waiting the file to be generated and when it's done, it will copy it
   to [`/common/config`](#common-folder) so make it completely ready to
   use in [step 2](#step-2).
3. Cleaning up the Docker containers by bringing down the docker-compose.yml.

This script accepts an optional parameter `delay`. Its initial value is set
to 5 seconds. If you run the script and no static-nodes.json is generated
you may have to increase the delay to give more time to the nodes be ready
to be interacted.

Example:
```
entrypoint: ["/besu/scripts/static-nodes-generator/static-nodes-generator.sh"]
command: >
  nodes=172.28.0.11:8545,172.28.0.12:8545
  delay=10
```

### docker-compose

This docker-compose.yml is the one in charge of the actual blockchain setup.

### static-nodes-runner-script

The `static-nodes-runner.sh` is a simple script that wraps the call to the
docker-compose.yml.

What it does under the hood is just making sure of
every node in the [`/nodes`](#nodes-folders) has its own static-nodes.json
file in their `/.data` folder by copying it from the one in
`/common/config/generated/static-nodes.json`.

Then it runs the docker-compose.yml as you would do manually.

So for running this script you also need to check your Docker daemon is
up and running.

---

## Static nodes JSON file generation

This process corresponds to the above mention [step 1](#step-1).

In order to generate the static-nodes.json file you should have your Docker
daemon up and running.

The workflow is as follows.

The [docker-compose.yml](#docker-compose) runs the nodes with the minimal
required setup.

Once the nodes are up and running, it will trigger the
[script](#static-nodes-generator-script) to generate the file.

Up this point the generation is completely valid and independent, you can
take the generated file and use it as you wish.

However, instead of running up the docker-compose.yml by your own, it's recommended
to simply run the [orchestrator script](#static-nodes-generator-orchestrator-script).

This will reduce the manual intervention needed into just running a single
CLI command, copying the json file into the required place for step 2 working
seamlessly and also cleaning up the Docker containers.

---

## Running the blockchain

### Step 1: Generating the static-nodes.json

If you are in project's root folder, you should go to the example's root:
```
cd multiple-nodes/static-nodes
```

To run the process that generates the static-nodes.json you can run:
```
./static-nodes-generator-orchestrator.sh
```

It should generate the file at: `/common/config/generated/static-nodes.json`

---

### Step 2: Actual blockchain deployment

To deploy the blockchain use the script:
```
./static-nodes-runner.sh
```

or if you prefer directly running the docker-compose.yml (You first should
check every node in `/nodes` folder has one copy of the static-nodes.json
file under `./data`):

```
docker-compose up
```

---

__Some useful commands to clean up the temporal files and folders__:

To remove `.data` folder (subdirectories included):
```
find . -type d -name '.data' -exec rm -rf {} +
```

To remove `.output` folder (subdirectories included):
```
find . -type d -name '.output' -exec rm -rf {} +
```

To remove `generated` folder (subdirectories included):
```
find . -type d -name 'generated' -exec rm -rf {} +
```

Altogether:
```
find . -type d -name '.data' -exec rm -rf {} +
find . -type d -name '.output' -exec rm -rf {} +
find . -type d -name 'generated' -exec rm -rf {} +
```

---

## Initial state of the chain

### Validators

As stated in the `extradata` field in `genesis.json`, there will be only
two validators in the chain. The addresses correspond to the nodes:
- node1
- node3

Validators doesn't necessary need to have any funds (node7 has 0 ETH).
In the `alloc` field we are initially funding nodes like this:
- node1: 100 ETH
- node2: 27.5 ETH

### Peering

The current approach is config the static-nodes.json file with all the nodes
in the blockchain:
```
entrypoint: ["/besu/scripts/static-nodes-generator/static-nodes-generator.sh"]
command: >
  nodes=172.28.0.11:8545,172.28.0.12:8545,172.28.0.13:8545,172.28.0.14:8545,172.28.0.15:8545
  delay=10
```

Based on that, the resulting peering map should be every node to be connected
with all the rest of the nodes:
```
node1 -> node2, node3, node4, node5 
node2 -> node1, node3, node4, node5
node3 -> node1, node2, node4, node5
node4 -> node1, node2, node3, node5
node5 -> node1, node2, node3, node4
```

---

However, if we only configure the nodes node1 and node2 to be set as static
nodes:
```
entrypoint: ["/besu/scripts/static-nodes-generator/static-nodes-generator.sh"]
command: >
  nodes=172.28.0.11:8545,172.28.0.12:8545
  delay=10
```

The peering map would end up being as follows:
```
node1 -> node2, node3, node4, node5 
node2 -> node1, node3, node4, node5
node3 -> node1, node2
node4 -> node1, node2
node5 -> node1, node2
```

Nodes node3, node4 and node5 only know the nodes1 and node2 since both are the
only ones specified in the static-nodes.json.

Nodes node1 and node2 know the rest of the chain because the others nodes are
peering with them.

_**NOTE_: This approach takes a few minutes until the nodes do the peering.
Probably because having such a low amount of static nodes will make things
hard for Besu to handle the peering.

---

__Hybrid approach__

Since this example aims to cover an only static nodes approach, p2p discovering
is disabled.

However, it's possible to make a hybrid solution. If p2p discovering were
active for this last mention scenario, the peering map would end up in all
nodes peering with all the rest of the nodes in the chain.

This is because, for example, node3 would initially only peer with node1 and
node2 but, eventually, node4 and node5 will peer with node1 (or node2), and
this will allow node3 to peer node4 and node5 via node1 (or node2).

---
