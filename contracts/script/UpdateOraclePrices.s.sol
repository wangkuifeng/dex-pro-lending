// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";

/**
 * @title UpdateOraclePrices
 * @notice Set Chainlink feeds and fallback prices for oracle
 *
 * Problem: Chainlink has no USDC/USD or USDT/USD feeds on Sepolia
 * Solution: Use real ETH/USD feed + stablecoin fallback prices ($1)
 */
contract UpdateOraclePrices is Script {
    // ========== Real Chainlink Feed Addresses (Sepolia) ==========
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    // ========== Deployed Contract Addresses ==========
    address constant ORACLE_ADDRESS = 0x4550C5C073719c7d876666d98Ec71f3f7EE4A4D6;
    address constant WETH_ADDRESS = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant USDC_ADDRESS = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant USDT_ADDRESS = 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        PriceOracle oracle = PriceOracle(ORACLE_ADDRESS);

        console.log("\n========== Updating Oracle Price Config ==========");

        // ========== 1. Set WETH to use Chainlink ETH/USD feed ==========
        console.log("Setting WETH Chainlink feed:", ETH_USD_FEED);
        address[] memory assets1 = new address[](1);
        address[] memory sources1 = new address[](1);
        assets1[0] = WETH_ADDRESS;
        sources1[0] = ETH_USD_FEED;
        oracle.setAssetSources(assets1, sources1);

        // ========== 2. Set USDC fallback price = $1.00 (8 decimals) ==========
        console.log("Setting USDC fallback price: $1.00");
        uint256 usdcPrice = 1 * 10**8; // $1.00, 8 decimals
        oracle.setFallbackPrice(USDC_ADDRESS, usdcPrice);

        // ========== 3. Set USDT fallback price = $1.00 (8 decimals) ==========
        console.log("Setting USDT fallback price: $1.00");
        uint256 usdtPrice = 1 * 10**8; // $1.00, 8 decimals
        oracle.setFallbackPrice(USDT_ADDRESS, usdtPrice);

        vm.stopBroadcast();

        // ========== 4. Verify prices ==========
        console.log("\n========== Verifying Price Settings ==========");

        uint256 wethPrice = oracle.getAssetPrice(WETH_ADDRESS);
        console.log("WETH price (USD, 8 decimals):", wethPrice);
        console.log("WETH price (USD):", uint256(wethPrice / 1e8), ".", uint256(wethPrice % 1e8));

        uint256 usdcPriceCheck = oracle.getAssetPrice(USDC_ADDRESS);
        console.log("USDC price (USD, 8 decimals):", usdcPriceCheck);
        console.log("USDC price (USD):", uint256(usdcPriceCheck / 1e8));

        uint256 usdtPriceCheck = oracle.getAssetPrice(USDT_ADDRESS);
        console.log("USDT price (USD, 8 decimals):", usdtPriceCheck);
        console.log("USDT price (USD):", uint256(usdtPriceCheck / 1e8));

        console.log("\n========== Price Update Complete! ==========");
    }
}
