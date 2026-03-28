// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {PoolUpgradeable} from "../src/core/PoolUpgradeable.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";

/**
 * @title CheckReserves
 * @notice Check all reserves in the Pool
 */
contract CheckReserves is Script {
    address constant POOL_ADDRESS = 0xe5ED95744b5a5987CBFd06827BC194F4664cC680;

    function run() external {
        PoolUpgradeable pool = PoolUpgradeable(POOL_ADDRESS);

        console.log("\n========== Checking Reserves ==========");

        address[] memory assets = new address[](3);
        assets[0] = 0x94249A6B20E2b6B30C2e059E921Cf110B0d48E40; // WETH
        assets[1] = 0x98fB8e836Ee1b62420EF3Fd634f69EC677fc49bd; // USDC
        assets[2] = 0xfe012B9C851435D1E0303f63E7455CaA0A9a2e52; // USDT

        for (uint i = 0; i < assets.length; i++) {
            console.log("\n--- Asset", i, "---");
            console.log("Address:", assets[i]);

            DataTypes.ReserveData memory reserve = pool.getReserveData(assets[i]);
            console.log("aToken:", reserve.aTokenAddress);
            console.log("ID:", reserve.id);
            console.log("Config:", reserve.configuration);
        }
    }
}
