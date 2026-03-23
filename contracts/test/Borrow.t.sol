// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Pool} from "../src/core/Pool.sol";
import {AToken} from "../src/core/AToken.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";
import {MockV3Aggregator} from "../src/mocks/MockV3Aggregator.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract BorrowTest is Test {
    Pool public pool;
    PriceOracle public oracle;
    
    MockERC20 public weth;
    MockERC20 public usdc;
    AToken public aWeth;
    AToken public aUsdc;

    MockV3Aggregator public wethOracle;
    MockV3Aggregator public usdcOracle;

    address public alice = makeAddr("Alice");
    address public liquidityProvider = makeAddr("LP");

    function setUp() public {
        pool = new Pool();
        oracle = new PriceOracle();
        pool.setOracle(address(oracle));

        // 部署资产 (全用 18 位精度方便计算)
        weth = new MockERC20("WETH", "WETH", 18);
        usdc = new MockERC20("USDC", "USDC", 18);

        aWeth = new AToken(address(pool), address(weth), "aWETH", "aWETH");
        aUsdc = new AToken(address(pool), address(usdc), "aUSDC", "aUSDC");

        // 配置预言机 (WETH = 3000 USD, USDC = 1 USD，精度统一 8 位)
        wethOracle = new MockV3Aggregator(8, 3000 * 10**8);
        usdcOracle = new MockV3Aggregator(8, 1 * 10**8);
        
        address[] memory assets = new address[](2);
        assets[0] = address(weth);
        assets[1] = address(usdc);
        address[] memory sources = new address[](2);
        sources[0] = address(wethOracle);
        sources[1] = address(usdcOracle);
        oracle.setAssetSources(assets, sources);

        // 注册资产到 Pool (WETH: LTV 80%, 清算阈值 85% | USDC: LTV 80%, 清算阈值 85%)
        pool.initReserve(address(weth), address(aWeth), 8000, 8500);
        pool.initReserve(address(usdc), address(aUsdc), 8000, 8500);

        // 给测试用户发钱
        weth.mint(alice, 10 ether);
        usdc.mint(liquidityProvider, 100000 ether); // LP 提供充足的 USDC 流动性
        
        // LP 存入 100,000 USDC 作为池子的放贷本金
        vm.startPrank(liquidityProvider);
        usdc.approve(address(pool), 100000 ether);
        pool.supply(address(usdc), 100000 ether, liquidityProvider, 0);
        vm.stopPrank();
    }

    function test_BorrowAndRepay() public {
        // 1. Alice 存入 1 个 WETH 作为抵押品 (价值 3000 USD)
        vm.startPrank(alice);
        weth.approve(address(pool), 1 ether);
        pool.supply(address(weth), 1 ether, alice, 0);

        // 预期最大可借: 3000 USD * 80% LTV = 2400 USD (对应 2400 USDC)
        uint256 borrowAmount = 2000 ether; // 借 2000 个 USDC，在安全线内

        // 2. Alice 借出 2000 USDC
        pool.borrow(address(usdc), borrowAmount, 1, 0, alice);
        
        // 验证借出成功
        assertEq(usdc.balanceOf(alice), borrowAmount, "Alice should receive borrowed USDC");

        // 检查健康因子
        (,,,,,uint256 hf) = pool.getUserAccountData(alice);
        // HF = (抵押物价值 3000 * 清算阈值 0.85) / 债务 2000 = 2550 / 2000 = 1.275 (1275000000000000000)
        assertEq(hf, 1275000000000000000, "Health factor mismatch");

        // 3. Alice 归还借款
        usdc.approve(address(pool), borrowAmount);
        pool.repay(address(usdc), borrowAmount, 1, alice);
        vm.stopPrank();

        assertEq(usdc.balanceOf(alice), 0, "Alice USDC balance should be 0 after repay");
    }
}