// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Pool} from "../src/core/Pool.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/**
 * @title TestSupply
 * @notice Do supply for user using deployer's tokens
 */
contract TestSupply is Script {
    address constant POOL_ADDRESS = 0xB6f654b7eEADbC7171fb1BD2f23a2ea0E8c0604E;
    address constant WETH_ADDRESS = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant TEST_USER = 0x799416951eA1b21Fc1306e172d2E018b11787379;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        Pool pool = Pool(POOL_ADDRESS);
        MockERC20 weth = MockERC20(WETH_ADDRESS);

        console.log("\n========== Test Supply for User ==========");
        console.log("Test User:", TEST_USER);
        console.log("Deployer:", deployer);

        // ========== 1. Mint WETH to deployer ==========
        console.log("\nMinting WETH to deployer...");
        weth.mint(deployer, 100 * 10**18);
        console.log("Minted 100 WETH to deployer");

        // ========== 2. Approve Pool ==========
        console.log("\nApproving Pool...");
        weth.approve(POOL_ADDRESS, type(uint256).max);
        console.log("Approved");

        // ========== 3. Supply WETH to Pool for user ==========
        console.log("\nSupplying 5 WETH for user...");
        pool.supply(WETH_ADDRESS, 5 * 10**18, TEST_USER, 0);
        console.log("Supplied 5 WETH");

        vm.stopBroadcast();

        // ========== 4. Verify user data ==========
        console.log("\n========== Verifying User Account Data ==========");

        (uint256 totalCollateralBase,
         uint256 totalDebtBase,
         ,
         ,
         ,
         uint256 healthFactor) = pool.getUserAccountData(TEST_USER);

        console.log("Total Collateral (USD):", uint256(totalCollateralBase / 1e8));
        console.log("Total Debt (USD):", uint256(totalDebtBase / 1e8));
        console.log("Health Factor:", healthFactor);

        console.log("\n========== Done! Refresh your frontend! ==========");
    }
}
