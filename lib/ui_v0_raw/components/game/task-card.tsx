'use client'

import { motion } from 'framer-motion'
import { Footprints, Dumbbell, Timer, Brain, ChevronRight, Check } from 'lucide-react'
import type { Task, ZoneType, ActivityType, Stats } from '@/lib/game-types'

interface TaskCardProps {
  task: Task
  onSelect: (task: Task) => void
  index: number
}

const zoneAccents: Record<ZoneType, string> = {
  comfort: 'border-l-comfort',
  normal: 'border-l-normal',
  growth: 'border-l-growth'
}

const activityIcons: Record<ActivityType, React.ElementType> = {
  steps: Footprints,
  cardio: Timer,
  gym: Dumbbell,
  focus: Brain
}

const statColors: Record<keyof Stats, string> = {
  strength: 'text-destructive',
  discipline: 'text-primary',
  endurance: 'text-stamina',
  wisdom: 'text-mana'
}

export function TaskCard({ task, onSelect, index }: TaskCardProps) {
  const ActivityIcon = activityIcons[task.activityType]
  const progress = Math.min((task.progress / task.target) * 100, 100)

  return (
    <motion.button
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05 }}
      whileTap={{ scale: 0.98 }}
      onClick={() => onSelect(task)}
      disabled={task.completed}
      className={`
        w-full text-left bg-card rounded-lg border border-border
        border-l-[3px] ${zoneAccents[task.zone]}
        ${task.completed ? 'opacity-50' : 'active:bg-card/80'}
        transition-colors
      `}
    >
      <div className="p-3">
        {/* Top row: icon, name, chevron */}
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-secondary/50 flex items-center justify-center shrink-0">
            {task.completed ? (
              <Check className="w-4 h-4 text-comfort" />
            ) : (
              <ActivityIcon className="w-4 h-4 text-foreground/70" />
            )}
          </div>
          
          <div className="flex-1 min-w-0">
            <h3 className="font-medium text-foreground text-[15px] leading-tight truncate">
              {task.name}
            </h3>
            <div className="flex items-center gap-2 mt-0.5">
              <span className="text-xs text-xp font-medium">+{task.xpReward} XP</span>
              <span className="text-muted-foreground/40">·</span>
              <span className={`text-xs font-medium ${statColors[task.statReward]}`}>
                +{task.statAmount} {task.statReward.slice(0, 3).toUpperCase()}
              </span>
            </div>
          </div>

          {!task.completed && (
            <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0" />
          )}
        </div>

        {/* Progress bar */}
        {!task.completed && (
          <div className="mt-3 pl-12">
            <div className="flex items-center gap-2">
              <div className="flex-1 h-1.5 bg-secondary rounded-full overflow-hidden">
                <motion.div
                  className={`h-full rounded-full ${
                    task.zone === 'comfort' ? 'bg-comfort' :
                    task.zone === 'normal' ? 'bg-normal' : 'bg-growth'
                  }`}
                  initial={{ width: 0 }}
                  animate={{ width: `${progress}%` }}
                  transition={{ duration: 0.5, ease: 'easeOut' }}
                />
              </div>
              <span className="text-[11px] text-muted-foreground tabular-nums w-8 text-right">
                {Math.round(progress)}%
              </span>
            </div>
          </div>
        )}
      </div>
    </motion.button>
  )
}
