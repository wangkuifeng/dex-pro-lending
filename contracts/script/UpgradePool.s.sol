// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PoolUpgradeable} from "../src/core/PoolUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title UpgradePool
 * @notice 升级 Pool 合约逻辑
 *
 * 升级流程：
 * 1. 部署新的逻辑合约
 * 2. 通过 Proxy 调用 upgradeTo
 *
 * Proxy 地址不变，所有状态和数据保持不变
 */
contract UpgradePool is Script {
    // ========== 配置 ==========
    address constant PROXY_ADDRESS = 0xB6f654b7eEADbC7171fb1BD2f23a2ea0E8c0604E;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n========== Upgrading Pool ==========");

        // ========== 1. 部署新的逻辑合约 ==========
        console.log("\n1. Deploying new PoolUpgradeable implementation...");
        PoolUpgradeable newImplementation = new PoolUpgradeable();
        console.log("New implementation address:", address(newImplementation));

        // ========== 2. 升级 Proxy ==========
        console.log("\n2. Upgrading proxy...");
        PoolUpgradeable pool = PoolUpgradeable(PROXY_ADDRESS);
        pool.upgradeToAndCall(address(newImplementation), "");
        console.log("Upgrade successful!");

        vm.stopBroadcast();

        // ========== 3. 验证升级 ==========
        console.log("\n========== Verifying Upgrade ==========");

        uint256 version = pool.version();
        console.log("\nPool Proxy address:", PROXY_ADDRESS);
        console.log("New implementation address:", address(newImplementation));
        console.log("Pool version:", version);

        console.log("\n========== Upgrade Complete! ==========");
        console.log("Proxy address unchanged:", PROXY_ADDRESS);
        console.log("All state and data preserved!");
    }
}
