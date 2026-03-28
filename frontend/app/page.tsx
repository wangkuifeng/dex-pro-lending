import { WalletConnect } from "@/components/wallet-connect";
import { MarketTable } from "@/components/market-table";
import { UserDashboard } from "@/components/user-dashboard";

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-black">
      <WalletConnect />
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-white mb-2">
          DEX Pro Lending
        </h1>
        <p className="text-gray-300 mb-8">
          去中心化借贷协议
        </p>

        {/* 用户 Dashboard */}
        <div className="mb-8">
          <UserDashboard />
        </div>

        {/* 功能介绍 */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <h2 className="text-xl font-semibold text-white mb-4">存入资产</h2>
            <p className="text-gray-400">存入加密资产赚取利息</p>
            <ul className="mt-4 space-y-2 text-sm text-gray-300">
              <li>✓ 支持 WETH, USDC, USDT</li>
              <li>✓ 实时计息</li>
              <li>✓ 作为抵押品借款</li>
            </ul>
          </div>
          <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <h2 className="text-xl font-semibold text-white mb-4">借款</h2>
            <p className="text-gray-400">抵押资产借入资金</p>
            <ul className="mt-4 space-y-2 text-sm text-gray-300">
              <li>✓ 灵活的抵押率</li>
              <li>✓ 实时健康因子监控</li>
              <li>✓ 多资产支持</li>
            </ul>
          </div>
        </div>

        {/* 市场总览 */}
        <div>
          <h2 className="text-2xl font-semibold text-white mb-6">市场总览</h2>
          <MarketTable />
        </div>
      </div>
    </main>
  );
}
