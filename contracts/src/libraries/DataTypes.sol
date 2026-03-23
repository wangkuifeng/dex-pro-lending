// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library DataTypes {
    /**
     * @dev 核心资产池状态数据
     * 使用 uint128 等较小的数据类型，利用 Solidity 的插槽打包(Slot Packing)机制降低 Gas
     */
    struct ReserveData {
        // bitmask: 包含 LTV, 借款启用状态, 清算阈值等配置 (Day 22 隔离模式也会用到)
        uint256 configuration;
        
        // 流动性指数与借款指数
        uint128 liquidityIndex;
        uint128 currentLiquidityRate;
        uint128 variableBorrowIndex;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        
        uint40 lastUpdateTimestamp;
        uint16 id; // 资产池的内部 ID
        
        // 相关 Token 地址
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        
        // 财库收入与未支持的债务
        uint128 accruedToTreasury;
        uint128 unbacked;
        uint128 isolationModeTotalDebt;
    }

    /**
     * @dev 用户配置位图
     * 每个位(bit)代表一个特定的状态（如：针对 reserve ID 1，是否将其作为抵押品）
     */
    struct UserConfigurationMap {
        uint256 data; 
    }
}