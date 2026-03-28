// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IAToken} from "../interfaces/IAToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title PoolUpgradeable
 * @notice UUPS 可升级版本的 Pool 合约
 *
 * 升级路径：
 * 1. 部署逻辑合约 (PoolUpgradeable)
 * 2. 部署 ERC1967 Proxy
 * 3. 通过 Proxy 调用 initialize
 * 4. 升级时部署新逻辑合约，调用 upgradeTo
 */
contract PoolUpgradeable is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    // ========== 状态变量 ==========

    // 映射：���产地址 -> 储备数据
    mapping(address => DataTypes.ReserveData) internal _reserves;

    // 映射：用户地址 -> 用户配置
    mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

    // 预言机地址
    IPriceOracle internal _priceOracle;

    // 最大数量储备
    uint16 internal constant MAX_NUMBER_RESERVES = 128;

    // ========== 事件 ==========

    event ReserveInitialized(address indexed asset, address aToken);
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
    event Supply(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount);
    event Withdraw(address indexed reserve, address user, address indexed to, uint256 amount);
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate
    );
    event Repay(address indexed reserve, address user, address indexed repayer, uint256 amount);
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator
    );

    /// @notice 自定义错误
    error Errors_InvalidCaller();
    error Errors_InvalidPriceOracle();
    error Errors_InvalidConfiguration();
    error Errors_InvalidAmount();
    error Errors_NoCollateral();
    error Errors_InsufficientCollateral();

    /// @notice 构造函数 - 禁用，使用 initialize
    constructor() {
        _disableInitializers();
    }

    /// @notice 初始化函数（替代构造函数）
    /// @param oracle_ 预言机地址
    /// @param owner_ 合约所有者
    function initialize(address oracle_, address owner_) public initializer {
        __Ownable_init(owner_);

        require(oracle_ != address(0), "Invalid oracle");
        _priceOracle = IPriceOracle(oracle_);
    }

    // ========== 版本号（用于升级验证）==========
    function version() external pure returns (uint256) {
        return 1;
    }

    // ========== UUPS 升级授权 ==========

    /// @notice 授权升级函数（只有 owner 可以升级）
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ========== 核心功能（与原 Pool 合约保持一致）==========

    /// @notice 设置预言机
    function setOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle");
        _priceOracle = IPriceOracle(newOracle);
    }

    /// @notice 获取预言机地址
    function oracle() external view returns (address) {
        return address(_priceOracle);
    }

    /// @notice 初始化储备
    function initReserve(
        address asset,
        address aTokenAddress,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external onlyOwner {
        require(asset != address(0), "Invalid asset");
        require(aTokenAddress != address(0), "Invalid aToken");
        require(_reserves[asset].aTokenAddress == address(0), "Reserve already initialized");

        // 简化配置：使用位图存储配置
        uint256 configuration = (ltv << 0) | (liquidationThreshold << 16) | (liquidationBonus << 32);

        _reserves[asset] = DataTypes.ReserveData({
            configuration: configuration,
            liquidityIndex: 1e27,
            currentLiquidityRate: 0,
            variableBorrowIndex: 1e27,
            currentVariableBorrowRate: 0,
            currentStableBorrowRate: 0,
            lastUpdateTimestamp: uint40(block.timestamp),
            id: uint16(0), // 简化：不使用递增 ID
            aTokenAddress: aTokenAddress,
            stableDebtTokenAddress: address(0),
            variableDebtTokenAddress: address(0),
            interestRateStrategyAddress: address(0),
            accruedToTreasury: 0,
            unbacked: 0,
            isolationModeTotalDebt: 0
        });

        emit ReserveInitialized(asset, aTokenAddress);
    }

    /// @notice 存款
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        require(amount > 0, "Invalid amount");
        require(onBehalfOf != address(0), "Invalid onBehalfOf");

        DataTypes.ReserveData storage reserve = _reserves[asset];
        require(reserve.id != 0 || reserve.aTokenAddress != address(0), "Reserve not initialized");

        // 1. 先从用户转移底层资产到 AToken 合约
        IERC20(asset).safeTransferFrom(msg.sender, reserve.aTokenAddress, amount);

        // 2. 铸造 aToken 给用户
        IAToken(reserve.aTokenAddress).mint(msg.sender, onBehalfOf, amount, 1e27);

        emit Supply(asset, msg.sender, onBehalfOf, amount);
    }

    /// @notice 取款
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(to != address(0), "Invalid to");

        DataTypes.ReserveData storage reserve = _reserves[asset];
        require(reserve.id != 0 || reserve.aTokenAddress != address(0), "Reserve not initialized");

        uint256 userBalance = IERC20(reserve.aTokenAddress).balanceOf(msg.sender);
        uint256 amountToWithdraw = amount == type(uint256).max ? userBalance : amount;
        require(amountToWithdraw <= userBalance, "Insufficient balance");

        IAToken(reserve.aTokenAddress).burn(msg.sender, to, amountToWithdraw, 1e27);

        emit Withdraw(asset, msg.sender, to, amountToWithdraw);
        return amountToWithdraw;
    }

    /// @notice 获取用户账户数据
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
        )
    {
        totalCollateralBase = 0;
        totalDebtBase = 0;
        uint256 weightedLiquidationThreshold = 0;

        // 已知的资产地址和对应精度 (Sepolia 测试网)
        // WETH: 18 位, USDC: 6 位, USDT: 6 位
        address[3] memory knownAssets = [
            0x94249A6B20E2b6B30C2e059E921Cf110B0d48E40, // WETH
            0x98fB8e836Ee1b62420EF3Fd634f69EC677fc49bd, // USDC
            0xfe012B9C851435D1E0303f63E7455CaA0A9a2e52  // USDT
        ];

        // 遍历所有已知资产
        for (uint256 i = 0; i < knownAssets.length; i++) {
            address asset = knownAssets[i];
            DataTypes.ReserveData storage reserve = _reserves[asset];

            // 检查 aToken 地址是否有效
            if (reserve.aTokenAddress == address(0)) continue;

            // 获取用户的 aToken 余额
            uint256 userBalance = IERC20(reserve.aTokenAddress).balanceOf(user);
            if (userBalance == 0) continue;

            // 获取资产价格 (Chainlink 8 位精度)
            uint256 assetPrice = _priceOracle.getAssetPrice(asset);
            if (assetPrice == 0) continue;

            // 解析配置
            uint256 reserveLiquidationThreshold = (reserve.configuration >> 16) & 0xFFFF;

            // 计算抵押品价值 (USD, 8 位精度)
            // 需要根据代币精度调整: price (8 位) * balance / 10^decimals = USD (8 位)
            uint256 collateralValue;
            if (i == 0) {
                // WETH: 18 位精度
                collateralValue = (userBalance * assetPrice) / 1e18;
            } else {
                // USDC/USDT: 6 位精度
                collateralValue = (userBalance * assetPrice) / 1e6;
            }
            totalCollateralBase += collateralValue;

            // 累加权清算阈值
            weightedLiquidationThreshold += (collateralValue * reserveLiquidationThreshold) / 10000;
        }

        // 如果没有债务，健康因子为无穷大
        if (totalDebtBase == 0) {
            healthFactor = type(uint256).max;
        } else {
            // 健康因子 = (总抵押品 * 加权清算阈值) / 总债务
            if (weightedLiquidationThreshold >= totalDebtBase) {
                healthFactor = (weightedLiquidationThreshold * 1e18) / totalDebtBase;
            } else {
                healthFactor = 0;
            }
        }

        // 可借金额 = 总抵押品 * LTV / 10000 - 总债务
        // 简化：使用平均 LTV
        if (totalCollateralBase > 0) {
            uint256 avgLtv = 7500; // 简化：假设 75% 平均 LTV
            availableBorrowsBase = (totalCollateralBase * avgLtv) / 10000 - totalDebtBase;
        }

        currentLiquidationThreshold = weightedLiquidationThreshold > 0 && totalCollateralBase > 0
            ? (weightedLiquidationThreshold * 10000) / totalCollateralBase
            : 0;
        ltv = 7500; // 简化：返回固定 LTV
    }

    /// @notice 获取储备数据
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory) {
        return _reserves[asset];
    }
}
