'use client'

import { motion } from 'framer-motion'
import { Scroll, User, Trophy, Award } from 'lucide-react'

export type TabType = 'quests' | 'character' | 'leaderboard' | 'achievements'

interface BottomNavProps {
  activeTab: TabType
  onTabChange: (tab: TabType) => void
}

const tabs: { id: TabType; icon: React.ElementType; label: string }[] = [
  { id: 'quests', icon: Scroll, label: 'Quests' },
  { id: 'character', icon: User, label: 'Character' },
  { id: 'leaderboard', icon: Trophy, label: 'Arena' },
  { id: 'achievements', icon: Award, label: 'Feats' },
]

export function BottomNav({ activeTab, onTabChange }: BottomNavProps) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-card border-t border-border pb-safe">
      <div className="flex items-stretch h-14">
        {tabs.map((tab) => {
          const Icon = tab.icon
          const isActive = activeTab === tab.id
          
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className="flex-1 flex flex-col items-center justify-center gap-0.5 relative"
            >
              {isActive && (
                <motion.div
                  layoutId="navIndicator"
                  className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full"
                  transition={{ type: 'spring', stiffness: 500, damping: 35 }}
                />
              )}
              <Icon 
                className={`w-5 h-5 transition-colors ${
                  isActive ? 'text-primary' : 'text-muted-foreground'
                }`} 
              />
              <span 
                className={`text-[10px] transition-colors ${
                  isActive ? 'text-primary font-medium' : 'text-muted-foreground'
                }`}
              >
                {tab.label}
              </span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}
