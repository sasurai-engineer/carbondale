#!/usr/bin/env bats

load test_helper

CONSUL_IP=$(cat /etc/environment | grep DOCKER_HOST_IP | cut -d "=" -f2)
CONSUL_PORT=8500
CONSUL_API_VERSION=v1
CONSUL_KV_API=kv
CONSUL_HEALTH_API=health/state/passing

@test "CONSUL: Consul is active." {
    output=$(curl -s http://${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_HEALTH_API})
    assert_contains "Serf Health Status"
}

@test "CONSUL: Reading, writing, and deleting to Consul works." {
    TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
    run curl -fX PUT ${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/testing/token -d $TOKEN
    assert_success

    output=$(curl -sf "${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/testing/token" | jq -r '.[].Value'| base64 -d)
    assert_contains "$output" "$TOKEN"

    run curl --request DELETE "${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/testing/token"
    assert_success

    run curl -sf "${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/testing/token"
    [ "$status" -eq 22 ]
}

@test "VAULT: Vault is unsealed." {
    output=$(curl -s http://${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_HEALTH_API})
    assert_contains $output "Vault Sealed Status"
}

@test "VAULT: Reading, writing, listing and deleting key-value pairs to Vault works." {
	run vault list secret/
	assert_success

    TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
    run vault write secret/testing token=$TOKEN
    assert_success

    output=$(vault read secret/testing)
    assert_contains "$output" "$TOKEN"

    run vault delete secret/testing/token"
    assert_success

    run vault read secret/testing/token"
    [ "$status" -eq 2 ]
}
