// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PoolUpgradeable} from "../src/core/PoolUpgradeable.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/**
 * @title TestSupply
 * @notice 为用户做 supply 测试，使用部署者的代币
 */
contract TestSupply is Script {
    // 可升级 Pool 合约地址
    address constant POOL_ADDRESS = 0xe5ED95744b5a5987CBFd06827BC194F4664cC680;

    // 新的 Mock 代币地址
    address constant WETH_ADDRESS = 0x94249A6B20E2b6B30C2e059E921Cf110B0d48E40;
    address constant USDC_ADDRESS = 0x98fB8e836Ee1b62420EF3Fd634f69EC677fc49bd;

    // 测试用户地址
    address constant TEST_USER = 0x799416951eA1b21Fc1306e172d2E018b11787379;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        PoolUpgradeable pool = PoolUpgradeable(POOL_ADDRESS);
        MockERC20 weth = MockERC20(WETH_ADDRESS);
        MockERC20 usdc = MockERC20(USDC_ADDRESS);

        console.log("\n========== Test Supply for User ==========");
        console.log("Test User:", TEST_USER);
        console.log("Deployer:", deployer);

        // ========== 1. Mint 代币给部署者 ==========
        console.log("\nMinting tokens to deployer...");
        weth.mint(deployer, 100 * 10**18);
        usdc.mint(deployer, 100000 * 10**6);
        console.log("Minted 100 WETH and 100k USDC to deployer");

        // ========== 2. 授权 Pool ==========
        console.log("\nApproving Pool...");
        weth.approve(POOL_ADDRESS, type(uint256).max);
        usdc.approve(POOL_ADDRESS, type(uint256).max);
        console.log("Approved");

        // ========== 3. Supply WETH 到 Pool 给用户 ==========
        console.log("\nSupplying 5 WETH for user...");
        pool.supply(WETH_ADDRESS, 5 * 10**18, TEST_USER, 0);
        console.log("Supplied 5 WETH");

        // ========== 4. Supply USDC 到 Pool 给用户 ==========
        console.log("\nSupplying 10000 USDC for user...");
        pool.supply(USDC_ADDRESS, 10000 * 10**6, TEST_USER, 0);
        console.log("Supplied 10000 USDC");

        vm.stopBroadcast();

        // ========== 5. 验证用户数据 ==========
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
