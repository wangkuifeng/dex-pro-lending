// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Pool} from "../src/core/Pool.sol";
import {AToken} from "../src/core/AToken.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";
import {MockV3Aggregator} from "../src/mocks/MockV3Aggregator.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract LiquidationTest is Test {
    Pool public pool;
    PriceOracle public oracle;
    
    MockERC20 public weth;
    MockERC20 public usdc;
    AToken public aWeth;
    AToken public aUsdc;

    MockV3Aggregator public wethOracle;
    MockV3Aggregator public usdcOracle;

    address public alice = makeAddr("Alice"); // 倒霉的借款人
    address public bob = makeAddr("Bob");     // 敏锐的清算者
    address public liquidityProvider = makeAddr("LP");

    function setUp() public {
        pool = new Pool();
        oracle = new PriceOracle();
        pool.setOracle(address(oracle));

        weth = new MockERC20("WETH", "WETH", 18);
        usdc = new MockERC20("USDC", "USDC", 18);

        aWeth = new AToken(address(pool), address(weth), "aWETH", "aWETH");
        aUsdc = new AToken(address(pool), address(usdc), "aUSDC", "aUSDC");

        // 初始价格: WETH = 3000 USD, USDC = 1 USD
        wethOracle = new MockV3Aggregator(8, 3000 * 10**8);
        usdcOracle = new MockV3Aggregator(8, 1 * 10**8);
        
        address[] memory assets = new address[](2);
        assets[0] = address(weth);
        assets[1] = address(usdc);
        address[] memory sources = new address[](2);
        sources[0] = address(wethOracle);
        sources[1] = address(usdcOracle);
        oracle.setAssetSources(assets, sources);

        // 初始化 Reserve (关键升级: 加上了第 5 个参数 Liquidation Bonus = 10500, 即 5% 奖励)
        // WETH: LTV 80%, LiqThreshold 85%, Bonus 5%
        pool.initReserve(address(weth), address(aWeth), 8000, 8500, 10500);
        // USDC: LTV 80%, LiqThreshold 85%, Bonus 0% (稳定币一般没有清算奖励)
        pool.initReserve(address(usdc), address(aUsdc), 8000, 8500, 10000);

        // 发放初始资金
        weth.mint(alice, 10 ether);
        usdc.mint(bob, 10000 ether); // 给 Bob 准备弹药用于清算
        usdc.mint(liquidityProvider, 100000 ether);
        
        // LP 提供 USDC 流动性
        vm.startPrank(liquidityProvider);
        usdc.approve(address(pool), 100000 ether);
        pool.supply(address(usdc), 100000 ether, liquidityProvider, 0);
        vm.stopPrank();
    }

    function test_LiquidationCall_Success() public {
        // ==========================================
        // 1. Alice 正常借款
        // ==========================================
        vm.startPrank(alice);
        weth.approve(address(pool), 1 ether);
        pool.supply(address(weth), 1 ether, alice, 0); // Alice 存入 1 WETH
        
        uint256 borrowAmount = 2000 ether; 
        pool.borrow(address(usdc), borrowAmount, 1, 0, alice); // 借出 2000 USDC
        vm.stopPrank();

        // 借款后，HF = (3000 * 0.85) / 2000 = 1.275 (安全)
        (,,,,,uint256 hfBefore) = pool.getUserAccountData(alice);
        assertEq(hfBefore, 1275000000000000000, "HF should be 1.275");

        // ==========================================
        // 2. 市场闪崩 (WETH 从 3000 跌到 2000)
        // ==========================================
        wethOracle.updateAnswer(2000 * 10**8);

        // 崩盘后，HF = (2000 * 0.85) / 2000 = 0.85 (资不抵债，触发清算)
        (,,,,,uint256 hfAfter) = pool.getUserAccountData(alice);
        assertEq(hfAfter, 850000000000000000, "HF should drop to 0.85");

        // ==========================================
        // 3. Bob 发起清算 (代还 1000 USDC 债务)
        // ==========================================
        uint256 debtToCover = 1000 ether;
        
        // 计算预期清算收益:
        // 代还 1000 USDC (价值 1000 USD)
        // 加上 5% 奖励 = 1050 USD 的 WETH
        // 当前 WETH 价格为 2000 USD
        // 预期拿到 WETH: 1050 / 2000 = 0.525 WETH
        uint256 expectedWethReward = 0.525 ether;

        uint256 bobWethBalanceBefore = weth.balanceOf(bob);
        uint256 aliceAWethBalanceBefore = aWeth.balanceOf(alice);

        vm.startPrank(bob);
        usdc.approve(address(pool), debtToCover);
        // 执行清算：参数(抵押资产, 债务资产, 被清算人, 代还金额, 接收aToken(否))
        pool.liquidationCall(address(weth), address(usdc), alice, debtToCover, false);
        vm.stopPrank();

        // ==========================================
        // 4. 验证资产转移是否精确无误
        // ==========================================
        uint256 bobWethBalanceAfter = weth.balanceOf(bob);
        uint256 aliceAWethBalanceAfter = aWeth.balanceOf(alice);

        // 验证 1: Bob 收到了打了折的 WETH
        assertEq(bobWethBalanceAfter - bobWethBalanceBefore, expectedWethReward, "Bob should receive exact WETH reward");
        
        // 验证 2: Alice 的 aWETH 抵押凭证被相应扣除
        assertEq(aliceAWethBalanceBefore - aliceAWethBalanceAfter, expectedWethReward, "Alice should lose exact aWETH");
        
        // 验证 3: Alice 的债务减轻了 1000 USDC
        (,uint256 aliceDebtAfter,,,,) = pool.getUserAccountData(alice);
        assertEq(aliceDebtAfter, (2000 - 1000) * 10**8, "Alice debt should be reduced by 1000 USD");
    }

    // 测试如果没跌破 1.0 就强行清算，系统必须拦截
    function test_RevertIf_HealthFactorNotBelow1() public {
        vm.startPrank(alice);
        weth.approve(address(pool), 1 ether);
        pool.supply(address(weth), 1 ether, alice, 0);
        pool.borrow(address(usdc), 2000 ether, 1, 0, alice);
        vm.stopPrank();

        // WETH 价格没变，HF = 1.275，不允许清算
        vm.startPrank(bob);
        usdc.approve(address(pool), 1000 ether);
        
        vm.expectRevert("HEALTH_FACTOR_NOT_BELOW_1");
        pool.liquidationCall(address(weth), address(usdc), alice, 1000 ether, false);
        vm.stopPrank();
    }
}