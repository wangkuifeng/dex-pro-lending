// 用户账户数据类型
export interface UserAccountData {
  totalCollateralBase: string;
  totalDebtBase: string;
  availableBorrowsBase: string;
  currentLiquidationThreshold: string;
  ltv: string;
  healthFactor: string;
}

// 用户储备余额
export interface UserReserveBalance {
  assetAddress: string;
  symbol: string;
  decimals: number;
  suppliedAmount: string;
  borrowedAmount: string;
  supplyApy: number;
  borrowApy: number;
  usableAsCollateral: boolean;
}

// 用户完整状态
export interface UserState {
  address: string;
  accountData: UserAccountData;
  reserves: UserReserveBalance[];
}
