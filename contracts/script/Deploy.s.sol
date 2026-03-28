// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Pool} from "../src/core/Pool.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";
import {AToken} from "../src/core/AToken.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";

/**
 * @title DeployScript
 * @dev 将 DEX Pro Lending 协议部署到 Sepolia 测试网
 *
 * 部署步骤：
 * 1. 部署 PriceOracle
 * 2. 部署 Pool
 * 3. Pool 设置 Oracle
 * 4. 为每个资产部署 AToken 并初始化
 * 5. 设置价格源
 */
contract DeployScript is Script {
    // ========== 配置参数 ==========

    // Sepolia 测试网上的常用代币地址
    address constant WETH_SEPOLIA = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant USDC_SEPOLIA = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant USDT_SEPOLIA = 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06;

    // Sepolia Chainlink 价格预言机地址
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant USDC_USD_FEED = 0xa2f78AB2355fE2F984D808b5ce067eEbD5E912fb;
    address constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;

    // LTV 和清算阈值配置 (以基点为单位，10000 = 100%)
    uint256 constant WETH_LTV = 8000;           // 80%
    uint256 constant WETH_LIQ_THRESHOLD = 8500; // 85%
    uint256 constant WETH_LIQ_BONUS = 10500;    // 105%

    uint256 constant USDC_LTV = 7500;           // 75%
    uint256 constant USDC_LIQ_THRESHOLD = 8000; // 80%
    uint256 constant USDC_LIQ_BONUS = 10500;    // 105%

    uint256 constant USDT_LTV = 7500;           // 75%
    uint256 constant USDT_LIQ_THRESHOLD = 8000; // 80%
    uint256 constant USDT_LIQ_BONUS = 10500;    // 105%

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========== Deployment Started ==========");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // ========== Step 1: Deploy PriceOracle ==========
        console.log("\n========== Deploying PriceOracle ==========");
        PriceOracle oracle = new PriceOracle();
        console.log("PriceOracle deployed at:", address(oracle));

        // ========== Step 2: Deploy Pool ==========
        console.log("\n========== Deploying Pool ==========");
        Pool pool = new Pool();
        console.log("Pool deployed at:", address(pool));

        // ========== Step 3: Set Oracle ==========
        console.log("\n========== Setting Oracle ==========");
        pool.setOracle(address(oracle));
        console.log("Oracle set to Pool");

        // ========== Step 4: Deploy ATokens and Initialize Reserves ==========

        // WETH
        console.log("\n========== Deploying WETH AToken ==========");
        AToken aWETH = new AToken(
            address(pool),
            WETH_SEPOLIA,
            "DEX Pro WETH",
            "dpWETH"
        );
        console.log("aWETH deployed at:", address(aWETH));

        pool.initReserve(
            WETH_SEPOLIA,
            address(aWETH),
            WETH_LTV,
            WETH_LIQ_THRESHOLD,
            WETH_LIQ_BONUS
        );
        console.log("WETH reserve initialized");

        // USDC
        console.log("\n========== Deploying USDC AToken ==========");
        AToken aUSDC = new AToken(
            address(pool),
            USDC_SEPOLIA,
            "DEX Pro USDC",
            "dpUSDC"
        );
        console.log("aUSDC deployed at:", address(aUSDC));

        pool.initReserve(
            USDC_SEPOLIA,
            address(aUSDC),
            USDC_LTV,
            USDC_LIQ_THRESHOLD,
            USDC_LIQ_BONUS
        );
        console.log("USDC reserve initialized");

        // USDT
        console.log("\n========== Deploying USDT AToken ==========");
        AToken aUSDT = new AToken(
            address(pool),
            USDT_SEPOLIA,
            "DEX Pro USDT",
            "dpUSDT"
        );
        console.log("aUSDT deployed at:", address(aUSDT));

        pool.initReserve(
            USDT_SEPOLIA,
            address(aUSDT),
            USDT_LTV,
            USDT_LIQ_THRESHOLD,
            USDT_LIQ_BONUS
        );
        console.log("USDT reserve initialized");

        // ========== Step 5: Set Price Sources ==========
        console.log("\n========== Setting Price Sources ==========");

        address[] memory assets = new address[](3);
        address[] memory sources = new address[](3);

        assets[0] = WETH_SEPOLIA;
        assets[1] = USDC_SEPOLIA;
        assets[2] = USDT_SEPOLIA;

        sources[0] = ETH_USD_FEED;
        sources[1] = USDC_USD_FEED;
        sources[2] = USDT_USD_FEED;

        oracle.setAssetSources(assets, sources);
        console.log("Price sources set");

        vm.stopBroadcast();

        // ========== Deployment Summary ==========
        console.log("\n========== Deployment Complete ==========");
        console.log("PriceOracle:", address(oracle));
        console.log("Pool:", address(pool));
        console.log("aWETH:", address(aWETH));
        console.log("aUSDC:", address(aUSDC));
        console.log("aUSDT:", address(aUSDT));
        console.log("==========================================");

        // ========== Verify Deployment ==========
        console.log("\n========== Verifying Deployment ==========");
        DataTypes.ReserveData memory wethReserve = pool.getReserveData(WETH_SEPOLIA);
        DataTypes.ReserveData memory usdcReserve = pool.getReserveData(USDC_SEPOLIA);
        DataTypes.ReserveData memory usdtReserve = pool.getReserveData(USDT_SEPOLIA);
        console.log("Pool Oracle address:", address(pool.oracle()));
        console.log("WETH LTV:", wethReserve.configuration & uint256(0xFFFF));
        console.log("USDC LTV:", usdcReserve.configuration & uint256(0xFFFF));
        console.log("USDT LTV:", usdtReserve.configuration & uint256(0xFFFF));
    }
}
