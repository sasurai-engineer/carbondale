#!/bin/bash
set +e

CONSUL_IP=$(ip route get 1 | awk '{print $7;exit}')
CONSUL_PORT=8500
CONSUL_API_VERSION=v1
CONSUL_KV_API=kv
VAULT_IP=$CONSUL_IP
VAULT_PORT=8200
VAULT_API_VERSION=v1
VAULT_KV=service/vault
VAULT_ENV=/etc/environment

cget() {
    curl -sf "${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/${VAULT_KV}/$1" | jq -r '.[].Value' | base64 -d | sed 's/\x1b\[[0-9;]*[mGKH]//g'
 }

output() {
    cat <<EOF
We use an instance of HashiCorp Vault for secrets management.
It has been automatically initialized and unsealed.

The unseal keys and root token have been stored in Consul K/V.
   service/vault/root-token
   service/vault/unseal-key-{1..5}
EOF

    exit 0
}

vault_init() {
    VAULT_DEMO_KV=service/nodejs
    INIT_STATUS=$(curl -s "${VAULT_IP}:${VAULT_PORT}/${VAULT_API_VERSION}/${INIT_API}" | jq -r '.initialized')
    INIT_API=sys/health

    printf '\n%s\n' "Initializing Vault..."
    if [[ $INIT_STATUS == "true" ]] ;then
        printf '\n%s\n' "Vault has already been initialized!"
    else
        # Store master keys in consul for operator to retrieve and remove
        printf '\n%s\n' "Storing Vault keys..."
        COUNTER=1
        vault operator init &> /tmp/vault.init || true

        sleep 2
        cat /tmp/vault.init | tr -d '\r' | grep 'Unseal' | awk '{print $4}' | for key in $(cat -); do
            curl -fX PUT ${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/${VAULT_KV}/unseal-key-${COUNTER} -d "$key" > /dev/null 2>&1
            COUNTER=$((COUNTER + 1))
        done

        sleep 2
        printf '\n%s\n' "Vault has been initialized!"

        ROOT_TOKEN=$(cat /tmp/vault.init | tr -d '\r' | grep 'Initial' | awk '{print $4}')
        curl -fX PUT ${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/${VAULT_KV}/root-token -d ${ROOT_TOKEN} > /dev/null 2>&1
    fi

    printf '\n%s\n' "Setting up Vault demo..."
    curl -fX PUT ${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/${VAULT_DEMO_KV}/show_vault -d "true" > /dev/null 2>&1
    curl -fX PUT ${CONSUL_IP}:${CONSUL_PORT}/${CONSUL_API_VERSION}/${CONSUL_KV_API}/${VAULT_DEMO_KV}/vault_files -d "aws.html,generic.html" > /dev/null 2>&1
}

scrub_creds() {
    printf '\n%s\n' "Removing master keys from disk..."
    shred /tmp/vault.init
    rm -rf /tmp/vault.init
    printf '\n%s\n' "Master keys have been scrubbed from disk!"
}

vault_unseal() {
    SEAL_STATUS_API=sys/seal-status
    UNSEAL_API=sys/unseal
    SEAL_STATUS=$(curl -s "${VAULT_IP}:${VAULT_PORT}/${VAULT_API_VERSION}/${SEAL_STATUS_API}" | jq -r '.sealed')
    printf '\n%s\n' "Unsealing Vault..."
    if [ "${SEAL_STATUS}" != 'false' ];then
        curl -X PUT ${VAULT_IP}:${VAULT_PORT}/${VAULT_API_VERSION}/${UNSEAL_API} -d '{"key":"'$(cget unseal-key-1)'"}' > /dev/null 2>&1
        sleep 1
        curl -X PUT ${VAULT_IP}:${VAULT_PORT}/${VAULT_API_VERSION}/${UNSEAL_API} -d '{"key":"'$(cget unseal-key-2)'"}' > /dev/null 2>&1
        sleep 1
        curl -X PUT ${VAULT_IP}:${VAULT_PORT}/${VAULT_API_VERSION}/${UNSEAL_API} -d '{"key":"'$(cget unseal-key-3)'"}' > /dev/null 2>&1
        sleep 1
        printf '\n%s\n' "Vault setup complete!"
        return
    fi
    printf '\n%s\n' "Vault has already been unsealed. Setup complete!"
    return
 }

vault_login(){
    VAULT_TOKEN="$(cget root-token)"
    printf '\n%s\n' "Logging in to Vault..."
    vault login "$VAULT_TOKEN"
    sleep 2
    
    CUR_TOKEN=$(cat $VAULT_ENV | grep VAULT_TOKEN | cut -d "=" -f2)
    printf '\n%s\n' "Setting up Vault token..."
    if [[ -z "$CUR_TOKEN" ]];then
        sudo su -c "echo VAULT_TOKEN=$VAULT_TOKEN >> $VAULT_ENV"
        printf '\n%s\n' "Vault token set!"
    else
        printf '\n%s\n' "Vault token already set!"
    fi

    printf '\n%s\n' "Vault is now available for use!"
}

vault_set_addr(){
    VAULT_ADDR=http://${VAULT_IP}:8200
    CUR_ADDR=$(cat $VAULT_ENV | grep VAULT_ADDR | cut -d "=" -f2)
    printf '\n%s\n' "Setting Vault environment variables..."
    if [[ -z "$CUR_ADDR" ]];then
        sudo su -c "echo VAULT_ADDR=$VAULT_ADDR >> $VAULT_ENV"
        printf '\n%s\n' "Vault environment variable set!"
    else
        printf '\n%s\n' "Vault environment already set!"
    fi

}

vault_set_addr
vault_init
sleep 2
vault_unseal
sleep 2
vault_login
scrub_creds
output