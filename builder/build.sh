#!/bin/bash

set -e
cd $(dirname $0)

# Build all
git clone https://github.com/Lora-net/gateway_2g4_hal repo
pushd repo
make clean all
popd
