'use client';

import { http, createConfig } from 'wagmi';
import { sepolia } from 'wagmi/chains';
import { injected, metaMask } from 'wagmi/connectors';

// 简化配置，只使用 MetaMask
export const config = createConfig({
  chains: [sepolia],
  connectors: [
    injected(),
    metaMask(),
  ],
  transports: {
    [sepolia.id]: http(),
  },
  ssr: true,
});

// 为 RainbowKit 提供的配置
export const projectId = 'aef1cdac96e84f54d6a8bc234979d8fc';
export const appName = 'DEX Pro Lending';
