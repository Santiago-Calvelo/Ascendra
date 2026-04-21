'use client'

import { motion } from 'framer-motion'
import { XPBar } from './xp-bar'
import type { Character } from '@/lib/game-types'

interface CharacterHeaderProps {
  character: Character
}

export function CharacterHeader({ character }: CharacterHeaderProps) {
  return (
    <motion.div 
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      className="px-4"
    >
      <div className="flex items-center gap-3">
        {/* Avatar */}
        <div className="relative shrink-0">
          <div className="w-12 h-12 rounded-full bg-card border border-border flex items-center justify-center text-xl">
            {character.avatar}
          </div>
          <div className="absolute -bottom-0.5 -right-0.5 bg-gold text-background text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center">
            {character.level}
          </div>
        </div>
        
        {/* Name and XP */}
        <div className="flex-1 min-w-0">
          <div className="flex items-baseline gap-2">
            <h1 className="font-semibold text-foreground truncate">
              {character.name}
            </h1>
            <span className="text-xs text-gold-dim shrink-0">{character.title}</span>
          </div>
          <div className="mt-1">
            <XPBar 
              current={character.xp} 
              max={character.xpToNextLevel} 
              level={character.level}
              showLabel={false}
              size="sm"
            />
            <div className="flex justify-between mt-0.5">
              <span className="text-[10px] text-muted-foreground">
                Level {character.level}
              </span>
              <span className="text-[10px] text-xp">
                {character.xp}/{character.xpToNextLevel} XP
              </span>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  )
}
