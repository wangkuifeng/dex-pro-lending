// frontend/config/contracts.ts
import { parseAbi } from 'viem';

// 替换为你最新部署的 Pool 地址 (Sepolia)
// 可升级 Pool 合约 (UUPS Proxy) - 这是永久地址
export const POOL_ADDRESS = '0xe5ED95744b5a5987CBFd06827BC194F4664cC680';

// 预言机地址
export const ORACLE_ADDRESS = '0x8cFe668ed04B62dF79182C97c40ad49824433493';

// Mock 代币地址 (Sepolia)
export const TOKENS = {
  WETH: '0x94249A6B20E2b6B30C2e059E921Cf110B0d48E40',
  USDC: '0x98fB8e836Ee1b62420EF3Fd634f69EC677fc49bd',
  USDT: '0xfe012B9C851435D1E0303f63E7455CaA0A9a2e52',
} as const;

// AToken 地址
export const ATOKENS = {
  WETH: '0x00A7CD9441e8ec2bF65582569d7f5e9f45A9dF22',
  USDC: '0x95DDA02446c37490480b66350Aba4769097FdD7b',
  USDT: '0xe395ea3d0cb286cA11204C7367ADA1C5a5F823FB',
} as const;

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