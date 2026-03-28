'use client';

import { useState, useEffect } from 'react';

declare global {
  interface Window {
    ethereum?: {
      request: (args: { method: string; params?: any[] }) => Promise<any>;
      on: (event: string, handler: (...args: any[]) => void) => void;
      removeListener: (event: string, handler: (...args: any[]) => void) => void;
      selectedAddress?: string;
    };
  }
}

export function WalletConnect() {
  const [account, setAccount] = useState<string>('');
  const [isConnecting, setIsConnecting] = useState(false);
  const [chainId, setChainId] = useState<number | null>(null);

  const isWrongNetwork = chainId !== null && chainId !== 11155111;

  useEffect(() => {
    if (window.ethereum?.selectedAddress) {
      setAccount(window.ethereum.selectedAddress);
    }

    const handleAccountsChanged = (accounts: string[]) => {
      if (accounts.length > 0) {
        setAccount(accounts[0]);
      } else {
        setAccount('');
      }
    };

    const handleChainChanged = (chainId: string) => {
      setChainId(parseInt(chainId, 16));
    };

    if (window.ethereum) {
      window.ethereum.on('accountsChanged', handleAccountsChanged);
      window.ethereum.on('chainChanged', handleChainChanged);
      window.ethereum.request({ method: 'eth_chainId' })
        .then((id: string) => setChainId(parseInt(id, 16)));
    }

    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
        window.ethereum.removeListener('chainChanged', handleChainChanged);
      }
    };
  }, []);

  const connectWallet = async () => {
    if (!window.ethereum) {
      alert('请安装 MetaMask 钱包！');
      return;
    }

    setIsConnecting(true);
    try {
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts',
      });
      setAccount(accounts[0]);

      const chainId = await window.ethereum.request({ method: 'eth_chainId' });
      setChainId(parseInt(chainId, 16));

      if (parseInt(chainId, 16) !== 11155111) {
        await switchToSepolia();
      }
    } catch (error: any) {
      console.error('连接钱包失败:', error);
      if (error.code === 4001) {
        alert('用户拒绝了连接请求');
      } else {
        alert('连接失败: ' + error.message);
      }
    } finally {
      setIsConnecting(false);
    }
  };

  const switchToSepolia = async () => {
    try {
      await window.ethereum!.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0xaa36a7' }],
      });
      setChainId(11155111);
    } catch (error: any) {
      if (error.code === 4902) {
        try {
          await window.ethereum!.request({
            method: 'wallet_addEthereumChain',
            params: [{
              chainId: '0xaa36a7',
              chainName: 'Sepolia Test Network',
              nativeCurrency: {
                name: 'Sepolia ETH',
                symbol: 'ETH',
                decimals: 18,
              },
              rpcUrls: ['https://rpc.sepolia.org'],
              blockExplorerUrls: ['https://sepolia.etherscan.io'],
            }],
          });
          setChainId(11155111);
        } catch (addError) {
          console.error('添加网络失败:', addError);
          alert('无法切换到 Sepolia 网络');
        }
      }
    }
  };

  const disconnectWallet = () => {
    setAccount('');
    setChainId(null);
  };

  const formatAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  return (
    <div className="fixed top-4 right-4 z-50">
      {isWrongNetwork && (
        <div className="mb-2 px-3 py-2 bg-red-500/20 border border-red-500 rounded-lg text-red-400 text-xs">
          ⚠️ 请切换到 Sepolia 网络
        </div>
      )}
      {!account ? (
        <button
          onClick={connectWallet}
          disabled={isConnecting}
          className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isConnecting ? '连接中...' : '连接钱包'}
        </button>
      ) : (
        <div className="flex items-center gap-3">
          <div className="px-4 py-2 bg-gray-800 rounded-lg border border-gray-700">
            <p className="text-white text-sm font-medium">
              {formatAddress(account)}
            </p>
            {chainId !== null && (
              <p className="text-gray-400 text-xs">
                {chainId === 11155111 ? 'Sepolia' : `Chain ${chainId}`}
              </p>
            )}
          </div>
          <button
            onClick={disconnectWallet}
            className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm transition-colors"
          >
            断开
          </button>
        </div>
      )}
    </div>
  );
}
