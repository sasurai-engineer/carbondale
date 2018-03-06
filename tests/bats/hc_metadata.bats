#!/usr/bin/env bats

load test_helper

CONSUL_IP=$(cat /etc/environment | grep DOCKER_HOST_IP | cut -d "=" -f2)
CONSUL_PORT=8500
CONSUL_API_VERSION=v1
CONSUL_HEALTH_API=health/state/passing

@test "METADATA: Consul is active." {
    skip "Skipping test until we support Consul"
    output=$(curl -s http://${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_HEALTH_API})
    assert_contains "Serf Health Status"
}

@test "METADATA: Vault is unsealed." {
    skip "Skipping test until we support Vault"
    output=$(curl -s http://${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_HEALTH_API})
    assert_contains $output "Vault Sealed Status"
}
