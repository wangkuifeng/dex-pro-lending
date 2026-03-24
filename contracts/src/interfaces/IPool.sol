// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IPool {

    /* ========================================================================= */
    /* EVENTS                                     */
    /* ========================================================================= */

    /**
     * @notice 存款事件
     * @param reserve 底层资产地址
     * @param user 实际触发交易的用户
     * @param onBehalfOf 接收 aToken 的受益人地址
     * @param amount 存款金额
     * @param referralCode 推荐码
     */
    event Supply(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 referralCode);

    /**
     * @notice 提取事件
     * @param reserve 底层资产地址
     * @param user 触发提取的用户
     * @param to 接收底层资产的地址
     * @param amount 提取金额
     */
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @notice 借款事件
     * @param reserve 底层资产地址
     * @param user 触发借款的用户
     * @param onBehalfOf 实际承担债务的地址
     * @param amount 借款金额
     * @param interestRateMode 借款利率模式 (1 = 稳定, 2 = 浮动)
     * @param borrowRate 借款时的瞬间利率 (重要：供后端记录快照)
     * @param referralCode 推荐码
     */
    event Borrow(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint256 interestRateMode, uint256 borrowRate, uint16 referralCode);

    /**
     * @notice 还款事件
     * @param reserve 底层资产地址
     * @param user 实际被消除债务的地址 (onBehalfOf)
     * @param repayer 实际支付底层资产的地址 (msg.sender)
     * @param amount 还款金额
     */
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @notice 清算事件
     * @param collateralAsset 抵押物资产地址
     * @param debtAsset 债务资产地址
     * @param user 被清算的用户地址
     * @param debtToCover 清算者代还的债务数量
     * @param liquidatedCollateralAmount 被清算的抵押物数量 (含清算奖励)
     * @param liquidator 清算者地址
     * @param receiveAToken 是否直接接收 aToken
     */
    event LiquidationCall(address indexed collateralAsset, address indexed debtAsset, address indexed user, uint256 debtToCover, uint256 liquidatedCollateralAmount, address liquidator, bool receiveAToken);

    /* ========================================================================= */
    /* FUNCTIONS                                    */
    /* ========================================================================= */
    
    /**
     * @notice 向协议提供流动性（存款）
     * @param asset 底层资产地址 (如 WETH/USDC)
     * @param amount 存款金额
     * @param onBehalfOf 接收 aToken 的地址（通常是 msg.sender）
     * @param referralCode 推荐码（用于后期分润，默认为 0）
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice 从协议提取流动性
     * @param asset 底层资产地址
     * @param amount 提取金额 (如果为 type(uint256).max 则提取全部)
     * @param to 接收底层资产的地址
     * @return 实际提取的金额
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice 获取特定资产池的数据状态
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);


    // ... 保留之前的 supply, withdraw, getReserveData

    /**
     * @notice 借出指定资产
     * @param asset 想要借出的底层资产地址
     * @param amount 借款数量
     * @param interestRateMode 借款利率模式 (1 = 稳定利率, 2 = 浮动利率)
     * @param referralCode 推荐码
     * @param onBehalfOf 承担这笔债务的地址
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice 偿还借款
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice 获取用户的全局账户数据（计算健康因子必备）
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice 清算处于不健康状态的头寸
     * @param collateralAsset 抵押物资产地址 (清算者想拿走的资产)
     * @param debtAsset 债务资产地址 (清算者要代还的资产)
     * @param user 被清算的用户地址
     * @param debtToCover 清算者打算代还的债务数量
     * @param receiveAToken 是否直接接收 aToken (今天先传 false，直接拿底层资产)
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;    
}