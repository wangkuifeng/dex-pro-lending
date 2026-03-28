"use client";

import { useQuery } from "@tanstack/react-query";
import { MarketData } from "@/types/market";
import { API_BASE_URL } from "@/lib/config";
import { SupplyWithdraw } from "./supply-withdraw";
import { BorrowRepay } from "./borrow-repay";
import { useWallet } from "./wallet-connect";

const fetchMarkets = async (): Promise<MarketData[]> => {
  const res = await fetch(`${API_BASE_URL}/api/markets`);
  if (!res.ok) throw new Error("Network response was not ok");

  const json = await res.json();
  const markets = json.data || [];

  // 如果后端返回空数据，返回静态测试数据
  if (markets.length === 0) {
    return [
      {
        asset_address: '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14',
        symbol: 'WETH',
        name: 'Wrapped Ether',
        decimals: 18,
        tvl: '1000000',
        totalBorrowed: '500000',
        supplyApy: 0.05,
        borrowApy: 0.08,
        availableLiquidity: '500000',
      },
      {
        asset_address: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
        symbol: 'USDC',
        name: 'USD Coin',
        decimals: 6,
        tvl: '2000000',
        totalBorrowed: '800000',
        supplyApy: 0.03,
        borrowApy: 0.06,
        availableLiquidity: '1200000',
      },
      {
        asset_address: '0x7169D38820dfd117C3FA1f22a697DBA58d90BA06',
        symbol: 'USDT',
        name: 'Tether USD',
        decimals: 6,
        tvl: '1500000',
        totalBorrowed: '600000',
        supplyApy: 0.035,
        borrowApy: 0.065,
        availableLiquidity: '900000',
      },
    ];
  }

  return markets.map((market: any): MarketData => ({
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
      {markets && markets.length > 0 && (
        <div className="p-4 bg-yellow-500/10 border border-yellow-500/20 rounded-lg mb-4">
          <div className="text-sm text-yellow-400">
            ℹ️ 当前显示测试数据。要使用真实数据，需要先部署合约到 Sepolia 测试网。
          </div>
        </div>
      )}

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
                  ${tvl.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
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
