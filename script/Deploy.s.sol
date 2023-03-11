// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "forge-std/Script.sol";
import "src/Tomb.sol";
import "src/TShare.sol";
import "src/TBond.sol";
import "src/Oracle.sol";
import "src/Masonry.sol";
import "src/Treasury.sol";
import "src/distribution/TombGenesisRewardPool.sol";

import "src/interfaces/ITreasury.sol";
import "src/interfaces/IUniswapV2Router.sol";
import "src/interfaces/IUniswapV2Pair.sol";
import "src/lib/UniswapV2Library.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

import "openzeppelin-contracts/token/ERC20/ERC20Burnable.sol";
import "src/owner/Operator.sol";

contract Deploy is Script {
    using stdJson for string;

    address daoFund;
    address devFund;
    address factory;
    address router;
    address usdc;

    function run() public {
        string memory config = vm.readFile("script/deploy_conf.json");

        daoFund = config.readAddress(".daoFund");
        devFund = config.readAddress(".devFund");
        factory = config.readAddress(".factory");
        router = config.readAddress(".router");
        usdc = config.readAddress(".usdc");

        bool isProduction = config.readBool(".production");
        uint256 genesisStartTime = config.readUint(".genesisStartTime");
        uint256 treasuryStartTime = config.readUint(".treasuryStartTime");

        vm.startBroadcast();

        // Tokens
        Tomb tomb = new Tomb(0, tx.origin);
        TShare tshare = new TShare(block.timestamp, daoFund, devFund);
        TBond tbond = new TBond();

        if (!isProduction) {
            USDC fakeUsdc = new USDC();
            fakeUsdc.mint(tx.origin, 1000e6);
            usdc = address(fakeUsdc);
        } 

        address nativePair = UniswapV2Library.pairFor(factory, address(tomb), usdc);

        console.log(nativePair);

        // Add initial liquidity
        tomb.approve(router, 1 ether);
        IERC20(usdc).approve(router, 1e6);
        IUniswapV2Router(router).addLiquidity(
            address(tomb),
            usdc,
            1 ether, // 1 TOMB
            1e6, // 1 USDC
            0,
            0,
            tx.origin,
            block.timestamp + 1000
        );

        // Treasury and Masonry
        Oracle oracle = new Oracle(IUniswapV2Pair(nativePair), 6 hours, treasuryStartTime);
        Treasury treasury = new Treasury();
        Masonry masonry = new Masonry();

        oracle.update();

        treasury.initialize(
            address(tomb),
            address(tbond),
            address(tshare),
            address(oracle),
            address(masonry),
            treasuryStartTime
        );
        treasury.setExtraFunds(
            daoFund,
            100, // 1%
            devFund,
            100  // 1%
        );

        masonry.initialize(
            IERC20(tomb),
            IERC20(tshare),
            ITreasury(address(treasury))
        );

        // Genesis pools
        TombGenesisRewardPool genesisPool = new TombGenesisRewardPool(address(tomb), genesisStartTime, devFund);

        // Fund genesis pool
        tomb.distributeReward(address(genesisPool));

        // Setup genesis pools
        genesisPool.add(1000, IERC20(nativePair), false, 0, 10);
        genesisPool.add(1000, IERC20(usdc), true, 0, 10);

        // Transfer operator to Treasury
        oracle.transferOperator(address(treasury));
        masonry.setOperator(address(treasury));
        tomb.transferOperator(address(treasury));
        tbond.transferOperator(address(treasury));
        tshare.transferOperator(address(treasury));

        vm.stopBroadcast();
    }
}

contract USDC is ERC20Burnable, Operator {

    constructor() public ERC20("USD Coin", "USDC") {
        _setupDecimals(6);
    }

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
