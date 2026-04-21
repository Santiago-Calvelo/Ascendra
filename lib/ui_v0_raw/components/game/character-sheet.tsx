'use client'

import { motion } from 'framer-motion'
import { Sword, Brain, Heart, Zap, Calendar, Flame } from 'lucide-react'
import { XPBar } from './xp-bar'
import type { Character, Stats } from '@/lib/game-types'

interface CharacterSheetProps {
  character: Character
}

const statDetails: Record<keyof Stats, {
  icon: React.ElementType
  label: string
  color: string
  description: string
}> = {
  strength: { icon: Sword, label: 'Strength', color: 'text-destructive', description: 'Gym workouts' },
  discipline: { icon: Brain, label: 'Discipline', color: 'text-primary', description: 'Mental focus' },
  endurance: { icon: Heart, label: 'Endurance', color: 'text-stamina', description: 'Cardio & steps' },
  wisdom: { icon: Zap, label: 'Wisdom', color: 'text-mana', description: 'Focus sessions' }
}

export function CharacterSheet({ character }: CharacterSheetProps) {
  return (
    <div className="space-y-4">
      {/* Profile Card */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-card rounded-xl p-5 border border-border text-center"
      >
        <div className="w-20 h-20 mx-auto rounded-full bg-secondary/50 border border-border flex items-center justify-center text-4xl mb-3">
          {character.avatar}
        </div>
        <h2 className="text-xl font-semibold text-foreground">{character.name}</h2>
        <p className="text-sm text-gold-dim mb-4">{character.title}</p>
        
        <div className="flex items-center justify-center gap-6 mb-4">
          <div className="text-center">
            <span className="text-2xl font-bold text-gold">{character.level}</span>
            <span className="text-xs text-muted-foreground block">Level</span>
          </div>
          <div className="w-px h-8 bg-border" />
          <div className="text-center">
            <span className="text-2xl font-bold text-foreground">
              {Object.values(character.stats).reduce((a, b) => a + b, 0)}
            </span>
            <span className="text-xs text-muted-foreground block">Total Stats</span>
          </div>
        </div>

        <XPBar 
          current={character.xp} 
          max={character.xpToNextLevel} 
          level={character.level}
          size="md"
        />
      </motion.div>

      {/* Stats */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="bg-card rounded-xl p-4 border border-border"
      >
        <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wide mb-3">
          Attributes
        </h3>
        <div className="space-y-3">
          {(Object.keys(character.stats) as Array<keyof Stats>).map((stat) => {
            const config = statDetails[stat]
            const Icon = config.icon
            const value = character.stats[stat]
            const percentage = Math.min((value / 100) * 100, 100)

            return (
              <div key={stat} className="flex items-center gap-3">
                <Icon className={`w-4 h-4 ${config.color} shrink-0`} />
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm text-foreground">{config.label}</span>
                    <span className={`text-sm font-semibold ${config.color}`}>{value}</span>
                  </div>
                  <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
                    <motion.div
                      className={`h-full rounded-full ${
                        stat === 'strength' ? 'bg-destructive' :
                        stat === 'discipline' ? 'bg-primary' :
                        stat === 'endurance' ? 'bg-stamina' : 'bg-mana'
                      }`}
                      initial={{ width: 0 }}
                      animate={{ width: `${percentage}%` }}
                      transition={{ duration: 0.5 }}
                    />
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </motion.div>

      {/* Activity */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="grid grid-cols-2 gap-3"
      >
        <div className="bg-card rounded-xl p-4 border border-border">
          <div className="flex items-center gap-2 text-muted-foreground mb-1">
            <Calendar className="w-4 h-4" />
            <span className="text-xs">Days Active</span>
          </div>
          <span className="text-2xl font-bold text-foreground">42</span>
        </div>
        <div className="bg-card rounded-xl p-4 border border-border">
          <div className="flex items-center gap-2 text-muted-foreground mb-1">
            <Flame className="w-4 h-4 text-growth" />
            <span className="text-xs">Streak</span>
          </div>
          <span className="text-2xl font-bold text-foreground">7</span>
        </div>
      </motion.div>
    </div>
  )
}
