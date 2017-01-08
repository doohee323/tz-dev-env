#!/usr/bin/env bash

set +x

### [run vagrant] ############################################################################################################

# just run one time
# vagrant box add Xenial https://github.com/jose-lpa/packer-ubuntu_lts/releases/download/v3.1/ubuntu-16.04.box

vagrant destroy -f
vagrant up

# vagrant ssh dev
# vagrant ssh client

exit 0
  