#!/usr/bin/env bats

load test_helper

CONSUL_IP=$(cat /etc/environment | grep DOCKER_HOST_IP | cut -d "=" -f2)
CONSUL_PORT=8500
CONSUL_API_VERSION=v1
CONSUL_KV_API=kv
@test "METADATA: Read, write and removing data to service works." {
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
