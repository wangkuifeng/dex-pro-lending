"use client";

import { useState, useEffect } from 'react';
import { useWallet } from './wallet-connect';

// ERC20 ABI - 只需要用到的函数
const ERC20_ABI = [
  {
    "constant": true,
    "inputs": [{"name": "_owner", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "balance", "type": "uint256"}],
    "type": "function"
  },
  {
    "constant": false,
    "inputs": [
      {"name": "_spender", "type": "address"},
      {"name": "_value", "type": "uint256"}
    ],
    "name": "approve",
    "outputs": [{"name": "", "type": "bool"}],
    "type": "function"
  },
  {
    "constant": true,
    "inputs": [
      {"name": "_owner", "type": "address"},
      {"name": "_spender", "type": "address"}
    ],
    "name": "allowance",
    "outputs": [{"name": "", "type": "uint256"}],
    "type": "function"
  }
];

// Pool ABI
const POOL_ABI = [
  {
    "inputs": [
      {"name": "asset", "type": "address"},
      {"name": "amount", "type": "uint256"}
    ],
    "name": "supply",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "asset", "type": "address"},
      {"name": "amount", "type": "uint256"}
    ],
    "name": "withdraw",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

const POOL_ADDRESS = '0xB6f654b7eEADbC7171fb1BD2f23a2ea0E8c0604E';

interface SupplyWithdrawProps {
  asset: {
    asset_address: string;
    symbol: string;
    decimals: number;
    supplyApy: number;
  };
}

export function SupplyWithdraw({ asset }: SupplyWithdrawProps) {
  const { account, isConnected } = useWallet();
  const [isOpen, setIsOpen] = useState(false);
  const [amount, setAmount] = useState('');
  const [activeTab, setActiveTab] = useState<'supply' | 'withdraw'>('supply');
  const [isLoading, setIsLoading] = useState(false);
  const [balance, setBalance] = useState('0');
  const [allowance, setAllowance] = useState<bigint>(BigInt(0));

  // 获取余额和授权额度
  useEffect(() => {
    if (!window.ethereum || !account) return;

    const fetchBalanceAndAllowance = async () => {
      try {
        // 获取余额
        const balanceCall = {
          to: asset.asset_address,
          data: '0x70a08231' + account.slice(2).padStart(64, '0') // balanceOf
        };

        const balanceResult = await window.ethereum.request({
          method: 'eth_call',
          params: [balanceCall, 'latest']
        });
        const bal = BigInt(balanceResult);
        setBalance((bal / BigInt(10 ** asset.decimals)).toString());

        // 获取授权额度
        const allowanceCall = {
          to: asset.asset_address,
          data: '0xdd62ed3e' + // allowance
                  account.slice(2).padStart(64, '0') +
                  POOL_ADDRESS.slice(2).padStart(64, '0')
        };

        const allowanceResult = await window.ethereum.request({
          method: 'eth_call',
          params: [allowanceCall, 'latest']
        });
        setAllowance(BigInt(allowanceResult));
      } catch (error) {
        console.error('Failed to fetch balance:', error);
      }
    };

    fetchBalanceAndAllowance();
  }, [account, asset.asset_address, asset.decimals]);

  const encodeApprove = (spender: string, amount: bigint) => {
    const methodId = '0x095ea7b3'; // approve
    const encodedSpender = spender.slice(2).padStart(64, '0');
    const encodedAmount = amount.toString(16).padStart(64, '0');
    return methodId + encodedSpender + encodedAmount;
  };

  const encodeSupply = (asset: string, amount: bigint) => {
    const methodId = '0x617ba037'; // supply
    const encodedAsset = asset.slice(2).padStart(64, '0');
    const encodedAmount = amount.toString(16).padStart(64, '0');
    return methodId + encodedAsset + encodedAmount;
  };

  const encodeWithdraw = (asset: string, amount: bigint) => {
    const methodId = '0x441a3e70'; // withdraw
    const encodedAsset = asset.slice(2).padStart(64, '0');
    const encodedAmount = amount.toString(16).padStart(64, '0');
    return methodId + encodedAsset + encodedAmount;
  };

  const handleApprove = async () => {
    if (!account || !amount) return;
    setIsLoading(true);

    try {
      const amountWei = BigInt(Math.floor(parseFloat(amount) * 10 ** asset.decimals));
      const txData = encodeApprove(POOL_ADDRESS, amountWei);

      const txHash = await window.ethereum!.request({
        method: 'eth_sendTransaction',
        params: [{
          from: account,
          to: asset.asset_address,
          data: txData
        }]
      });

      alert(`授权交易已发送: ${txHash}`);
      setIsOpen(false);
    } catch (error: any) {
      alert('授权失败: ' + error.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSupply = async () => {
    if (!account || !amount) return;
    setIsLoading(true);

    try {
      const amountWei = BigInt(Math.floor(parseFloat(amount) * 10 ** asset.decimals));
      const txData = encodeSupply(asset.asset_address, amountWei);

      const txHash = await window.ethereum!.request({
        method: 'eth_sendTransaction',
        params: [{
          from: account,
          to: POOL_ADDRESS,
          data: txData
        }]
      });

      alert(`存款交易已发送: ${txHash}`);
      setIsOpen(false);
    } catch (error: any) {
      alert('存款失败: ' + error.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleWithdraw = async () => {
    if (!account || !amount) return;
    setIsLoading(true);

    try {
      const amountWei = BigInt(Math.floor(parseFloat(amount) * 10 ** asset.decimals));
      const txData = encodeWithdraw(asset.asset_address, amountWei);

      const txHash = await window.ethereum!.request({
        method: 'eth_sendTransaction',
        params: [{
          from: account,
          to: POOL_ADDRESS,
          data: txData
        }]
      });

      alert(`提取交易已发送: ${txHash}`);
      setIsOpen(false);
    } catch (error: any) {
      alert('提取失败: ' + error.message);
    } finally {
      setIsLoading(false);
    }
  };

  const needsApproval = allowance < BigInt(Math.floor(parseFloat(amount || '0') * 10 ** asset.decimals));

  if (!isConnected) {
    return (
      <button
        className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded text-sm font-medium transition-colors"
        onClick={() => alert('请先连接钱包')}
      >
        存款/提取
      </button>
    );
  }

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded text-sm font-medium transition-colors"
      >
        存款/提取
      </button>

      {isOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4 border border-gray-700">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-xl font-semibold text-white">
                {activeTab === 'supply' ? '存款' : '提取'} {asset.symbol}
              </h2>
              <button
                onClick={() => setIsOpen(false)}
                className="text-gray-400 hover:text-white"
              >
                ✕
              </button>
            </div>

            <div className="flex gap-2 mb-6">
              <button
                onClick={() => setActiveTab('supply')}
                className={`flex-1 py-2 rounded font-medium transition-colors ${
                  activeTab === 'supply'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                }`}
              >
                存款
              </button>
              <button
                onClick={() => setActiveTab('withdraw')}
                className={`flex-1 py-2 rounded font-medium transition-colors ${
                  activeTab === 'withdraw'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                }`}
              >
                提取
              </button>
            </div>

            <div className="mb-4 text-sm text-gray-400">
              {activeTab === 'supply' ? (
                <div>
                  余额: {balance} {asset.symbol}
                  <button
                    onClick={() => setAmount(balance)}
                    className="ml-2 text-blue-400 hover:text-blue-300"
                  >
                    最大
                  </button>
                </div>
              ) : (
                <div>提取数量（请输入要提取的金额）</div>
              )}
            </div>

            {activeTab === 'supply' && (
              <div className="mb-4 p-3 bg-green-500/10 border border-green-500/20 rounded-lg">
                <div className="text-sm text-gray-300">存款 APY</div>
                <div className="text-lg font-semibold text-green-400">
                  {(asset.supplyApy * 100).toFixed(2)}%
                </div>
              </div>
            )}

            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-300 mb-2">
                金额
              </label>
              <div className="relative">
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.0"
                  className="w-full bg-gray-900 border border-gray-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  disabled={isLoading}
                />
                <div className="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400">
                  {asset.symbol}
                </div>
              </div>
            </div>

            {activeTab === 'supply' ? (
              needsApproval ? (
                <button
                  onClick={handleApprove}
                  disabled={!amount || isLoading}
                  className="w-full bg-orange-600 hover:bg-orange-700 text-white py-3 rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isLoading ? '处理中...' : `授权 ${asset.symbol}`}
                </button>
              ) : (
                <button
                  onClick={handleSupply}
                  disabled={!amount || isLoading}
                  className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isLoading ? '处理中...' : '存款'}
                </button>
              )
            ) : (
              <button
                onClick={handleWithdraw}
                disabled={!amount || isLoading}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? '处理中...' : '提取'}
              </button>
            )}
          </div>
        </div>
      )}
    </>
  );
}
