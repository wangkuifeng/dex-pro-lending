// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";
import {MockV3Aggregator} from "../src/mocks/MockV3Aggregator.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;
    MockV3Aggregator public wethAggregator;
    MockERC20 public weth;

    function setUp() public {
        // 1. 部署预言机主合约
        oracle = new PriceOracle();
        
        // 2. 部署 WETH 代币
        weth = new MockERC20("Wrapped Ether", "WETH", 18);

        // 3. 部署 WETH 的 Mock 喂价合约 (假设初始价格为 3000 USD，精度 8 位)
        // Chainlink 的 USD 交易对通常是 8 位精度
        wethAggregator = new MockV3Aggregator(8, 3000 * 10**8);

        // 4. 配置预言机路由
        address[] memory assets = new address[](1);
        assets[0] = address(weth);
        
        address[] memory sources = new address[](1);
        sources[0] = address(wethAggregator);

        oracle.setAssetSources(assets, sources);
    }

    function test_GetAssetPrice() public view {
        uint256 price = oracle.getAssetPrice(address(weth));
        // 验证拉取的价格是否为 3000 * 10^8
        assertEq(price, 3000 * 10**8, "WETH price should be 3000 USD");
    }

    function test_UpdateAssetPrice() public {
        // 模拟以太坊暴跌到 1500 USD
        wethAggregator.updateAnswer(1500 * 10**8);
        
        uint256 newPrice = oracle.getAssetPrice(address(weth));
        assertEq(newPrice, 1500 * 10**8, "WETH price should update to 1500 USD");
    }

    function test_FallbackPrice() public {
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6);
        
        // 对于没有配置 Chainlink 源的代币，设置 fallback 价格 (1 USD = 1 * 10^8)
        oracle.setFallbackPrice(address(usdc), 1 * 10**8);

        uint256 price = oracle.getAssetPrice(address(usdc));
        assertEq(price, 1 * 10**8, "USDC fallback price should be 1 USD");
    }
}