#!/bin/sh

docker run -it --rm -v $PWD:/ansible --env PWD="/ansible" --env USER="$USER" --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined ansible-nfvis ansible-playbook build-iso.yml "$@"
