'use client'

import { motion } from 'framer-motion'

interface XPBarProps {
  current: number
  max: number
  level: number
  showLabel?: boolean
  size?: 'sm' | 'md' | 'lg'
}

export function XPBar({ current, max, showLabel = true, size = 'md' }: XPBarProps) {
  const percentage = Math.min((current / max) * 100, 100)
  
  const heights = {
    sm: 'h-1.5',
    md: 'h-2',
    lg: 'h-2.5'
  }

  return (
    <div className="w-full">
      {showLabel && (
        <div className="flex justify-between items-center mb-1">
          <span className="text-[11px] text-muted-foreground">
            Progress
          </span>
          <span className="text-[11px] text-xp tabular-nums">
            {current.toLocaleString()} / {max.toLocaleString()} XP
          </span>
        </div>
      )}
      <div className={`relative ${heights[size]} bg-secondary rounded-full overflow-hidden`}>
        <motion.div
          className="absolute inset-y-0 left-0 bg-gradient-to-r from-xp to-gold rounded-full"
          initial={{ width: 0 }}
          animate={{ width: `${percentage}%` }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
        />
      </div>
    </div>
  )
}
