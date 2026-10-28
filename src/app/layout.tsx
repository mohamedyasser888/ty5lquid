import type { Metadata, Viewport } from "next";
import DeviceInfo from "@/components/ui/DeviceInfo";
import "./globals.css";

const GAME_VERSION = '3.4';

export const metadata: Metadata = {
  title: "Quidditch Academy - Magical Sports Game",
  description: "Enter the wizarding world of Quidditch. Play solo or team matches, unlock achievements, and compete with wizards worldwide.",
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'Quidditch Academy',
  },
  manifest: '/manifest.json', // PWA manifest
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5, // Allow zoom for accessibility, but prevent accidental pinch zoom during gameplay
  userScalable: true,
  themeColor: '#0f172a', // slate-900 for mobile browser chrome
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className="h-full antialiased"
    >
      <head>
        {/* Critical Resource Hints for Maximum Performance */}
        
        {/* DNS Prefetch - Resolve DNS early */}
        <link rel="dns-prefetch" href="https://supabase.co" />
        <link rel="dns-prefetch" href="https://fonts.googleapis.com" />
        
        {/* Preconnect - Establish connections early */}
        <link rel="preconnect" href="https://supabase.co" crossOrigin="anonymous" />
        
      </head>
      <body className="min-h-full flex flex-col">
        <DeviceInfo />
        {children}
        <div className="fixed bottom-1 right-2 z-[100] rounded-md border border-amber-300/30 bg-slate-950/80 px-2 py-0.5 text-[10px] font-black tracking-wider text-amber-200/80 shadow-lg">
          v{GAME_VERSION}
        </div>
      </body>
    </html>
  );
}
