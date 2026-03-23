// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAToken} from "../interfaces/IAToken.sol";

contract AToken is ERC20, IAToken {
    address public immutable POOL;
    address internal _underlyingAsset;

    modifier onlyPool() {
        require(msg.sender == POOL, "CALLER_MUST_BE_POOL");
        _;
    }

    constructor(
        address pool,
        address underlyingAsset,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        POOL = pool;
        _underlyingAsset = underlyingAsset;
    }

    function mint(
        address /* caller */,      // 修改这里 (原本是 address caller)
        address onBehalfOf,
        uint256 amount,
        uint256 /* index */        // 修改这里 (原本是 uint256 index)
    ) external override onlyPool returns (bool) {
        // TODO: Phase 2 我们会在这里引入 index (流动性指数) 来实现利息的自动累加 (Scaled Balance)
        // 今天我们先保持 1:1 的基础铸造逻辑，跑通闭环
        _mint(onBehalfOf, amount);
        return true;
    }

    function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
        return _underlyingAsset;
    }

    // 记得在文件顶部引入 SafeERC20 和 IERC20
    using SafeERC20 for IERC20;

    function burn(
        address from,
        address receiver,
        uint256 amount,
        uint256 /* index */        // 修改这里 (原本是 uint256 index)
    ) external override onlyPool {
        // 1. 销毁用户的 aToken 凭证
        _burn(from, amount);

        // 2. 将底层资产（如 USDC/WETH）从 AToken 合约转移给 receiver
        // 注意：这里的资金是从 AToken 合约发出的，因为 Supply 时资金存在了这里
        IERC20(_underlyingAsset).safeTransfer(receiver, amount);
    }

    function transferUnderlyingTo(address target, uint256 amount) external override onlyPool {
        IERC20(_underlyingAsset).safeTransfer(target, amount);
    }
}