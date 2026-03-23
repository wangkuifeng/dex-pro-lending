// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PriceOracle is IPriceOracle, Ownable {
    mapping(address => IAggregatorV3) private assetsSources;
    mapping(address => uint256) private fallbackPrices;

    event AssetSourceUpdated(address indexed asset, address indexed source);
    event FallbackPriceUpdated(address indexed asset, uint256 price);

    constructor() Ownable(msg.sender) {}

    function getAssetPrice(address asset) external view override returns (uint256) {
        IAggregatorV3 source = assetsSources[asset];

        if (address(source) == address(0)) {
            return fallbackPrices[asset];
        } else {
            (, int256 price, , , ) = source.latestRoundData();
            require(price > 0, "INVALID_PRICE");
            return uint256(price);
        }
    }

    function setAssetSources(address[] calldata assets, address[] calldata sources) external override onlyOwner {
        require(assets.length == sources.length, "INCONSISTENT_PARAMS_LENGTH");
        
        for (uint256 i = 0; i < assets.length; i++) {
            assetsSources[assets[i]] = IAggregatorV3(sources[i]);
            emit AssetSourceUpdated(assets[i], sources[i]);
        }
    }

    function setFallbackPrice(address asset, uint256 price) external onlyOwner {
        fallbackPrices[asset] = price;
        emit FallbackPriceUpdated(asset, price);
    }
}