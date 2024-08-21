# Multiple Nodes: Node Discovery Example

---

# Table of contents
- [Overview](#overview)
- [Structure](#structure)
  - [Nodes folders](#nodes-folders)
  - [Common folder](#common-folder)
  - [docker-compose](#docker-compose)
  - [Dockerfile](#dockerfile)
  - [enode collector script](#enode-collector-script)
- [Running the blockchain](#running-the-blockchain)
- [Initial state of the chain](#initial-state-of-the-chain)
  - [Validators](#validators)
  - [Peering](#peering)

---

## Overview

This example consist in a setup to deploy a blockchain made up of 7 nodes.
There is no configuration for static nodes, since the final purpose is to have
a configuration that allows these nodes to peer among them in the most automatic
way possible.

In order to run this example you should already have Docker installed.

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

### docker-compose

This is the most interesting file in the example. Here we setup the nodes se want
our blockchain to have.

** All the nodes are configured using the same image: hyperledger/besu:24.7.1 (the
'stable' version on the moment the development is happening). Let's see one of them
more in detail:

```
  node1:
    image: hyperledger/besu:24.7.1
    container_name: besu-node1
    ports:
      - 8545:8545
      - 8546:8546
      - 30303:30303   # For node discovering
    volumes:
      - ./node1/.data:/besu/data
      - ./node1/.env:/besu/secret
      - ./common/config:/besu/config
    networks:
      besu-chain:
        ipv4_address: 172.28.0.11
    command: >
      --config-file=/besu/config/besu.config.toml
```

The container names are following a simple convention of `besu-{node_name}`.

The ports are being mapped to avoid conflicts in the host:
  - 8545 for HTTP
  - 8546 for WebSocket
  - 30303 is used internally for node discovering

The volumes, as previously mentioned, are mounting the data with the blockchain info,
the node's key and also the common files needed to start the Besu node.

In the networks field we are simply setting a custom ip for each node. Here the 
convention is being follow is `172.28.0.1{node_id}`

And finally, the command is used to give to Besu execution command the config file 
with the parameters we defined in `besu.config.toml`
  
Although I just said all the nodes are using the same image, I kind of lied...
In order to allow other nodes to peer with validators, we need to set the Besu
parameter `--bootnodes={enode_list}`

This adds a bit more of complexity than it may seem, since the enode is only know at
runtime (Besu uses the PK of the node to generate the enode). More details
[here](#enode-collector-script)

So in order to avoid doing a multistep deployment (one to deploy some nodes,
extracting their enode manually, and use that enodes to do a second deploy with
the rest of the nodes) I made a custom script that will be covered below.

So when you want to specify the bootnodes for node you will have to configure like this:

```
  node4:
    build: .
    image: hyperledger/besu-curl:24.7.1
    container_name: besu-node4
    depends_on:
      - node2
    ports:
      - 8575:8545
      - 8576:8546
      - 30306:30303   # For node discovering
    volumes:
      - ./node4/.data:/besu/data
      - ./node4/.env:/besu/secret
      - ./common/config:/besu/config
      - ./run_besu_with_bootnodes.sh:/besu/scripts/run_besu_with_bootnodes.sh
    networks:
      besu-chain:
        ipv4_address: 172.28.0.14
    entrypoint: ["/besu/scripts/run_besu_with_bootnodes.sh"]
    command: >
      --config-file=/besu/config/besu.config.toml
      bootnodes=172.28.0.12:8545
```

As you can see, the first difference we notice is the 'build' field that will
search for a Dockerfile and create a new image called `hyperledger/besu-curl:24.7.1`
I will cover the reason for this in the next section, but for now let's just 
think this is pretty much the same as simply having the same `hyperledger/besu:24.7.1`
that we were using with the previous node definition.

There is also the 'depends_on' field that will help on waiting the specified
node to be running before starting this one.

And also there is a new volume element. This is just to be able to run the
previous mention script, since it is executed inside the container we need to
support it in this way.

The field 'entrypoint' is now overriding the image entry point to run the custom
script instead of directly using the Besu image entrypoint to run besu command.

And pretty important, notice this `bootnodes=172.28.0.12:8545` parameter. This
is accepted by the custom script. Here we need to specify the direction from
where we want to make a call to retrieve the enode to set as a bootnode. As
you can see, we need to specify the HTTP port, since the enode query will be
made this way.

### Dockerfile

So as mentioned in the previous section there is this Dockerfile. This is
actually very simple one since the only purpose it has is to wrap the actual
Besu official image `hyperledger/besu:24.7.1` and extend it adding the `curl`
dependency.

This is needed later in the script to retrieve the enode for the bootnodes.

### enode collector script

This script has, as main purpose, gathering the enodes to add in the Besu
config when running the `besu` command and do the actual execution of it
once the enodes were processed.

It will also handle a customizable initial delay that will help when some
nodes depend on others to be executed.

Accepted parameters: When calling the script we can define this parameters:

```
command: >
   --config-file=/besu/config/besu.config.toml
   bootnodes=172.28.0.11:8545,172.28.0.14:8545,172.28.0.15:8545
   delay=14
```

- _bootnodes_: This parameters accepts a comma separated list of strings
  following the pattern `{host}:{port}`. This will be used to make an
  HTTP call that will retrieve the enode.

- _delay_: This is the amount of seconds to wait until start processing
  the script (therefore running the node).

- Other parameters starting with `--`: Parameters starting with a double
  hyphen will be treated as Besu config parameters.

The script has a retry mechanism to care about possible delays when
setting up dependant nodes although the values are predefined. I didn't
want to expose them to avoid making the call to the script more complex.

Also, worth mentions there is another predefined variable:
`SKIP_MISSING_BOOTNODES` (by default 'true') that will allow to ignore
a bootnode if its enode wasn't found (Although a warning is logged).
Setting it to false will make the script to stop the execution of the node.

---

## Running the blockchain

In order to run the blockchain, you first check your Docker daemon is
up and running.

If you are in the root of the whole project, please move to the
example folder:
```
cd multiple-nodes/node-discovery
```

In order to run the nodes and deploy the blockchain, simply run:
```
docker-compose -f docker-compose.yml up
```

You may want to remove the previous data of the nodes before deploying again:
```
find . -type d -name '.data' -exec rm -rf {} +
```

Single liner:
```
find . -type d -name '.data' -exec rm -rf {} +; docker-compose -f docker-compose.yml up
```

---

## Initial state of the chain

### Validators

As stated in the `extradata` field in `genesis.json`, there will be only
two validators in the chain. The addresses correspond to the nodes:
- node1
- node7

As you can check in the logs, the validators will mine blocks with a
_round-robin_ strategy.

Validators doesn't necessary need to have any funds (node7 has 0 ETH).
In the `alloc` field we are initially funding nodes like this:
- node1: 100 ETH
- node2: 27.5 ETH
- node5: 0.025 ETH

### Peering

The initial setup of the nodes in terms of peering is like this:

node1 -> no dependencies
node2 -> no dependencies
node3 -> node1
node4 -> node2
node5 -> node1 and node2
node6 -> node1, node4 and node5
node7 -> node6

When deployed all nodes should end up peering with the rest. Example:

- Initially, node2 is not peering with other nodes, therefore cannot receive
any update on the state of the blockchain since node2 is not a validator in
the chain.

- When node4 starts, it gets peered with node2. However, same as before,
  both node2 and node4 are not validators, and as they are connected only
  with themselves, they won't receive any update on the chain state.

- When node5 starts, it peers with node1 (validator) and also node2. This
  helps node2 (and also node4 via node2) discover node1, so node2 can begin
  receiving updates.

---
