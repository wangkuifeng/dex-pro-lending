// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Pool} from "../src/core/Pool.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";
import {AToken} from "../src/core/AToken.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol"; // 确保路径对应你的 Mock 合约

contract DeployAndMockScript is Script {
    // Sepolia Chainlink 价格预言机地址 (保持真实，前端数据才好看)
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant USDC_USD_FEED = 0xa2f78AB2355fE2F984D808b5ce067eEbD5E912fb;
    address constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;

    // LTV 和清算阈值配置
    uint256 constant WETH_LTV = 8000;
    uint256 constant WETH_LIQ_THRESHOLD = 8500;
    uint256 constant WETH_LIQ_BONUS = 10500;

    uint256 constant USDC_LTV = 7500;
    uint256 constant USDC_LIQ_THRESHOLD = 8000;
    uint256 constant USDC_LIQ_BONUS = 10500;

    uint256 constant USDT_LTV = 7500;
    uint256 constant USDT_LIQ_THRESHOLD = 8000;
    uint256 constant USDT_LIQ_BONUS = 10500;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // ========== 1. 部署 Mock 资产并疯狂 Mint ==========
        console.log("\n========== Deploying Mock Tokens ==========");
        MockERC20 mockWETH = new MockERC20("Wrapped Ether", "WETH", 18);
        MockERC20 mockUSDC = new MockERC20("USD Coin", "USDC", 6);
        MockERC20 mockUSDT = new MockERC20("Tether USD", "USDT", 6);

        mockWETH.mint(deployer, 1000 * 10**18);   // 1000 假 ETH
        mockUSDC.mint(deployer, 1000000 * 10**6); // 100万 假 USDC
        mockUSDT.mint(deployer, 1000000 * 10**6); // 100万 假 USDT
        console.log("Minted massive test tokens to:", deployer);

        // ========== 2. 部署核心逻辑 ==========
        console.log("\n========== Deploying Core Contracts ==========");
        PriceOracle oracle = new PriceOracle();
        Pool pool = new Pool();
        pool.setOracle(address(oracle));

        // ========== 3. 部署 AToken 并初始化池子 (绑定 Mock 地址) ==========
        console.log("\n========== Initializing Reserves ==========");
        AToken aWETH = new AToken(address(pool), address(mockWETH), "DEX Pro WETH", "dpWETH");
        pool.initReserve(address(mockWETH), address(aWETH), WETH_LTV, WETH_LIQ_THRESHOLD, WETH_LIQ_BONUS);

        AToken aUSDC = new AToken(address(pool), address(mockUSDC), "DEX Pro USDC", "dpUSDC");
        pool.initReserve(address(mockUSDC), address(aUSDC), USDC_LTV, USDC_LIQ_THRESHOLD, USDC_LIQ_BONUS);

        AToken aUSDT = new AToken(address(pool), address(mockUSDT), "DEX Pro USDT", "dpUSDT");
        pool.initReserve(address(mockUSDT), address(aUSDT), USDT_LTV, USDT_LIQ_THRESHOLD, USDT_LIQ_BONUS);

        // ========== 4. 预言机绑定 (假币对应真价格) ==========
        address[] memory assets = new address[](3);
        address[] memory sources = new address[](3);
        assets[0] = address(mockWETH); sources[0] = ETH_USD_FEED;
        assets[1] = address(mockUSDC); sources[1] = USDC_USD_FEED;
        assets[2] = address(mockUSDT); sources[2] = USDT_USD_FEED;
        oracle.setAssetSources(assets, sources);

        // ========== 5. The Magic: 顺手注入初始 TVL ==========
        console.log("\n========== Supplying Initial Liquidity ==========");
        mockWETH.approve(address(pool), type(uint256).max);
        mockUSDC.approve(address(pool), type(uint256).max);

        pool.supply(address(mockWETH), 15 * 10**18, deployer, 0);   // 存 15 个 WETH
        pool.supply(address(mockUSDC), 80000 * 10**6, deployer, 0); // 存 8万 USDC

        vm.stopBroadcast();

        // 打印汇总，供你更新 Go 后端和前端使用
        console.log("\n========== Deployment Summary ==========");
        console.log("Pool Address (Update Go .env):", address(pool));
        console.log("Mock WETH:", address(mockWETH));
        console.log("Mock USDC:", address(mockUSDC));
        console.log("Mock USDT:", address(mockUSDT));
        console.log("==========================================");
    }
}