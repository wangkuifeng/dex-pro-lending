// frontend/app/page.tsx
'use client';

import { Activity, Wallet, PieChart, ArrowRight, Zap, TrendingUp, ShieldAlert, ShieldCheck } from 'lucide-react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { formatUnits } from 'viem';
import { useAccount, useReadContract } from 'wagmi';
import { POOL_ADDRESS, POOL_ABI } from '@/config/contracts';

// --- 1. 接口与辅助函数 ---
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
  return { color: 'text-slate-400', bg: 'bg-slate-400/10', border: 'border-slate-500/20' };
};

// --- 2. 个人资产看板组件 (Day 14 核心) ---
function UserDashboard() {
  const { address: userAddress, isConnected } = useAccount();

  // 读取账户全局数据
  const { data: accountData,error: accountError } = useReadContract({
    address: POOL_ADDRESS,
    abi: POOL_ABI,
    functionName: 'getUserAccountData',
    args: userAddress ? [userAddress] : undefined,
    query: { enabled: !!userAddress, refetchInterval: 5000 },
  });

  // 加上这一行！在浏览器控制台（F12）看红字！
  if (accountError) {
    console.error("🚨 合约读取失败，原因如下:", accountError.message);
  }
  
  if (!isConnected) return null;

  // 默认值防空指针
  const [totalCollateralBase, totalDebtBase, , , , healthFactor] = (accountData as unknown as any[]) || [0n, 0n, 0n, 0n, 0n, 0n];

  // 格式化数值 (在 Aave 体系中 Base 单位通常是 8 位精度，匹配 Chainlink USD 预言机)
  const collateral = Number(formatUnits(totalCollateralBase, 8)).toFixed(2);
  const debt = Number(formatUnits(totalDebtBase, 8)).toFixed(2);
  const netWorth = (Number(collateral) - Number(debt)).toFixed(2);
  
  // 计算健康因子 (以太坊上极大值表示无借款，设定为无穷大)
  const hf = Number(formatUnits(healthFactor, 18));
  const hasNoDebt = totalDebtBase === 0n;
  const displayHF = hasNoDebt ? '∞' : hf > 100 ? '100+' : hf.toFixed(2);

  // 动态颜色和进度条逻辑
  const getHFColor = (val: number, noDebt: boolean) => {
    if (noDebt || val >= 3) return 'text-emerald-400';
    if (val >= 1.5) return 'text-yellow-400';
    return 'text-red-500';
  };

  const getProgressColor = (val: number, noDebt: boolean) => {
    if (noDebt || val >= 3) return 'bg-emerald-500 shadow-[0_0_15px_rgba(16,185,129,0.4)]';
    if (val >= 1.5) return 'bg-yellow-500 shadow-[0_0_15px_rgba(234,179,8,0.4)]';
    return 'bg-red-500 shadow-[0_0_15px_rgba(239,68,68,0.6)] animate-pulse';
  };

  const progressPercent = hasNoDebt ? 100 : Math.min((hf / 5) * 100, 100);

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-12 animate-in slide-in-from-bottom-4 duration-700">
      <div className="lg:col-span-2 p-8 rounded-[2rem] bg-slate-900/40 border border-white/5 backdrop-blur-xl flex flex-col md:flex-row justify-between items-center gap-8 shadow-2xl relative overflow-hidden">
        <div className="absolute top-0 right-0 p-8 opacity-5 pointer-events-none">
          <Wallet size={120} />
        </div>
        <div className="space-y-1 relative z-10">
          <p className="text-slate-500 text-xs font-black uppercase tracking-widest">Net Worth</p>
          <h2 className="text-5xl font-black text-white">$ {netWorth}</h2>
        </div>

        <div className="flex gap-12 text-center relative z-10">
          <div>
            <p className="text-slate-500 text-xs font-bold mb-1 uppercase tracking-wider">Collateral</p>
            <p className="text-2xl font-bold text-white">$ {collateral}</p>
          </div>
          <div>
            <p className="text-slate-500 text-xs font-bold mb-1 uppercase tracking-wider">Total Debt</p>
            <p className="text-2xl font-bold text-orange-400">$ {debt}</p>
          </div>
        </div>
      </div>

      <div className="p-8 rounded-[2rem] bg-slate-900/40 border border-white/5 backdrop-blur-xl relative overflow-hidden group shadow-2xl">
        <div className="relative z-10">
          <div className="flex justify-between items-end mb-4">
            <div className="flex items-center gap-2">
              {hasNoDebt || hf >= 1.5 ? <ShieldCheck size={18} className="text-emerald-500" /> : <ShieldAlert size={18} className="text-red-500" />}
              <p className="text-slate-500 text-xs font-black uppercase tracking-widest">Health Factor</p>
            </div>
            <span className={`text-4xl font-black ${getHFColor(hf, hasNoDebt)}`}>{displayHF}</span>
          </div>

          <div className="h-4 w-full bg-black/40 rounded-full overflow-hidden mb-4 border border-white/5">
            <div 
              className={`h-full transition-all duration-1000 ease-out rounded-full ${getProgressColor(hf, hasNoDebt)}`}
              style={{ width: `${progressPercent}%` }}
            ></div>
          </div>
          
          <div className="flex justify-between text-[10px] font-bold uppercase tracking-widest">
            <span className="text-red-500">Danger (1.0)</span>
            <span className="text-emerald-500">Safe</span>
          </div>
        </div>
        
        <div className={`absolute -bottom-10 -right-10 w-40 h-40 rounded-full blur-[80px] opacity-20 transition-colors duration-1000 pointer-events-none ${getProgressColor(hf, hasNoDebt)}`}></div>
      </div>
    </div>
  );
}

// --- 3. 主页面 (包含宏观数据与列表) ---
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
    <div className="space-y-10">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h1 className="text-5xl font-black tracking-tight text-white mb-4">
            Markets
          </h1>
          <p className="text-slate-400 text-lg max-w-xl leading-relaxed">
            Supply assets to the protocol and earn real-time yield, or borrow against your collateral with institutional-grade security.
          </p>
        </div>
        <div className="flex items-center gap-2 px-4 py-2 bg-blue-500/10 border border-blue-500/20 rounded-xl text-blue-400 text-sm font-bold shadow-inner">
           <TrendingUp size={16} />
           Protocol TVL: $127.45M
        </div>
      </div>

      <UserDashboard />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[
          { label: 'Total Market Size', value: '$ 127.45M', icon: Wallet, color: 'text-blue-500' },
          { label: 'Total Borrowed', value: '$ 92.83M', icon: Activity, color: 'text-purple-500' },
          { label: 'Global Health Factor', value: '1.85', icon: PieChart, color: 'text-emerald-500' },
        ].map((stat, i) => (
          <div key={i} className="p-8 rounded-[2rem] bg-slate-900/40 border border-white/5 backdrop-blur-md hover:border-white/10 transition-all duration-300 group shadow-lg">
            <stat.icon size={24} className={`${stat.color} mb-4 opacity-80 group-hover:scale-110 transition-transform`} />
            <p className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-2">{stat.label}</p>
            <h2 className="text-3xl font-black text-white tracking-tight">{stat.value}</h2>
          </div>
        ))}
      </div>

      <div className="rounded-[2.5rem] border border-white/5 bg-slate-900/40 backdrop-blur-xl overflow-hidden shadow-2xl relative">
        <div className="px-8 py-6 border-b border-white/5 flex items-center justify-between bg-black/20">
          <h3 className="text-xl font-bold text-white flex items-center gap-3">
            <div className="p-2 bg-blue-500/20 rounded-lg">
               <Zap size={20} className="text-blue-400 fill-current" />
            </div>
            Active Reserves
          </h3>
          <div className="text-[10px] text-slate-500 font-mono uppercase tracking-widest border border-white/5 px-3 py-1 rounded-full">
            Real-time Oracle: Chainlink
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="text-[10px] uppercase text-slate-500 font-black tracking-widest bg-black/20 border-b border-white/5">
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
                          <div className="text-[10px] text-slate-500 font-mono mt-0.5">{market.asset_address.slice(0, 6)}...{market.asset_address.slice(-4)}</div>
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
                        className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-6 py-3 text-sm font-bold text-white shadow-lg shadow-blue-600/20 hover:bg-blue-500 hover:-translate-y-0.5 transition-all duration-300 active:scale-95 uppercase tracking-widest"
                      >
                        Details
                        <ArrowRight size={16} />
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