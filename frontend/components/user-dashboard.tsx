"use client";

import { useEffect, useState } from 'react';
import { useWallet } from './wallet-connect';
import { UserState } from '@/types/user';
import { API_BASE_URL } from '@/lib/config';

export function UserDashboard() {
  const { account, isConnected } = useWallet();
  const [userState, setUserState] = useState<UserState | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!account) return;

    const fetchUserState = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const response = await fetch(`${API_BASE_URL}/api/users/${account}`);
        if (response.ok) {
          const data = await response.json();
          console.log('User data:', data);
          setUserState(data);
        } else {
          setError('无法获取用户数据');
        }
      } catch (err) {
        console.error('Failed to fetch user state:', err);
        setError('获取用户数据失败');
      } finally {
        setIsLoading(false);
      }
    };

    fetchUserState();
    const interval = setInterval(fetchUserState, 15000);
    return () => clearInterval(interval);
  }, [account]);

  if (!isConnected) {
    return (
      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h2 className="text-xl font-semibold text-white mb-4">我的账户</h2>
        <p className="text-gray-400">请连接钱包查看您的账户信息</p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h2 className="text-xl font-semibold text-white mb-4">我的账户</h2>
        <div className="text-gray-400">加载中...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h2 className="text-xl font-semibold text-white mb-4">我的账户</h2>
        <div className="text-red-400">{error}</div>
      </div>
    );
  }

  // 安全的默认值
  const accountData = userState?.accountData;
  const healthFactor = parseFloat(accountData?.healthFactor || '0');
  const isHealthy = healthFactor >= 1.0 || healthFactor === 0;

  return (
    <div className="space-y-6">
      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h2 className="text-xl font-semibold text-white mb-6">我的账户</h2>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-gray-900/50 rounded-lg p-4">
            <div className="text-sm text-gray-400 mb-1">总抵押品价值</div>
            <div className="text-2xl font-bold text-green-400">
              ${parseFloat(accountData?.totalCollateralBase || '0').toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>

          <div className="bg-gray-900/50 rounded-lg p-4">
            <div className="text-sm text-gray-400 mb-1">总债务</div>
            <div className="text-2xl font-bold text-orange-400">
              ${parseFloat(accountData?.totalDebtBase || '0').toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>

          <div className="bg-gray-900/50 rounded-lg p-4">
            <div className="text-sm text-gray-400 mb-1">可借额度</div>
            <div className="text-2xl font-bold text-blue-400">
              ${parseFloat(accountData?.availableBorrowsBase || '0').toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
          </div>
        </div>

        <div className="mt-6">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-gray-400">健康因子</span>
            <span className={`text-lg font-semibold ${isHealthy ? 'text-green-400' : 'text-red-400'}`}>
              {healthFactor === 0 ? '∞' : healthFactor.toFixed(2)}
            </span>
          </div>

          <div className="w-full bg-gray-700 rounded-full h-3 overflow-hidden">
            <div
              className={`h-full transition-all ${
                healthFactor >= 2 ? 'bg-green-500' :
                healthFactor >= 1.5 ? 'bg-yellow-500' :
                healthFactor >= 1.1 ? 'bg-orange-500' :
                healthFactor >= 1 ? 'bg-red-500' :
                'bg-red-600 animate-pulse'
              }`}
              style={{ width: `${Math.min(healthFactor / 3 * 100, 100)}%` }}
            />
          </div>

          {healthFactor < 1.5 && healthFactor > 0 && (
            <div className="mt-3 p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
              <div className="text-sm text-red-400">
                {healthFactor < 1 ? '⚠️ 危险：健康因子低于 1.0，面临清算风险！' : '⚠️ 警告：健康因子偏低，建议增加抵押品或偿还债务'}
              </div>
            </div>
          )}

          {healthFactor === 0 && (
            <div className="mt-3 p-3 bg-blue-500/10 border border-blue-500/20 rounded-lg">
              <div className="text-sm text-blue-400">ℹ️ 当前无借款，请先存入资产作为抵押品</div>
            </div>
          )}
        </div>
      </div>

      {userState?.reserves && userState.reserves.length > 0 && (
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <h3 className="text-lg font-semibold text-white mb-4">我的持仓</h3>

          <div className="space-y-4">
            {userState.reserves.map((reserve) => {
              const supplied = parseFloat(reserve.suppliedAmount || '0');
              const borrowed = parseFloat(reserve.borrowedAmount || '0');

              if (supplied === 0 && borrowed === 0) return null;

              return (
                <div key={reserve.assetAddress} className="bg-gray-900/50 rounded-lg p-4">
                  <div className="flex justify-between items-center mb-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-white text-sm font-medium">
                        {reserve.symbol[0]}
                      </div>
                      <div>
                        <div className="text-white font-medium">{reserve.symbol}</div>
                        <div className="text-sm text-gray-400">{reserve.assetAddress.slice(0, 10)}...</div>
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4 text-sm">
                    {supplied > 0 && (
                      <div>
                        <div className="text-gray-400">已存款</div>
                        <div className="text-green-400 font-medium">
                          {supplied.toFixed(4)} {reserve.symbol}
                        </div>
                      </div>
                    )}

                    {borrowed > 0 && (
                      <div>
                        <div className="text-gray-400">已借款</div>
                        <div className="text-orange-400 font-medium">
                          {borrowed.toFixed(4)} {reserve.symbol}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
