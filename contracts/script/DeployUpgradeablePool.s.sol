// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {PoolUpgradeable} from "../src/core/PoolUpgradeable.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";

/**
 * @title DeployUpgradeablePool
 * @notice 部署可升级的 Pool 合约
 *
 * 部署流程：
 * 1. 部署逻辑合约 (PoolUpgradeable)
 * 2. 部署 ERC1967 Proxy
 * 3. 通过 Proxy 调用 initialize
 *
 * Proxy 地址保持不变，逻辑合约可以升级
 */
contract DeployUpgradeablePool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n========== Deploying Upgradeable Pool ==========");

        // ========== 1. 部署逻辑合约 ==========
        console.log("\n1. Deploying PoolUpgradeable implementation...");
        PoolUpgradeable implementation = new PoolUpgradeable();
        console.log("Implementation address:", address(implementation));

        // ========== 2. 部署预言机（如果还没有）==========
        console.log("\n2. Deploying PriceOracle...");
        PriceOracle oracle = new PriceOracle();
        console.log("Oracle address:", address(oracle));

        // ========== 3. 部署 Proxy ==========
        console.log("\n3. Deploying ERC1967 Proxy...");

        // 编码 initialize 函数调用数据
        bytes memory initData = abi.encodeWithSelector(
            PoolUpgradeable.initialize.selector,
            address(oracle), // oracle
            deployer         // owner
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation), // logic
            initData                  // data
        );
        console.log("Proxy address (THIS IS YOUR POOL ADDRESS):", address(proxy));

        vm.stopBroadcast();

        // ========== 4. 验证部署 ==========
        console.log("\n========== Verifying Deployment ==========");

        PoolUpgradeable pool = PoolUpgradeable(address(proxy));
        address oracleAddr = pool.oracle();
        uint256 version = pool.version();

        console.log("\nPool Proxy address:", address(proxy));
        console.log("Pool Implementation address:", address(implementation));
        console.log("Oracle address:", oracleAddr);
        console.log("Pool version:", version);

        console.log("\n========== Deployment Summary ==========");
        console.log("Update your frontend with:");
        console.log("POOL_ADDRESS =", address(proxy));
        console.log("PRICE_ORACLE_ADDRESS =", address(oracle));
    }
}
