// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";
import {PoolUpgradeable} from "../src/core/PoolUpgradeable.sol";

/**
 * @title SetupUpgradeablePoolPart2
 * @notice 完成剩余配置（预言机价格、储备初始化）
 */
contract SetupUpgradeablePoolPart2 is Script {
    // Chainlink 真实喂价
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    // 已部署合约
    address constant POOL_ADDRESS = 0xe5ED95744b5a5987CBFd06827BC194F4664cC680;
    address constant ORACLE_ADDRESS = 0x8cFe668ed04B62dF79182C97c40ad49824433493;

    // Mock 代币
    address constant WETH = 0x94249A6B20E2b6B30C2e059E921Cf110B0d48E40;
    address constant USDC = 0x98fB8e836Ee1b62420EF3Fd634f69EC677fc49bd;
    address constant USDT = 0xfe012B9C851435D1E0303f63E7455CaA0A9a2e52;

    // AToken (使用正确的 checksum)
    address constant aWETH = 0x00A7CD9441e8ec2bF65582569d7f5e9f45A9dF22;
    address constant aUSDC = 0x95DDA02446c37490480b66350Aba4769097FdD7b;
    address constant aUSDT = 0xe395ea3d0cb286cA11204C7367ADA1C5a5F823FB;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n========== Completing Setup ==========");

        PriceOracle oracle = PriceOracle(ORACLE_ADDRESS);
        PoolUpgradeable pool = PoolUpgradeable(POOL_ADDRESS);

        // ========== 1. 配置预言机 ==========
        console.log("\n1. Setting Oracle prices...");

        address[] memory assets = new address[](3);
        address[] memory sources = new address[](3);
        assets[0] = WETH; sources[0] = ETH_USD_FEED;
        assets[1] = USDC; sources[1] = address(0); // 使用 fallback
        assets[2] = USDT; sources[2] = address(0); // 使用 fallback

        oracle.setAssetSources(assets, sources);
        console.log("Set WETH -> Chainlink feed");

        oracle.setFallbackPrice(USDC, 1 * 10**8);
        oracle.setFallbackPrice(USDT, 1 * 10**8);
        console.log("Set USDC/USDT -> $1.00");

        // ========== 2. 初始化储备 ==========
        console.log("\n2. Initializing reserves...");

        pool.initReserve(WETH, aWETH, 8000, 8500, 10500);
        pool.initReserve(USDC, aUSDC, 7500, 8000, 10500);
        pool.initReserve(USDT, aUSDT, 7500, 8000, 10500);
        console.log("Reserves initialized");

        vm.stopBroadcast();

        // ========== 3. 验证 ==========
        console.log("\n========== Verification ==========");

        uint256 wethPrice = oracle.getAssetPrice(WETH);
        uint256 usdcPrice = oracle.getAssetPrice(USDC);
        uint256 usdtPrice = oracle.getAssetPrice(USDT);

        console.log("\nPrices (USD):");
        console.log("WETH:", uint256(wethPrice / 1e8));
        console.log("USDC:", uint256(usdcPrice / 1e8));
        console.log("USDT:", uint256(usdtPrice / 1e8));

        console.log("\n========== Done! ==========");
    }
}
