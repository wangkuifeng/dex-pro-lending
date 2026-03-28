// frontend/types/market.ts

// 后端返回的原始数据格式（snake_case）
export interface MarketDataRaw {
  asset_address: string;  // 底层资产合约地址
  symbol: string;          // 例如 "USDC", "WETH"
  name: string;            // 资产名称
  decimals: number;        // 小数位数
  total_supply_base: string;   // 总供应量
  total_borrow_base: string;   // 总借出量
  current_liquidity_rate: string; // 存款利率
  current_borrow_rate: string;   // 借款利率
}

// 前端使用的格式（camelCase + 计算字段）
export interface MarketData {
  asset_address: string;
  symbol: string;
  name: string;
  decimals: number;
  tvl: string;           // 总锁仓量 (计算字段)
  totalBorrowed: string; // 总借出量 (计算字段)
  supplyApy: number;     // 存款 APY (计算字段)
  borrowApy: number;     // 借款 APY (计算字段)
  availableLiquidity: string; // 可用流动性 (计算字段)
}