// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";
import {PoolUpgradeable} from "../src/core/PoolUpgradeable.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {AToken} from "../src/core/AToken.sol";

/**
 * @title SetupUpgradeablePool
 * @notice 配置可升级 Pool 合约
 *
 * 1. 配置预言机价格
 * 2. 部署 Mock 代币
 * 3. 部署 AToken
 * 4. 初始化储备
 */
contract SetupUpgradeablePool is Script {
    // Chainlink 真实喂价地址 (Sepolia)
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    // 已部署合约地址
    address constant POOL_ADDRESS = 0xe5ED95744b5a5987CBFd06827BC194F4664cC680;
    address constant ORACLE_ADDRESS = 0x8cFe668ed04B62dF79182C97c40ad49824433493;

    // LTV 配置
    uint256 constant WETH_LTV = 8000;
    uint256 constant WETH_LIQ_THRESHOLD = 8500;
    uint256 constant WETH_LIQ_BONUS = 10500;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n========== Setting Up Upgradeable Pool ==========");

        PoolUpgradeable pool = PoolUpgradeable(POOL_ADDRESS);
        PriceOracle oracle = PriceOracle(ORACLE_ADDRESS);

        // ========== 1. 部署 Mock 代币 ==========
        console.log("\n1. Deploying Mock Tokens...");
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH", 18);
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6);
        MockERC20 usdt = new MockERC20("Tether USD", "USDT", 6);
        console.log("WETH:", address(weth));
        console.log("USDC:", address(usdc));
        console.log("USDT:", address(usdt));

        // ========== 2. 部署 AToken ==========
        console.log("\n2. Deploying ATokens...");
        AToken aWETH = new AToken(POOL_ADDRESS, address(weth), "DEX Pro WETH", "dpWETH");
        AToken aUSDC = new AToken(POOL_ADDRESS, address(usdc), "DEX Pro USDC", "dpUSDC");
        AToken aUSDT = new AToken(POOL_ADDRESS, address(usdt), "DEX Pro USDT", "dpUSDT");
        console.log("aWETH:", address(aWETH));
        console.log("aUSDC:", address(aUSDC));
        console.log("aUSDT:", address(aUSDT));

        // ========== 3. 初始化储备 ==========
        console.log("\n3. Initializing Reserves...");
        pool.initReserve(address(weth), address(aWETH), WETH_LTV, WETH_LIQ_THRESHOLD, WETH_LIQ_BONUS);
        pool.initReserve(address(usdc), address(aUSDC), 7500, 8000, 10500);
        pool.initReserve(address(usdt), address(aUSDT), 7500, 8000, 10500);
        console.log("Reserves initialized");

        // ========== 4. 配置预言机价格 ==========
        console.log("\n4. Setting up Oracle prices...");

        // WETH 使用 Chainlink 真实喂价
        address[] memory assets1 = new address[](1);
        address[] memory sources1 = new address[](1);
        assets1[0] = address(weth);
        sources1[0] = ETH_USD_FEED;
        oracle.setAssetSources(assets1, sources1);
        console.log("WETH -> Chainlink ETH/USD feed");

        // USDC 和 USDT 使用 fallback 价格 $1
        oracle.setFallbackPrice(address(usdc), 1 * 10**8);
        oracle.setFallbackPrice(address(usdt), 1 * 10**8);
        console.log("USDC/USDT -> $1.00 fallback");

        // ========== 5. Mint 测试代币给部署者 ==========
        console.log("\n5. Minting test tokens...");
        weth.mint(deployer, 1000 * 10**18);
        usdc.mint(deployer, 1000000 * 10**6);
        usdt.mint(deployer, 1000000 * 10**6);
        console.log("Minted 1000 WETH, 1M USDC, 1M USDT");

        vm.stopBroadcast();

        // ========== 6. 验证配置 ==========
        console.log("\n========== Verification ==========");

        uint256 wethPrice = oracle.getAssetPrice(address(weth));
        uint256 usdcPrice = oracle.getAssetPrice(address(usdc));
        uint256 usdtPrice = oracle.getAssetPrice(address(usdt));

        console.log("\nPrices:");
        console.log("WETH:", uint256(wethPrice / 1e8), "USD");
        console.log("USDC:", uint256(usdcPrice / 1e8), "USD");
        console.log("USDT:", uint256(usdtPrice / 1e8), "USD");

        console.log("\n========== Configuration Summary ==========");
        console.log("Pool (Proxy):", POOL_ADDRESS);
        console.log("Oracle:", ORACLE_ADDRESS);
        console.log("WETH:", address(weth));
        console.log("USDC:", address(usdc));
        console.log("USDT:", address(usdt));
        console.log("\nUpdate frontend contracts.ts with:");
        console.log("POOL_ADDRESS =", POOL_ADDRESS);
    }
}
