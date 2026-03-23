// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataTypes} from "./DataTypes.sol";

library ReserveConfiguration {
    // 架构师优化：使用位移和取反自动生成安全的 Mask，杜绝硬编码引发的偏移 Bug
    // LTV 占据 bit 0-15
    uint256 constant LTV_MASK                   = ~(uint256(0xFFFF));
    // Liquidation Threshold 占据 bit 16-31
    uint256 constant LIQUIDATION_THRESHOLD_MASK = ~(uint256(0xFFFF) << 16);
    // Liquidation Bonus 占据 bit 32-47
    uint256 constant LIQUIDATION_BONUS_MASK     = ~(uint256(0xFFFF) << 32);

    function setLtv(DataTypes.ReserveData storage reserve, uint256 ltv) internal {
        require(ltv <= 10000, "INVALID_LTV");
        reserve.configuration = (reserve.configuration & LTV_MASK) | ltv;
    }

    function getLtv(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
        return reserve.configuration & ~LTV_MASK;
    }

    function setLiquidationThreshold(DataTypes.ReserveData storage reserve, uint256 threshold) internal {
        require(threshold <= 10000, "INVALID_LIQ_THRESHOLD");
        reserve.configuration = (reserve.configuration & LIQUIDATION_THRESHOLD_MASK) | (threshold << 16);
    }

    function getLiquidationThreshold(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
        return (reserve.configuration & ~LIQUIDATION_THRESHOLD_MASK) >> 16;
    }

    function setLiquidationBonus(DataTypes.ReserveData storage reserve, uint256 bonus) internal {
        // 放宽限制：允许清算奖励系数超过 10000 (如 10500 代表 5% 奖励)
        require(bonus <= 20000, "INVALID_LIQ_BONUS");
        reserve.configuration = (reserve.configuration & LIQUIDATION_BONUS_MASK) | (bonus << 32);
    }

    function getLiquidationBonus(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
        return (reserve.configuration & ~LIQUIDATION_BONUS_MASK) >> 32;
    }
}