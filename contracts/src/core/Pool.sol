pragma solidity ^0.8.20;

import {IPool} from "../interfaces/IPool.sol";
import {IAToken} from "../interfaces/IAToken.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {ReserveConfiguration} from "../libraries/ReserveConfiguration.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Pool is IPool {
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveData;

    mapping(address => DataTypes.ReserveData) private _reserves;
    // Phase 1 简易账本：记录 用户 => 资产 => 借款数量
    mapping(address => mapping(address => uint256)) private _usersDebt;
    
    // 维护一个支持的资产列表，方便遍历计算总价值
    address[] private _reservesList;

    IPriceOracle public oracle;

    function setOracle(address _oracle) external {
        oracle = IPriceOracle(_oracle);
    }

    // 后门函数：注册资产并设置 LTV (如 8000 = 80%) 和 清算阈值 (如 8500 = 85%)
    function initReserve(address asset, address aTokenAddress, uint256 ltv, uint256 liqThreshold) external {
        if (_reserves[asset].aTokenAddress == address(0)) {
            _reservesList.push(asset);
        }
        _reserves[asset].aTokenAddress = aTokenAddress;
        _reserves[asset].setLtv(ltv);
        _reserves[asset].setLiquidationThreshold(liqThreshold);
    }

    /**
     * @inheritdoc IPool
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 /* referralCode */  // 修改这里 (原本是 uint16 referralCode)
    ) external override {
        // 1. Checks (校验)
        require(amount > 0, "INVALID_AMOUNT");
        DataTypes.ReserveData storage reserve = _reserves[asset];
        require(reserve.aTokenAddress != address(0), "ASSET_NOT_LISTED");

        // 2. Effects (状态更新)
        // TODO: Day 4/5 将在这里调用 updateState(asset, reserve) 更新借贷利率和流动性指数
        uint256 currentLiquidityIndex = reserve.liquidityIndex == 0 ? 1e27 : reserve.liquidityIndex;

        // 3. Interactions (外部交互)
        // 注意：底层资产被直接 transfer 到 aToken 合约中，而不是留在 Pool 里
        IERC20(asset).safeTransferFrom(msg.sender, reserve.aTokenAddress, amount);

        // 调用 aToken 铸造凭证给 onBehalfOf
        IAToken(reserve.aTokenAddress).mint(msg.sender, onBehalfOf, amount, currentLiquidityIndex);
    }

   /**
     * @inheritdoc IPool
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external override returns (uint256) {
        DataTypes.ReserveData storage reserve = _reserves[asset];
        require(reserve.aTokenAddress != address(0), "ASSET_NOT_LISTED");

        // 1. 获取用户的 aToken 余额 (后续会包含累加利息)
        uint256 userBalance = IERC20(reserve.aTokenAddress).balanceOf(msg.sender);
        require(userBalance > 0, "NO_FUNDS_TO_WITHDRAW");

        // 2. 处理 type(uint256).max 的全额提取逻辑
        uint256 amountToWithdraw = amount;
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        require(amountToWithdraw <= userBalance, "NOT_ENOUGH_FUNDS");

        // TODO: Day 5 (借款逻辑) 在这里需要插入 ValidationLogic.validateWithdraw()
        // 核心校验：如果用户有借款，提取抵押物后，健康因子 (Health Factor) 不能低于 1.0

        // 3. Effects & Interactions: 调用 AToken 进行销毁和资金转账
        // AToken 的 burn 内部已经包含了底层资产的 safeTransfer
        uint256 currentLiquidityIndex = reserve.liquidityIndex == 0 ? 1e27 : reserve.liquidityIndex;
        IAToken(reserve.aTokenAddress).burn(msg.sender, to, amountToWithdraw, currentLiquidityIndex);

        // 4. 发送事件 (今天暂略，后续配合 Go Indexer 一起补全)
        // emit Withdraw(asset, msg.sender, to, amountToWithdraw);

        return amountToWithdraw;
    }
    
/**
     * @inheritdoc IPool
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 /* interestRateMode */,
        uint16 /* referralCode */,
        address onBehalfOf
    ) external override {
        require(amount > 0, "INVALID_AMOUNT");
        
        // 1. 获取借款人的账户健康状态
        (
            ,
            ,
            uint256 availableBorrowsBase,
            ,
            ,
            uint256 healthFactor
        ) = this.getUserAccountData(onBehalfOf);

        // 2. 校验能否借款
        require(availableBorrowsBase > 0, "NO_COLLATERAL");
        require(healthFactor > 1e18, "HEALTH_FACTOR_TOO_LOW");

        uint256 assetPrice = oracle.getAssetPrice(asset);
        //抹除代币本身的 18 位精度，保留预言机的 8 位 USD 精度
        uint256 amountInUsd = (amount * assetPrice) / (10 ** 18); 

        require(amountInUsd <= availableBorrowsBase, "BORROW_EXCEEDS_CAPACITY");

        // 3. Effects: 更新债务账本 (Phase 1 简易记账)
        _usersDebt[onBehalfOf][asset] += amount;

        // 4. Interactions: 从 AToken 放款给借款人
        DataTypes.ReserveData storage reserve = _reserves[asset];
        IAToken(reserve.aTokenAddress).transferUnderlyingTo(onBehalfOf, amount);
    }

    /**
     * @inheritdoc IPool
     */
    function getUserAccountData(address user)
        external
        view
        override
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
        {
        uint256 avgLtv = 0;
        uint256 avgLiquidationThreshold = 0;

        // 遍历所有资产，计算总抵押物 USD 价值和总债务 USD 价值
        for (uint256 i = 0; i < _reservesList.length; i++) {
            address asset = _reservesList[i];
            DataTypes.ReserveData storage reserve = _reserves[asset];
            
            uint256 assetPrice = oracle.getAssetPrice(asset);

            // 计算该资产的抵押价值
            if (reserve.aTokenAddress != address(0)) {
                uint256 aTokenBalance = IERC20(reserve.aTokenAddress).balanceOf(user);
                if (aTokenBalance > 0) {
                    uint256 collateralValue = (aTokenBalance * assetPrice) / (10 ** 18);
                    totalCollateralBase += collateralValue;
                    
                    avgLtv += collateralValue * reserve.getLtv();
                    avgLiquidationThreshold += collateralValue * reserve.getLiquidationThreshold();
                }
            }

            // 计算该资产的债务价值
            uint256 userDebt = _usersDebt[user][asset];
            if (userDebt > 0) {
                totalDebtBase += (userDebt * assetPrice) / (10 ** 18);
            }
        }

        if (totalCollateralBase > 0) {
            avgLtv /= totalCollateralBase;
            avgLiquidationThreshold /= totalCollateralBase;
        }

        availableBorrowsBase = (totalCollateralBase * avgLtv) / 10000;
        if (availableBorrowsBase > totalDebtBase) {
            availableBorrowsBase = availableBorrowsBase - totalDebtBase;
        } else {
            availableBorrowsBase = 0;
        }

        // 计算 Health Factor: (抵押物价值 * 清算阈值) / 债务价值
        if (totalDebtBase == 0) {
            healthFactor = type(uint256).max;
        } else {
            healthFactor = (totalCollateralBase * avgLiquidationThreshold * 1e18) / (totalDebtBase * 10000);
        }

        return (
            totalCollateralBase,
            totalDebtBase,
            availableBorrowsBase,
            avgLiquidationThreshold,
            avgLtv,
            healthFactor
        );
    }

    /**
     * @inheritdoc IPool
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 /* interestRateMode */,
        address onBehalfOf
    ) external override returns (uint256) {
        require(amount > 0, "INVALID_AMOUNT");
        
        uint256 userDebt = _usersDebt[onBehalfOf][asset];
        require(userDebt > 0, "NO_DEBT");

        // 处理全额还款
        uint256 paybackAmount = amount;
        if (amount == type(uint256).max) {
            paybackAmount = userDebt;
        }
        require(paybackAmount <= userDebt, "REPAY_EXCEEDS_DEBT");

        // Effects: 扣减债务账本
        _usersDebt[onBehalfOf][asset] -= paybackAmount;

        // Interactions: 将用户的底层资产还回到 AToken 合约中
        DataTypes.ReserveData storage reserve = _reserves[asset];
        IERC20(asset).safeTransferFrom(msg.sender, reserve.aTokenAddress, paybackAmount);

        return paybackAmount;
    }

    /**
     * @inheritdoc IPool
     */
    function getReserveData(address asset) external view override returns (DataTypes.ReserveData memory) {
        return _reserves[asset];
    }


    // 升级：初始化资产时带上清算奖励 (如 10500 = 5% bonus)
    function initReserve(address asset, address aTokenAddress, uint256 ltv, uint256 liqThreshold, uint256 liqBonus) external {
        if (_reserves[asset].aTokenAddress == address(0)) {
            _reservesList.push(asset);
        }
        _reserves[asset].aTokenAddress = aTokenAddress;
        _reserves[asset].setLtv(ltv);
        _reserves[asset].setLiquidationThreshold(liqThreshold);
        _reserves[asset].setLiquidationBonus(liqBonus);
    }

    /**
     * @inheritdoc IPool
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool /* receiveAToken */
    ) external override {
        // 1. 验证健康因子确实低于 1.0 (1e18)
        (,,,,, uint256 healthFactor) = this.getUserAccountData(user);
        require(healthFactor < 1e18, "HEALTH_FACTOR_NOT_BELOW_1");

        uint256 userDebt = _usersDebt[user][debtAsset];
        require(userDebt > 0, "USER_DOES_NOT_HAVE_DEBT");
        
        uint256 actualDebtToLiquidate = debtToCover > userDebt ? userDebt : debtToCover;

        // 2. 计算清算者可以拿走多少抵押物
        DataTypes.ReserveData storage collateralReserve = _reserves[collateralAsset];
        uint256 collateralPrice = oracle.getAssetPrice(collateralAsset);
        uint256 debtPrice = oracle.getAssetPrice(debtAsset);
        uint256 liquidationBonus = collateralReserve.getLiquidationBonus();

        // 核心公式：抵押物数量 = (代还债务数量 * 债务单价 * 清算奖励系数) / 抵押物单价
        // 注意：这里假设资产都是 18 位，所以直接消掉
        uint256 collateralToReceive = (actualDebtToLiquidate * debtPrice * liquidationBonus) / (collateralPrice * 10000);

        uint256 userCollateralBalance = IERC20(collateralReserve.aTokenAddress).balanceOf(user);
        require(userCollateralBalance >= collateralToReceive, "NOT_ENOUGH_COLLATERAL");

        // 3. Effects: 更新账本
        // 扣除用户的债务
        _usersDebt[user][debtAsset] -= actualDebtToLiquidate;

        // 4. Interactions: 执行资产交割
        // a. 销毁被清算人的 aToken (抵押物凭证)，并将底层资产转给清算者 (msg.sender)
        // 注意：这里调用我们在 Day 3 写的 aToken.burn()
        uint256 currentLiquidityIndex = 1e27; // Phase 1 先写死
        IAToken(collateralReserve.aTokenAddress).burn(user, msg.sender, collateralToReceive, currentLiquidityIndex);

        // b. 清算者把代还的债务资金，打回到债务资产的 aToken 合约里，补充流动性
        DataTypes.ReserveData storage debtReserve = _reserves[debtAsset];
        IERC20(debtAsset).safeTransferFrom(msg.sender, debtReserve.aTokenAddress, actualDebtToLiquidate);
    }
}