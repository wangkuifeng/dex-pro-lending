// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceOracle {
    /**
     * @notice 获取资产的 USD 价格
     * @param asset 资产的地址
     * @return 资产的 USD 价格
     */
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice 配置资产对应的 Chainlink 喂价合约地址
     */
    function setAssetSources(address[] calldata assets, address[] calldata sources) external;
}