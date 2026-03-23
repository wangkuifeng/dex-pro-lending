// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Pool} from "../src/core/Pool.sol";
import {AToken} from "../src/core/AToken.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";

contract PoolTest is Test {
    Pool public pool;
    MockERC20 public weth;
    AToken public aWeth;

    // 定义测试用户
    address public alice = makeAddr("Alice");
    address public bob = makeAddr("Bob");

    uint256 public constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        // 1. 部署核心合约
        pool = new Pool();
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        
        // 2. 部署 aToken 并绑定 Pool 与底层资产
        aWeth = new AToken(address(pool), address(weth), "Aave Interest bearing WETH", "aWETH");

        // 3. 初始化 Pool 的 Reserve 状态 (升级：带上 LTV 和 清算阈值)
        pool.initReserve(address(weth), address(aWeth), 8000, 8500);

        // 4. 给测试用户发钱
        weth.mint(alice, INITIAL_BALANCE);
        weth.mint(bob, INITIAL_BALANCE);
    }

    /* ==============================================
       测试: 存款 (Supply)
    ============================================== */
    function test_Supply_Success() public {
        uint256 supplyAmount = 100 ether;

        // Alice 存款前准备：授权 Pool 扣除 WETH
        vm.startPrank(alice);
        weth.approve(address(pool), supplyAmount);

        // Alice 执行存款
        pool.supply(address(weth), supplyAmount, alice, 0);
        vm.stopPrank();

        // 验证 1：Alice 的 aWETH 余额增加
        assertEq(aWeth.balanceOf(alice), supplyAmount, "Alice should receive exact aWETH");
        
        // 验证 2：Alice 的 WETH 余额减少
        assertEq(weth.balanceOf(alice), INITIAL_BALANCE - supplyAmount, "Alice WETH balance should decrease");
        
        // 验证 3：资金是否安全隔离在 aToken 合约中，而不是 Pool 中
        assertEq(weth.balanceOf(address(aWeth)), supplyAmount, "aToken contract should hold the underlying WETH");
        assertEq(weth.balanceOf(address(pool)), 0, "Pool should not hold user WETH");
    }

    function test_RevertIf_SupplyZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert("INVALID_AMOUNT");
        pool.supply(address(weth), 0, alice, 0);
    }

    /* ==============================================
       测试: 提取 (Withdraw)
    ============================================== */
    function test_Withdraw_Partial() public {
        uint256 supplyAmount = 100 ether;
        uint256 withdrawAmount = 40 ether;

        // Alice 先存 100 WETH
        vm.startPrank(alice);
        weth.approve(address(pool), supplyAmount);
        pool.supply(address(weth), supplyAmount, alice, 0);

        // Alice 提取 40 WETH
        pool.withdraw(address(weth), withdrawAmount, alice);
        vm.stopPrank();

        // 验证状态
        assertEq(aWeth.balanceOf(alice), supplyAmount - withdrawAmount, "aWETH balance incorrect after partial withdraw");
        assertEq(weth.balanceOf(alice), INITIAL_BALANCE - supplyAmount + withdrawAmount, "WETH balance incorrect after partial withdraw");
    }

    function test_Withdraw_MaxCapacity() public {
        uint256 supplyAmount = 100 ether;

        vm.startPrank(alice);
        weth.approve(address(pool), supplyAmount);
        pool.supply(address(weth), supplyAmount, alice, 0);

        // 使用 type(uint256).max 提取全部本息
        pool.withdraw(address(weth), type(uint256).max, alice);
        vm.stopPrank();

        assertEq(aWeth.balanceOf(alice), 0, "Alice should have 0 aWETH left");
        assertEq(weth.balanceOf(alice), INITIAL_BALANCE, "Alice should have all WETH back");
        assertEq(weth.balanceOf(address(aWeth)), 0, "aToken contract should be empty");
    }

    function test_RevertIf_WithdrawMoreThanBalance() public {
        uint256 supplyAmount = 100 ether;

        vm.startPrank(alice);
        weth.approve(address(pool), supplyAmount);
        pool.supply(address(weth), supplyAmount, alice, 0);

        // 尝试提取超出余额的金额
        vm.expectRevert("NOT_ENOUGH_FUNDS");
        pool.withdraw(address(weth), 101 ether, alice);
        vm.stopPrank();
    }
}