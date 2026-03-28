// frontend/config/wagmi.ts
import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { foundry, sepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'Dex Pro Lending',
  projectId: 'baadd4773f7e6b93743bfe2cd1803784', // 建议去 cloud.walletconnect.com 免费申请一个
  chains: [foundry, sepolia],
  ssr: true, // 适配 Next.js App Router 的服务端渲染
});