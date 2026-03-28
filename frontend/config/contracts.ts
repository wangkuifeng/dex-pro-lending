// frontend/config/contracts.ts
import { parseAbi } from 'viem';

// 替换为你最新部署的 Pool 地址 (Sepolia)
export const POOL_ADDRESS = '0x53da77297453cEA71949fB260335E3eC7ce0Cf25';

export const ERC20_ABI = parseAbi([
  'function approve(address spender, uint256 amount) external returns (bool)',
  'function allowance(address owner, address spender) external view returns (uint256)',
  'function balanceOf(address account) external view returns (uint256)',
  'function decimals() external view returns (uint8)',
  'function symbol() external view returns (string)'
]);

export const POOL_ABI = parseAbi([
  'function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external',
  'function withdraw(address asset, uint256 amount, address to) external returns (uint256)',
  // 👇 关键修复：加上这行，Wagmi 才能去读你的资产数据！并且去掉变量名防止崩溃！
  'function getUserAccountData(address user) external view returns (uint256, uint256, uint256, uint256, uint256, uint256)'
]);