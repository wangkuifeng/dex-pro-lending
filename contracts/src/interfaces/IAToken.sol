// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAToken {
    /**
     * @notice 由 Pool 合约调用，为用户铸造 aToken
     * @param caller 发起存款的地址 (msg.sender)
     * @param onBehalfOf 接收 aToken 的地址
     * @param amount 铸造数量
     * @param index 流动性指数 (用于后续利息计算，今天先透传)
     */
    function mint(
        address caller,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice 由 Pool 合约调用，销毁用户的 aToken，并将等额的底层资产转给接收者
     * @param from 销毁 aToken 的目标用户
     * @param receiver 接收底层资产的地址
     * @param amount 销毁与提取的数量
     * @param index 流动性指数 (Day 4/5 使用)
     */
    function burn(
        address from,
        address receiver,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @notice 由 Pool 调用，将底层资产转给借款人
     */
    function transferUnderlyingTo(address target, uint256 amount) external;
}