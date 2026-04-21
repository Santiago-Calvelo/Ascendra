'use client'

import { Sword, Brain, Heart, Zap } from 'lucide-react'
import type { Stats } from '@/lib/game-types'

const statConfig: Record<keyof Stats, {
  icon: React.ElementType
  label: string
  color: string
}> = {
  strength: { icon: Sword, label: 'STR', color: 'text-destructive' },
  discipline: { icon: Brain, label: 'DIS', color: 'text-primary' },
  endurance: { icon: Heart, label: 'END', color: 'text-stamina' },
  wisdom: { icon: Zap, label: 'WIS', color: 'text-mana' }
}

interface StatsDisplayProps {
  stats: Stats
  layout?: 'row' | 'grid'
}

export function StatsDisplay({ stats, layout = 'row' }: StatsDisplayProps) {
  const entries = Object.entries(stats) as [keyof Stats, number][]
  
  if (layout === 'grid') {
    return (
      <div className="grid grid-cols-2 gap-2">
        {entries.map(([stat, value]) => {
          const config = statConfig[stat]
          const Icon = config.icon
          return (
            <div key={stat} className="flex items-center gap-2 bg-secondary/30 rounded-lg px-3 py-2">
              <Icon className={`w-4 h-4 ${config.color}`} />
              <div className="flex items-baseline gap-1">
                <span className={`text-sm font-semibold ${config.color}`}>{value}</span>
                <span className="text-[10px] text-muted-foreground">{config.label}</span>
              </div>
            </div>
          )
        })}
      </div>
    )
  }

  return (
    <div className="flex items-center gap-4">
      {entries.map(([stat, value]) => {
        const config = statConfig[stat]
        const Icon = config.icon
        return (
          <div key={stat} className="flex items-center gap-1.5">
            <Icon className={`w-3.5 h-3.5 ${config.color}`} />
            <span className={`text-sm font-semibold ${config.color}`}>{value}</span>
          </div>
        )
      })}
    </div>
  )
}
