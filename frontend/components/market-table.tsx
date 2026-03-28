// frontend/components/market-table.tsx
"use client";

import { useQuery } from "@tanstack/react-query";
import { MarketData, MarketDataRaw } from "@/types/market";
import { API_BASE_URL } from "@/lib/config";

// 提取数据请求逻辑
const fetchMarkets = async (): Promise<MarketData[]> => {
  // 请求后端 API
  const res = await fetch(`${API_BASE_URL}/api/markets`);
  if (!res.ok) throw new Error("Network response was not ok");

  const json = await res.json();
  const markets: MarketDataRaw[] = json.data || [];

  // 转换数据格式，添加计算字段
  return markets.map((market: MarketDataRaw): MarketData => ({
    asset_address: market.asset_address,
    symbol: market.symbol,
    name: market.name,
    decimals: market.decimals,
    tvl: market.total_supply_base || "0",
    totalBorrowed: market.total_borrow_base || "0",
    supplyApy: 0, // TODO: 从 current_liquidity_rate 计算
    borrowApy: 0, // TODO: 从 current_borrow_rate 计算
    availableLiquidity: "0", // TODO: 计算 supply - borrow
  }));
};

export function MarketTable() {
  const { data: markets, isLoading, error } = useQuery({
    queryKey: ["marketsOverview"],
    queryFn: fetchMarkets,
    refetchInterval: 15000, // 每 15 秒轮询一次 Go 后端
  });

  if (isLoading) {
    return <div className="text-gray-400 py-8 text-center animate-pulse">正在同步链上流动性...</div>;
  }

  if (error) {
    return <div className="text-red-500 py-8 text-center">无法连接到索引节点</div>;
  }

  return (
    <div className="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden mt-8">
      <table className="w-full text-left text-sm text-gray-300">
        <thead className="bg-gray-900/50 text-gray-400 uppercase font-semibold">
          <tr>
            <th className="px-6 py-4">资产</th>
            <th className="px-6 py-4">总锁仓量 (TVL)</th>
            <th className="px-6 py-4">存款 APY</th>
            <th className="px-6 py-4">借款 APY</th>
            <th className="px-6 py-4 text-right">操作</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-700">
          {markets?.map((market) => (
            <tr key={market.asset_address} className="hover:bg-gray-750 transition-colors">
              <td className="px-6 py-4 font-medium text-white flex items-center gap-2">
                {/* 后期这里可以加上 Token Logo */}
                <span className="w-6 h-6 rounded-full bg-gray-600 block"></span>
                {market.symbol}
              </td>
              <td className="px-6 py-4">${Number(market.tvl).toLocaleString()}</td>
              <td className="px-6 py-4 text-green-400">
                {(market.supplyApy * 100).toFixed(2)}%
              </td>
              <td className="px-6 py-4 text-orange-400">
                {(market.borrowApy * 100).toFixed(2)}%
              </td>
              <td className="px-6 py-4 text-right">
                <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-1.5 rounded text-sm font-medium transition-colors">
                  详情
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}