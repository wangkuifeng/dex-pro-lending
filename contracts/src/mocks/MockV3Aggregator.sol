// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";

contract MockV3Aggregator is IAggregatorV3 {
    uint8 public override decimals;
    int256 public latestAnswer;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        latestAnswer = _initialAnswer;
    }

    // 提供一个更新价格的后门，Day 6 模拟价格暴跌时会用到
    function updateAnswer(int256 _answer) public {
        latestAnswer = _answer;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            1,
            latestAnswer,
            block.timestamp,
            block.timestamp,
            1
        );
    }
}