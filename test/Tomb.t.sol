// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "src/Tomb.sol";

contract TombTest is Test {
    Tomb tomb;
    address alice = 0xD7ecd81E390a420b4e529bbaf9380bC7C97dDA6b;

    function setUp() public {
        tomb = new Tomb(0, address(this));
    }

    function testMint() public {
        uint256 mintAmount = 100 ether;
        uint256 currentBalance = tomb.balanceOf(address(this));

        assertEq(tomb.mint(address(this), mintAmount), true);
        assertEq(tomb.balanceOf(address(this)), mintAmount + currentBalance);
    }

    function testTransfer() public {
        uint256 amountToTransfer = 1 ether;

        tomb.mint(address(this), amountToTransfer);
        tomb.transfer(alice, amountToTransfer);

        assertEq(tomb.balanceOf(alice), amountToTransfer);
    }
}
