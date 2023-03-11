#!/usr/bin/sh

source ./.env

forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
