// frontend/app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "./providers"; 
import { Zap } from "lucide-react";
import { ConnectButton } from '@rainbow-me/rainbowkit'; // 引入 RainbowKit 按钮

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Dex Pro Lending | Institutional Grade DeFi",
  description: "Next generation liquidity protocol",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark" style={{ backgroundColor: '#020617' }}>
      <body 
        className={`${inter.className} bg-[#020617] text-slate-200 antialiased min-h-screen`}
        style={{ backgroundColor: '#020617' }}
      >
        <Providers>
          {/* 顶栏 Header: 采用磨砂玻璃效果 */}
          <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-[#020617]/80 backdrop-blur-md">
            <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
              
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center shadow-lg shadow-blue-500/20">
                  <Zap size={20} className="text-white fill-current" />
                </div>
                <span className="text-xl font-bold tracking-tight text-white">
                  Dex Pro <span className="text-blue-500">Lending</span>
                </span>
              </div>
              
              <div className="flex items-center gap-4">
                <div className="hidden md:flex items-center gap-2 px-3 py-1.5 bg-white/5 rounded-full border border-white/10 text-xs text-slate-400 font-medium shadow-inner">
                   <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_8px_rgba(16,185,129,0.8)]"></div>
                   Sepolia Testnet
                </div>
                
                {/* 右上角钱包按钮 */}
                <ConnectButton />
              </div>
              
            </div>
          </header>

          {/* 主内容区域 */}
          <main className="max-w-7xl mx-auto px-6 py-10">
            {children}
          </main>
        </Providers>
      </body>
    </html>
  );
}