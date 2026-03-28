// frontend/app/components/Navbar.tsx
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';

export default function Navbar() {
  return (
    <nav className="border-b border-gray-800 bg-gray-950 px-6 py-4">
      <div className="mx-auto flex max-w-7xl items-center justify-between">
        {/* Logo 与项目名称 */}
        <Link href="/" className="text-xl font-bold tracking-tight text-white">
          Dex Pro <span className="text-blue-500">Lending</span>
        </Link>
        
        {/* RainbowKit 钱包连接按钮 */}
        <div className="flex items-center">
          <ConnectButton 
            chainStatus="icon" 
            showBalance={true} 
            accountStatus="address" 
          />
        </div>
      </div>
    </nav>
  );
}