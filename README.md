# Private EVM | Hyperledger Besu | PoA (Clique)

---

# Table of contents
- [Overview](#overview)
- [Examples](#examples)
  - [Single node example](#single-node-example)
  - [Multiple nodes: Node discovery example](#multiple-nodes-node-discovery-example)
  - [Multiple nodes: Static nodes example](#multiple-nodes-static-nodes-example)

---

## Overview

This project is aimed to launch a private EVM based blockchain by deploying
a few nodes using Docker technology.

The client nodes are handled by using Hyperledger Besu that runs a PoA
consensus protocol implemented with Clique.

There are several examples in this project. They are a showcase on the
different possibilities that we have to deploy nodes.

In order to make use of them you should have installed Docker.

---
## Examples

### Single node example

The [single node example](single-node) folder holds an example that allows to
run a single Besu node.

More details can be in the [README.md](single-node/README.md) file of the example.

---

### Multiple nodes: Node discovery example

The [node discovery example](multiple-nodes/node-discovery) folder is an example
that shows how to orchestrate several Besu nodes with automatic node discovery.

The nodes will initially connect with a few of others and since peer to peer
discovery feature is enabled, will end up peering with the rest of the chain.

Example: node 3 may be configured to initially connect with node2, but since
other nodes will be peered with others, node3 will end up being peered with
node1, node2, node4, etc...

More details can be in the [README.md](multiple-nodes/node-discovery/README.md)
file of the example.

---

###  Multiple nodes: Static nodes example

The [static nodes example](multiple-nodes/static-nodes) folder is an example
that shows how to orchestrate several Besu nodes by configuring static nodes.

This means nodes in the chain will not automatically discover the rest of the
nodes, just the ones established as static nodes.

Example. Nodes node1 and node2 are set as static. Nodes node3 and node4 will
not know each other, but they will still be peered with node1 and node2.

More details can be in the [README.md](multiple-nodes/static-nodes/README.md)
file of the example.

---
