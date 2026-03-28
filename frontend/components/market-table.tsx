"use client";

import { useQuery } from "@tanstack/react-query";
import { MarketData, MarketDataRaw } from "@/types/market";
import { API_BASE_URL } from "@/lib/config";
import { SupplyWithdraw } from "./supply-withdraw";
import { BorrowRepay } from "./borrow-repay";
import { useWallet } from "./wallet-connect";

const fetchMarkets = async (): Promise<MarketData[]> => {
  const res = await fetch(`${API_BASE_URL}/api/markets`);
  if (!res.ok) throw new Error("Network response was not ok");

  const json = await res.json();
  const markets: MarketDataRaw[] = json.data || [];

  return markets.map((market: MarketDataRaw): MarketData => ({
    asset_address: market.asset_address,
    symbol: market.symbol,
    name: market.name,
    decimals: market.decimals,
    tvl: market.total_supply_base || "0",
    totalBorrowed: market.total_borrow_base || "0",
    supplyApy: 0,
    borrowApy: 0,
    availableLiquidity: "0",
  }));
};

export function MarketTable() {
  const { account } = useWallet();
  const { data: markets, isLoading, error } = useQuery({
    queryKey: ["marketsOverview"],
    queryFn: fetchMarkets,
    refetchInterval: 15000,
  });

  if (isLoading) {
    return <div className="text-gray-400 py-8 text-center animate-pulse">正在加载数据...</div>;
  }

  if (error) {
    return <div className="text-red-500 py-8 text-center">加载数据失败</div>;
  }

  return (
    <div className="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden mt-8">
      <table className="w-full text-left text-sm text-gray-300">
        <thead className="bg-gray-900/50 text-gray-400 uppercase font-semibold">
          <tr>
            <th className="px-6 py-4">资产</th>
            <th className="px-6 py-4">总锁仓量 (TVL)</th>
            <th className="px-6 py-4">可用流动性</th>
            <th className="px-6 py-4">存款 APY</th>
            <th className="px-6 py-4">借款 APY</th>
            <th className="px-6 py-4 text-right">操作</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-700">
          {markets?.map((market) => {
            const tvl = parseFloat(market.tvl);
            const borrowed = parseFloat(market.totalBorrowed);
            const available = tvl - borrowed;

            return (
              <tr key={market.asset_address} className="hover:bg-gray-750 transition-colors">
                <td className="px-6 py-4 font-medium text-white flex items-center gap-2">
                  <span className="w-6 h-6 rounded-full bg-blue-600 block"></span>
                  {market.symbol}
                </td>
                <td className="px-6 py-4">
                  ${available.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </td>
                <td className="px-6 py-4">
                  ${available.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </td>
                <td className="px-6 py-4 text-green-400">
                  {(market.supplyApy * 100).toFixed(2)}%
                </td>
                <td className="px-6 py-4 text-orange-400">
                  {(market.borrowApy * 100).toFixed(2)}%
                </td>
                <td className="px-6 py-4 text-right">
                  <div className="flex justify-end gap-2">
                    {account ? (
                      <>
                        <SupplyWithdraw asset={market} />
                        <BorrowRepay asset={market} />
                      </>
                    ) : (
                      <span className="text-gray-500 text-sm">连接钱包以操作</span>
                    )}
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
