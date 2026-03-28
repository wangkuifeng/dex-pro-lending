// frontend/app/reserve/[address]/page.tsx
'use client';

import { useState, useEffect, use } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import { ArrowLeft, CheckCircle2, Loader2, ShieldCheck, ExternalLink } from 'lucide-react';
import Link from 'next/link';
import { POOL_ADDRESS, ERC20_ABI, POOL_ABI, TOKENS } from '@/config/contracts';

export default function ReservePage({ params }: { params: Promise<{ address: string }> }) {
  // 1. 处理 Next.js 15 的异步路由参数
  const resolvedParams = use(params);
  const assetAddress = resolvedParams.address as `0x${string}`;
  
  const { address: userAddress, isConnected } = useAccount();
  const [amount, setAmount] = useState('');

  // 2. 读取链上状态 (余额与授权额度)
  const { data: balance = 0n, refetch: refetchBalance } = useReadContract({
    address: assetAddress,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: userAddress ? [userAddress] : undefined,
    query: { enabled: !!userAddress },
  });

  const { data: allowance = 0n, refetch: refetchAllowance } = useReadContract({
    address: assetAddress,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: userAddress ? [userAddress, POOL_ADDRESS] : undefined,
    query: { enabled: !!userAddress },
  });

  // 3. 状态判断逻辑
  // 根据实际代币地址判断精度和符号
  const isWeth = assetAddress.toLowerCase() === TOKENS.WETH.toLowerCase();
  const isUSDC = assetAddress.toLowerCase() === TOKENS.USDC.toLowerCase();
  const isUSDT = assetAddress.toLowerCase() === TOKENS.USDT.toLowerCase();

  // 获取代币符号
  const getTokenSymbol = () => {
    if (isWeth) return 'WETH';
    if (isUSDC) return 'USDC';
    if (isUSDT) return 'USDT';
    return 'Token';
  };

  const decimals = isWeth ? 18 : 6;
  const parsedAmount = amount ? parseUnits(amount, decimals) : 0n;
  const needsApprove = parsedAmount > allowance;

  // 4. 写操作：Approve 授权
  const { writeContract: writeApprove, data: approveHash } = useWriteContract();
  const { isLoading: isApproveConfirming, isSuccess: isApproveSuccess } = useWaitForTransactionReceipt({ hash: approveHash });

  // 5. 写操作：Supply 存款
  const { writeContract: writeSupply, data: supplyHash } = useWriteContract();
  const { isLoading: isSupplyConfirming, isSuccess: isSupplySuccess } = useWaitForTransactionReceipt({ hash: supplyHash });

  // 6. 成功后的自动刷新逻辑
  useEffect(() => {
    if (isApproveSuccess) {
      refetchAllowance();
    }
    if (isSupplySuccess) {
      refetchBalance();
      // 存款成功后不立即清空 amount，让用户在弹窗里看到确认
    }
  }, [isApproveSuccess, isSupplySuccess, refetchAllowance, refetchBalance]);

  return (
    <div className="mt-8 max-w-xl mx-auto p-8 rounded-[2.5rem] border border-white/10 bg-slate-900/40 backdrop-blur-xl shadow-2xl relative overflow-hidden">
      {/* 背景装饰光效 */}
      <div className="absolute -top-24 -right-24 w-48 h-48 bg-blue-600/10 rounded-full blur-[80px] pointer-events-none"></div>

      <Link href="/" className="flex items-center gap-2 text-gray-500 hover:text-white mb-8 transition-colors text-sm font-medium">
        <ArrowLeft size={16} /> Back to Markets
      </Link>

      <div className="flex items-center gap-5 mb-10">
        <div className="p-4 bg-blue-600/20 rounded-2xl border border-blue-500/30 text-blue-400 shadow-inner">
          <ShieldCheck size={32} />
        </div>
        <div>
          <h2 className="text-3xl font-black text-white tracking-tight">Supply Asset</h2>
          <p className="text-xs text-slate-500 font-mono mt-1 break-all opacity-60">{assetAddress}</p>
        </div>
      </div>

      <div className="space-y-8">
        {/* 输入框区域 */}
        <div className="bg-black/40 border border-white/5 rounded-3xl p-6 hover:border-white/10 transition-colors">
          <div className="flex justify-between text-sm font-semibold text-slate-400 mb-4">
            <span>Amount to Supply</span>
            <span>Balance: <b className="text-white">{formatUnits(balance, decimals)}</b></span>
          </div>
          <div className="flex items-center gap-4">
            <input 
              type="number" 
              value={amount} 
              onChange={e => setAmount(e.target.value)}
              placeholder="0.00"
              className="w-full bg-transparent text-4xl font-bold text-white focus:outline-none placeholder-slate-800"
            />
            <button 
              onClick={() => setAmount(formatUnits(balance, decimals))} 
              className="px-4 py-2 bg-blue-600/10 rounded-xl text-xs font-black text-blue-400 hover:bg-blue-600 hover:text-white transition-all uppercase tracking-widest"
            >
              Max
            </button>
          </div>
        </div>

        {/* 交互按钮组 */}
        <div className="grid grid-cols-2 gap-4">
          <button
            onClick={() => writeApprove({ address: assetAddress, abi: ERC20_ABI, functionName: 'approve', args: [POOL_ADDRESS, parsedAmount] })}
            disabled={!needsApprove || isApproveConfirming || parsedAmount === 0n}
            className={`py-5 rounded-2xl font-black transition-all uppercase tracking-wider text-sm ${
              !needsApprove && parsedAmount > 0n 
                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 cursor-default' 
                : 'bg-slate-800 text-white hover:bg-slate-700 shadow-lg disabled:opacity-30 disabled:grayscale'
            }`}
          >
            {isApproveConfirming ? <Loader2 className="animate-spin mx-auto" /> : !needsApprove && parsedAmount > 0n ? '✓ Approved' : '1. Approve'}
          </button>

          <button
            onClick={() => writeSupply({ address: POOL_ADDRESS, abi: POOL_ABI, functionName: 'supply', args: [assetAddress, parsedAmount, userAddress!, 0] })}
            disabled={needsApprove || isSupplyConfirming || parsedAmount === 0n}
            className={`py-5 rounded-2xl font-black transition-all uppercase tracking-wider text-sm ${
              needsApprove 
                ? 'bg-slate-900 text-slate-600 border border-white/5 cursor-not-allowed' 
                : 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-xl shadow-blue-500/20 hover:scale-[1.02] active:scale-95'
            }`}
          >
            {isSupplyConfirming ? <Loader2 className="animate-spin mx-auto" /> : '2. Supply'}
          </button>
        </div>
      </div>

      {/* --- ✨ 成功反馈遮罩层 (Success Overlay) ✨ --- */}
      {isSupplySuccess && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-[#020617]/90 backdrop-blur-md animate-in fade-in duration-500">
          <div className="bg-slate-900 border border-white/10 p-10 rounded-[3rem] shadow-[0_0_80px_rgba(16,185,129,0.15)] text-center max-w-sm mx-4">
            <div className="w-24 h-24 bg-emerald-500/20 rounded-full flex items-center justify-center mx-auto mb-8 relative">
              <div className="absolute inset-0 bg-emerald-500/20 rounded-full animate-ping"></div>
              <CheckCircle2 size={56} className="text-emerald-500 relative z-10" />
            </div>
            
            <h3 className="text-3xl font-black text-white mb-3 tracking-tight">Success!</h3>
            <p className="text-slate-400 mb-8 leading-relaxed">
              Your {amount} {getTokenSymbol()} has been securely supplied to the protocol.
            </p>

            <div className="space-y-4">
              <button 
                onClick={() => { setAmount(''); window.location.href = '/'; }} 
                className="w-full py-4 bg-emerald-600 hover:bg-emerald-500 text-white rounded-2xl font-bold shadow-lg shadow-emerald-900/40 transition-all active:scale-95"
              >
                Back to Dashboard
              </button>
              
              <a 
                href={`https://sepolia.etherscan.io/tx/${supplyHash}`} 
                target="_blank" 
                rel="noreferrer"
                className="flex items-center justify-center gap-2 text-xs text-slate-500 hover:text-slate-300 transition-colors uppercase font-bold tracking-widest"
              >
                View Transaction <ExternalLink size={14} />
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}