// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";

import "src/interfaces/ITreasury.sol";

contract AllocateTreasury is Script {
    address treasury = 0xCb8981dBAB2B5F21674De1E9520015331E90C9f5;

    function run() public {
        vm.startBroadcast();

        ITreasury(treasury).allocateSeigniorage();

        vm.stopBroadcast();
    }
}
