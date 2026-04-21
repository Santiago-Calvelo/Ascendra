'use client'

import { motion } from 'framer-motion'
import { Lock } from 'lucide-react'
import type { Achievement } from '@/lib/game-types'

interface AchievementsProps {
  achievements: Achievement[]
}

export function Achievements({ achievements }: AchievementsProps) {
  const unlockedCount = achievements.filter(a => a.unlocked).length

  return (
    <div className="space-y-3">
      {/* Summary */}
      <div className="bg-card rounded-xl p-4 border border-border flex items-center justify-between">
        <span className="text-sm text-muted-foreground">Progress</span>
        <span className="text-sm font-medium text-foreground">
          <span className="text-gold">{unlockedCount}</span>/{achievements.length} unlocked
        </span>
      </div>

      {/* Grid */}
      <div className="grid grid-cols-2 gap-2">
        {achievements.map((achievement, index) => (
          <AchievementCard key={achievement.id} achievement={achievement} index={index} />
        ))}
      </div>
    </div>
  )
}

interface AchievementCardProps {
  achievement: Achievement
  index: number
}

function AchievementCard({ achievement, index }: AchievementCardProps) {
  const progress = (achievement.progress / achievement.target) * 100

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay: index * 0.03 }}
      className={`bg-card rounded-xl p-3 border ${
        achievement.unlocked ? 'border-gold/30' : 'border-border'
      }`}
    >
      {/* Icon */}
      <div className={`w-10 h-10 rounded-lg flex items-center justify-center text-xl mb-2 ${
        achievement.unlocked ? 'bg-gold/20' : 'bg-secondary'
      }`}>
        {achievement.unlocked ? achievement.icon : <Lock className="w-4 h-4 text-muted-foreground" />}
      </div>

      {/* Info */}
      <h4 className={`text-sm font-medium mb-0.5 ${
        achievement.unlocked ? 'text-gold' : 'text-foreground'
      }`}>
        {achievement.name}
      </h4>
      <p className="text-[11px] text-muted-foreground line-clamp-2 mb-2">
        {achievement.description}
      </p>

      {/* Progress */}
      {!achievement.unlocked && (
        <div>
          <div className="h-1 bg-secondary rounded-full overflow-hidden">
            <motion.div
              className="h-full bg-gold/50 rounded-full"
              initial={{ width: 0 }}
              animate={{ width: `${progress}%` }}
              transition={{ delay: index * 0.03 + 0.1 }}
            />
          </div>
          <span className="text-[10px] text-muted-foreground mt-0.5 block">
            {achievement.progress}/{achievement.target}
          </span>
        </div>
      )}

      {achievement.unlocked && (
        <span className="text-[10px] text-gold font-medium">Unlocked</span>
      )}
    </motion.div>
  )
}
