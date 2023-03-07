// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "src/Tomb.sol";
import "src/TShare.sol";
import "src/TBond.sol";
import "src/distribution/TombGenesisRewardPool.sol";
import "src/interfaces/IUniswapV2Router.sol";
import "src/lib/UniswapV2Library.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

import "openzeppelin-contracts/token/ERC20/ERC20Burnable.sol";
import "src/owner/Operator.sol";

contract Deploy is Script {
    using stdJson for string;

    function run() public {
        string memory config = vm.readFile("script/deploy_conf.json");

        // Protocol parameters
        address daoFund = tx.origin;
        address devFund = tx.origin;
        uint256 genesisStartTime = block.timestamp + 10 minutes;

        // Dex parameters
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        vm.startBroadcast();

        // Tokens
        Tomb tomb = new Tomb(0, tx.origin);
        TShare tshare = new TShare(block.timestamp, daoFund, devFund);
        TBond tbond = new TBond();
        USDC usdc = new USDC();

        usdc.mint(tx.origin, 100000 ether);

        // Genesis pools
        TombGenesisRewardPool genesisPool = new TombGenesisRewardPool(address(tomb), genesisStartTime);

        // Fund genesis pool
        tomb.distributeReward(address(genesisPool));

        tomb.approve(router, 1 ether);
        usdc.approve(router, 1 ether);
        IUniswapV2Router(router).addLiquidity(
            address(tomb),
            address(usdc),
            1 ether,
            1 ether,
            0,
            0,
            tx.origin,
            block.timestamp
        );
        address lpPair = UniswapV2Library.pairFor(factory, address(tomb), address(usdc));

        // Setup genesis pools
        genesisPool.add(1000, IERC20(lpPair), false, 0);
        genesisPool.add(1000, IERC20(usdc), true, 0);

        vm.stopBroadcast();
    }
}

contract USDC is ERC20Burnable, Operator {

    constructor() public ERC20("USD Coin", "USDC") {}

    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}
