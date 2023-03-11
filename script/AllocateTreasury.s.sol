// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";

import "src/interfaces/ITreasury.sol";

contract AllocateTreasury is Script {
    address treasury = 0x236e6e982E13F53864A67E763E7D7eBC3323bAeB;

    function run() public {
        vm.startBroadcast();

        ITreasury(treasury).allocateSeigniorage();

        vm.stopBroadcast();
    }
}
