"use client";

import { useState, useEffect } from 'react';
import { useWallet } from './wallet-connect';

const ERC20_ABI = ['0x095ea7b3', '0x70a08231', '0xdd62ed3e']; // approve, balanceOf, allowance
const POOL_ABI = ['0xc5cc746a', '0xa391344c']; // borrow, repay

const POOL_ADDRESS = '0xB6f654b7eEADbC7171fb1BD2f23a2ea0E8c0604E';

interface BorrowRepayProps {
  asset: {
    asset_address: string;
    symbol: string;
    decimals: number;
    borrowApy: number;
  };
}

export function BorrowRepay({ asset }: BorrowRepayProps) {
  const { account, isConnected } = useWallet();
  const [isOpen, setIsOpen] = useState(false);
  const [amount, setAmount] = useState('');
  const [activeTab, setActiveTab] = useState<'borrow' | 'repay'>('borrow');
  const [isLoading, setIsLoading] = useState(false);
  const [balance, setBalance] = useState('0');
  const [allowance, setAllowance] = useState<bigint>(BigInt(0));

  useEffect(() => {
    if (!window.ethereum || !account) return;

    const fetchData = async () => {
      try {
        const balanceCall = {
          to: asset.asset_address,
          data: '0x70a08231' + account.slice(2).padStart(64, '0')
        };
        const balanceResult = await window.ethereum.request({
          method: 'eth_call',
          params: [balanceCall, 'latest']
        });
        setBalance((BigInt(balanceResult) / BigInt(10 ** asset.decimals)).toString());

        const allowanceCall = {
          to: asset.asset_address,
          data: '0xdd62ed3e' + account.slice(2).padStart(64, '0') + POOL_ADDRESS.slice(2).padStart(64, '0')
        };
        const allowanceResult = await window.ethereum.request({
          method: 'eth_call',
          params: [allowanceCall, 'latest']
        });
        setAllowance(BigInt(allowanceResult));
      } catch (error) {
        console.error('Failed to fetch data:', error);
      }
    };

    fetchData();
  }, [account, asset.asset_address, asset.decimals]);

  const handleTransaction = async (methodId: string) => {
    if (!account || !amount) return;
    setIsLoading(true);

    try {
      const amountWei = BigInt(Math.floor(parseFloat(amount) * 10 ** asset.decimals));
      const encodedAmount = amountWei.toString(16).padStart(64, '0');
      const encodedAsset = asset.asset_address.slice(2).padStart(64, '0');
      const txData = methodId + encodedAsset + encodedAmount;

      const txHash = await window.ethereum!.request({
        method: 'eth_sendTransaction',
        params: [{
          from: account,
          to: activeTab === 'borrow' ? POOL_ADDRESS : asset.asset_address,
          data: activeTab === 'borrow' ? txData : '0xa391344c' + encodedAsset + encodedAmount
        }]
      });

      alert(`交易已发送: ${txHash}`);
      setIsOpen(false);
    } catch (error: any) {
      alert('交易失败: ' + error.message);
    } finally {
      setIsLoading(false);
    }
  };

  const needsApproval = allowance < BigInt(Math.floor(parseFloat(amount || '0') * 10 ** asset.decimals));

  if (!isConnected) {
    return <button className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded text-sm font-medium" onClick={() => alert('请先连接钱包')}>借款/还款</button>;
  }

  return (
    <>
      <button onClick={() => setIsOpen(true)} className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded text-sm font-medium">借款/还款</button>

      {isOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4 border border-gray-700">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-xl font-semibold text-white">{activeTab === 'borrow' ? '借款' : '还款'} {asset.symbol}</h2>
              <button onClick={() => setIsOpen(false)} className="text-gray-400 hover:text-white">✕</button>
            </div>

            <div className="flex gap-2 mb-6">
              <button onClick={() => setActiveTab('borrow')} className={`flex-1 py-2 rounded font-medium ${activeTab === 'borrow' ? 'bg-green-600 text-white' : 'bg-gray-700 text-gray-300'}`}>借款</button>
              <button onClick={() => setActiveTab('repay')} className={`flex-1 py-2 rounded font-medium ${activeTab === 'repay' ? 'bg-green-600 text-white' : 'bg-gray-700 text-gray-300'}`}>还款</button>
            </div>

            <div className="mb-6">
              <input type="number" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0.0" className="w-full bg-gray-900 border border-gray-700 rounded-lg px-4 py-3 text-white" disabled={isLoading} />
            </div>

            {activeTab === 'borrow' ? (
              needsApproval ? (
                <button onClick={() => handleTransaction('0x095ea7b3')} disabled={!amount || isLoading} className="w-full bg-orange-600 text-white py-3 rounded-lg">
                  {isLoading ? '处理中...' : `授权 ${asset.symbol}`}
                </button>
              ) : (
                <button onClick={() => handleTransaction('0xc5cc746a')} disabled={!amount || isLoading} className="w-full bg-green-600 text-white py-3 rounded-lg">
                  {isLoading ? '处理中...' : '借款'}
                </button>
              )
            ) : (
              <button onClick={() => handleTransaction('0xa391344c')} disabled={!amount || isLoading} className="w-full bg-green-600 text-white py-3 rounded-lg">
                {isLoading ? '处理中...' : '还款'}
              </button>
            )}
          </div>
        </div>
      )}
    </>
  );
}
