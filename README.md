# Carbondale
Carbondale is a cli tool that initializes and unseals Vault for development use.

## Overview
Vault secures, stores and controls access to tokens, passwords, certificates, 
API keys, and other secrets. Carbondale is an abstraction layer to Vault that
automates the provisioning of Vault using Consul.

Vault requires that it be initialized and unsealed before you are able to save key-value
pairs. The initialization process generates a set number of unseal keys and a root key. 
The unseal process takes three of the unseal keys and feeds them back in to Vault.
The keys are then scrubbed and removed from the filesystem.

## Prerequisites
1. Linux distro w/kernel 4.1+ with `systemd` as the init system
2. Docker 17.12+

## Quickstart
1. Checkout repo
2. `cd carbondale`
3. `carbond up`
4. `carbond help`

## Development
The development deployment for Carbodale deploys a two docker containers; Vault
and Consul. Consul is configured as both the Vault backend, as well as the 
location for the generated unseal keys and root keys.

The development deployment of Vault will persist on the filesystem only. This 
means if you delete the VM containing Vault, you will lose your values, but 
if the service is brought down and back up, it will persist the values. For
values that require a more robust persistence requirement, please use a 
production-level environment.

## Tests
There are currently healthchecks and tests created for Carbondale using the
BATS framework.

Heathchecks are non-destructive test that can be run to validate that the 
resources created have been provisioned correctly. Tests can be destructive.
The current tests will attempt to CRUD key-value pairs to Vault, but there
are plans to add testing that will test the destruction and creation of Vault.
