#!/usr/bin/sh

source ./.env

forge script script/AllocateTreasury.s.sol:AllocateTreasury --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv
