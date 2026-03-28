// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PoolUpgradeable} from "../src/core/PoolUpgradeable.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";

/**
 * @title DebugSupply
 * @notice Debug supply function
 */
contract DebugSupply is Script {
    address constant POOL_ADDRESS = 0xe5ED95744b5a5987CBFd06827BC194F4664cC680;
    address constant WETH_ADDRESS = 0x94249A6B20E2b6B30C2e059E921Cf110B0d48E40;
    address constant TEST_USER = 0x799416951eA1b21Fc1306e172d2E018b11787379;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        PoolUpgradeable pool = PoolUpgradeable(POOL_ADDRESS);
        MockERC20 weth = MockERC20(WETH_ADDRESS);

        console.log("\n========== Debug Supply ==========");
        console.log("Deployer:", deployer);
        console.log("Test User:", TEST_USER);

        // 1. 检查用户余额
        uint256 userBalance = weth.balanceOf(TEST_USER);
        console.log("User WETH balance:", userBalance);

        // 2. Mint 给用户如果余额不足
        if (userBalance < 1 * 10**18) {
            console.log("Minting 10 WETH to user...");
            weth.mint(TEST_USER, 10 * 10**18);
        }

        // 3. 用户授权 Pool
        console.log("\nUser approving Pool...");
        vm.prank(TEST_USER);
        weth.approve(POOL_ADDRESS, type(uint256).max);

        // 4. 检查授权额度
        uint256 allowance = weth.allowance(TEST_USER, POOL_ADDRESS);
        console.log("Allowance:", allowance);

        // 5. 检查储备数据
        console.log("\nChecking reserve data...");
        try pool.getReserveData(WETH_ADDRESS) returns (DataTypes.ReserveData memory reserveData) {
            console.log("Reserve found!");
            console.log("aToken address:", reserveData.aTokenAddress);
            console.log("ID:", reserveData.id);
        } catch {
            console.log("Reserve NOT initialized!");
        }

        // 6. 尝试 Supply 1 WETH
        console.log("\nAttempting to supply 1 WETH...");
        vm.prank(TEST_USER);
        try pool.supply(WETH_ADDRESS, 1 * 10**18, TEST_USER, 0) {
            console.log("Supply SUCCESS!");
        } catch (bytes memory reason) {
            console.log("Supply FAILED!");
            console.log("Reason:", string(reason));
        }

        vm.stopBroadcast();
    }
}
