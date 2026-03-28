import { WalletConnect } from "@/components/wallet-connect";
import { MarketTable } from "@/components/market-table"; // 新增引入

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-black">
      <WalletConnect />
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-white mb-8">
          DEX Pro Lending
        </h1>
        <p className="text-gray-300">
          去中心化借贷协议
        </p>
        <div className="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <h2 className="text-xl font-semibold text-white mb-4">存入资产</h2>
            <p className="text-gray-400">存入加密资产赚取利息</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <h2 className="text-xl font-semibold text-white mb-4">借款</h2>
            <p className="text-gray-400">抵押资产借入资金</p>
          </div>
        </div>
        {/* 挂载新的市场总览组件 */}
        <div className="mt-12">
          <h2 className="text-2xl font-semibold text-white mb-6">市场总览</h2>
          <MarketTable />
        </div>
      </div>
    </main>
  );
}
