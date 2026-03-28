// frontend/app/page.tsx
'use client';

import { Activity, Wallet, PieChart, ArrowRight, Zap, TrendingUp } from 'lucide-react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { formatUnits } from 'viem';

interface Market {
  asset_address: string;
  symbol: string;
  decimals: number;
  total_supply_base: string;     
  total_borrow_base: string;     
  current_liquidity_rate: string; 
  current_borrow_rate: string;    
}

const rayToPercent = (ray: string) => {
  return (Number(BigInt(ray || '0') / 10n**21n) / 10000).toFixed(2);
};

const getTokenStyle = (symbol: string) => {
  const s = symbol.toUpperCase();
  if (s.includes('WETH') || s.includes('ETH')) return { color: 'text-purple-400', bg: 'bg-purple-400/10', border: 'border-purple-500/20' };
  if (s.includes('USDC')) return { color: 'text-blue-400', bg: 'bg-blue-400/10', border: 'border-blue-500/20' };
  if (s.includes('USDT')) return { color: 'text-teal-400', bg: 'bg-teal-400/10', border: 'border-teal-500/20' };
  return { color: 'text-gray-400', bg: 'bg-gray-400/10', border: 'border-gray-500/20' };
};

export default function Home() {
  const { data: markets, isLoading, isError } = useQuery({
    queryKey: ['markets'],
    queryFn: async () => {
      const res = await fetch('http://localhost:8080/api/markets');
      if (!res.ok) throw new Error('Failed to fetch markets');
      const json = await res.json();
      return (json.data || json) as Market[]; 
    },
    refetchInterval: 10000, 
  });

  return (
    <div className="space-y-10 animate-in fade-in slide-in-from-bottom-4 duration-700">
      {/* Hero Section */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h1 className="text-5xl font-black tracking-tight text-white mb-4">
            Markets
          </h1>
          <p className="text-slate-400 text-lg max-w-xl leading-relaxed">
            Supply assets to the protocol and earn real-time yield, or borrow against your collateral with institutional-grade security.
          </p>
        </div>
        <div className="flex items-center gap-2 px-4 py-2 bg-blue-500/10 border border-blue-500/20 rounded-xl text-blue-400 text-sm font-bold">
           <TrendingUp size={16} />
           Protocol TVL: $127.45M
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[
          { label: 'Total Market Size', value: '$ 127.45M', icon: Wallet, color: 'text-blue-500' },
          { label: 'Total Borrowed', value: '$ 92.83M', icon: Activity, color: 'text-purple-500' },
          { label: 'Global Health Factor', value: '1.85', icon: PieChart, color: 'text-emerald-500' },
        ].map((stat, i) => (
          <div key={i} className="p-8 rounded-3xl bg-slate-900/40 border border-white/5 backdrop-blur-sm hover:border-white/10 transition-all duration-300 group">
            <stat.icon size={24} className={`${stat.color} mb-4 opacity-80 group-hover:scale-110 transition-transform`} />
            <p className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-1">{stat.label}</p>
            <h2 className="text-3xl font-bold text-white tracking-tight">{stat.value}</h2>
          </div>
        ))}
      </div>

      {/* Assets Table */}
      <div className="rounded-[2rem] border border-white/5 bg-slate-900/20 backdrop-blur-md overflow-hidden shadow-2xl">
        <div className="px-8 py-6 border-b border-white/5 flex items-center justify-between bg-white/[0.01]">
          <h3 className="text-xl font-bold text-white flex items-center gap-3">
            <Zap size={22} className="text-yellow-500 fill-current" />
            Assets to Supply
          </h3>
          <div className="text-xs text-slate-500 font-mono">Real-time Oracle: Chainlink</div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="text-xs uppercase text-slate-500 font-bold tracking-widest bg-white/[0.02]">
                <th className="px-8 py-6">Asset</th>
                <th className="px-8 py-6">Total Supplied</th>
                <th className="px-8 py-6 text-emerald-500/80">Supply APY</th>
                <th className="px-8 py-6">Total Borrowed</th>
                <th className="px-8 py-6 text-orange-500/80">Borrow APY</th>
                <th className="px-8 py-6 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="px-8 py-20 text-center">
                    <div className="inline-flex items-center gap-3 text-blue-400 font-bold">
                      <div className="w-5 h-5 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
                      Fetching Protocol Data...
                    </div>
                  </td>
                </tr>
              ) : markets?.map((market) => {
                const style = getTokenStyle(market.symbol);
                const supplied = Number(formatUnits(BigInt(market.total_supply_base || '0'), market.decimals)).toLocaleString(undefined, {minimumFractionDigits: 2});
                const borrowed = Number(formatUnits(BigInt(market.total_borrow_base || '0'), market.decimals)).toLocaleString(undefined, {minimumFractionDigits: 2});

                return (
                  <tr key={market.asset_address} className="group hover:bg-white/[0.03] transition-all duration-300">
                    <td className="px-8 py-6">
                      <div className="flex items-center gap-4">
                        <div className={`w-12 h-12 rounded-2xl ${style.bg} ${style.border} border flex items-center justify-center shadow-inner`}>
                          <span className={`text-lg font-black ${style.color}`}>{market.symbol.charAt(0)}</span>
                        </div>
                        <div>
                          <div className="font-bold text-white text-lg">{market.symbol}</div>
                          <div className="text-[10px] text-slate-500 font-mono">{market.asset_address.slice(0, 6)}...{market.asset_address.slice(-4)}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-8 py-6 font-semibold text-slate-200">{supplied}</td>
                    <td className="px-8 py-6 font-black text-emerald-400 text-lg">
                      {rayToPercent(market.current_liquidity_rate)}%
                    </td>
                    <td className="px-8 py-6 font-semibold text-slate-200">{borrowed}</td>
                    <td className="px-8 py-6 font-black text-orange-400 text-lg">
                      {rayToPercent(market.current_borrow_rate)}%
                    </td>
                    <td className="px-8 py-6 text-right">
                      <Link 
                        href={`/reserve/${market.asset_address}`}
                        className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-6 py-3 text-sm font-bold text-white shadow-lg shadow-blue-600/20 hover:bg-blue-500 hover:-translate-y-0.5 transition-all duration-300 active:scale-95"
                      >
                        Details
                        <ArrowRight size={18} />
                      </Link>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}