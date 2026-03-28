// frontend/app/layout.tsx
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Providers } from './providers';
import Navbar from '../components/Navbar';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Dex Pro Lending',
  description: 'Decentralized Lending Protocol targeting Aave V3',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          {/* 全局导航栏 */}
          <Navbar />
          {/* 这里可以预留全局 Navbar */}
          <main className="min-h-screen bg-gray-950 text-white">
            {children}
          </main>
        </Providers>
      </body>
    </html>
  );
}