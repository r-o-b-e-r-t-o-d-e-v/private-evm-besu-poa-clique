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
  - [static-nodes-orchestrator-script](#static-nodes-orchestrator-script)
- [Static nodes JSON file generation](#static-nodes-json-file-generation)

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


### Common folder


### Static nodes JSON generator folder

  #### docker-compose
  
  This docker-compose.yml is used to run the nodes of the blockchain with
  a minimal setup. Then, when the nodes are ready, it runs another service
  that simply call the shell script to generate the static-nodes.json file
  with the enodes of the nodes.
  
  #### static-nodes-generator-script
  
  This script handles the enodes collecting and after that will generate a
  static-nodes.json file in a temporal folder called `/.output`.

### static-nodes-orchestrator-script

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
to simply run the [orchestrator script](#static-nodes-orchestrator-script).

This will reduce the manual intervention needed into just running a single
CLI command, copying the json file into the required place for step 2 working
seamlessly and also cleaning up the Docker containers.

---
