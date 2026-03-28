// frontend/app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "./providers"; // 确保你的 Providers 路径正确
import { Zap } from "lucide-react";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Dex Pro Lending | Institutional Grade DeFi",
  description: "Next generation liquidity protocol",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      {/* 这里的 bg-slate-950 确保了全局没有白杠，antialiased 让文字更清晰 */}
      <body className={`${inter.className} bg-[#020617] text-slate-200 antialiased min-h-screen`}>
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
              
              {/* 这里预留你的钱包连接组件 */}
              <div className="flex items-center gap-4">
                <div className="hidden md:flex items-center gap-1 px-3 py-1 bg-white/5 rounded-full border border-white/10 text-xs text-gray-400 font-medium">
                   <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></div>
                   Sepolia Testnet
                </div>
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