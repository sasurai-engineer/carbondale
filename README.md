# Carbondale
Carbondale is a cli tool that initializes and unseals Vault for development use.

## Overview
Vault secures, stores and controls access to tokens, passwords, certificates, 
API keys, and other secrets. Carbondale is an abstraction layer to Vault that
automates the provisioning of Vault.

Vault requires that it be initialized and unsealed you are able to save key-value
pairs. The initialization process involves generated a set number of
unseal keys and a root key. The unseal process takes three of the unseal keys 
and feeds them back in to Vault. The keys are then scrubbed and removed from 
the filesystem.

## Quickstart
1. Checkout repo
2. `cd carbondale`
3. `carbond up`

## Development
The development deployment for Carbodale deploys a two docker containers; Vault
and Consul. Consul is configured as both the Vault backend, as well as the 
location for the generated unseal keys and root keys.

The development deployment of Vault will persist on the filesystem only. This 
means if you delete the VM containing Vault, you will lose your values, but 
if the service is brought down and back up, it will persist the values. For
values that require a more robust persistence requirement, please use a 
production-level environment.

## Testing
There are currently healthchecks and tests created for Carbondale using the
BATS framework.

Heathchecks are non-destructive test that can be run to validate that the 
resources created have been provisioned correctly. Tests can be destructive.
The current tests will attempt to CRUD key-value pairs to Vault, but there
are plans to add testing that will test the destruction and creation of Vault.

## Production
For production, it is recommended that you run at least a 3-node cluster, but since
Carbondale uses an Official dockerized version of Vault, this gives us certian liberties 
when determining what platform to deploy to for production use.

At the moment, Carbondale does not decide which platform to deploy on to, but does enforce
that in production the proper steps have been taken, regardless of where the application 
is deployed, i.e. container service, cloud instance, etc. See [PRR Model](https://landing.google.com/sre/book/chapters/evolving-sre-engagement-model.html)


![Vault AWS Auth Method diagram](https://www.vaultproject.io/assets/images/vault-aws-ec2-auth-flow-956d2a58.png)

### Prerequisites
1. [AWS instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) must be
provided to SNEI to authorize access.
2. [AWS VPC Peering](https://docs.aws.amazon.com/AmazonVPC/latest/PeeringGuide/Welcome.html)
