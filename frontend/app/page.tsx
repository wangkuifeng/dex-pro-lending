export default function Home() {
  return (
    <div className="mt-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight text-white">Markets Dashboard</h1>
        <p className="mt-2 text-gray-400">View and supply assets to the Dex Pro protocol.</p>
      </div>

      {/* 预留的市场数据表格区域 */}
      <div className="overflow-hidden rounded-xl border border-gray-800 bg-gray-900 shadow-sm">
        <div className="p-6 text-center text-gray-500">
          Loading market data from Go Indexer...
        </div>
      </div>
    </div>
  );
}