#!/bin/sh

docker run -it --rm -v $PWD:/ansible --env PWD="/ansible" --env USER="$USER" --device /dev/fuse --cap-add SYS_ADMIN ansible-nfvis ansible-playbook build-iso.yml "$@"