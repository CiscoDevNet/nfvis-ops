#!/bin/sh
VAULT_OPTIONS=""
if [[ ! -z "$ANSIBLE_VAULT_PASSWORD_FILE" ]]; then
   VAULT_OPTIONS="--env ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault.pw -v $ANSIBLE_VAULT_PASSWORD_FILE:/tmp/vault.pw"
fi

#docker run -it --rm -v $PWD:/ansible --env PWD="/ansible" --env USER="$USER" --env ANSIBLE_LOG_PATH=/ansible/debug.log --env ANSIBLE_ENABLE_DEBUG=True $VAULT_OPTIONS ansible-nfvis ansible-playbook "$@" 
docker run -it --rm -v $PWD:/ansible --env PWD="/ansible" --env USER="$USER" $VAULT_OPTIONS ansible-nfvis ansible-playbook "$@" 
