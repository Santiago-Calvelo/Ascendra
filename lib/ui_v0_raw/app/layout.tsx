import type { Metadata, Viewport } from 'next'
import { Cinzel, Geist } from 'next/font/google'
import { Analytics } from '@vercel/analytics/next'
import './globals.css'

const cinzel = Cinzel({ 
  subsets: ["latin"],
  variable: '--font-cinzel',
  weight: ['400', '500', '600', '700']
})

const geist = Geist({ 
  subsets: ["latin"],
  variable: '--font-geist'
})

export const metadata: Metadata = {
  title: 'HabitQuest - Your Daily Adventure',
  description: 'A gamified habit tracker with RPG mechanics. Complete quests, gain XP, and level up your character.',
  generator: 'v0.app',
}

export const viewport: Viewport = {
  themeColor: '#1a1625',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className={`${cinzel.variable} ${geist.variable} bg-background`}>
      <body className="font-sans antialiased min-h-screen">
        {children}
        {process.env.NODE_ENV === 'production' && <Analytics />}
      </body>
    </html>
  )
}
