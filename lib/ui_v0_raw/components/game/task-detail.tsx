'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ArrowLeft, Sword, Brain, Heart, Zap, Play, Check } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Timer } from './timer'
import { WorkoutBuilder } from './workout-builder'
import type { Task, Stats, Exercise } from '@/lib/game-types'

interface TaskDetailProps {
  task: Task
  onBack: () => void
  onComplete: (task: Task) => void
}

const statIcons: Record<keyof Stats, React.ElementType> = {
  strength: Sword,
  discipline: Brain,
  endurance: Heart,
  wisdom: Zap
}

const statColors: Record<keyof Stats, string> = {
  strength: 'text-destructive',
  discipline: 'text-primary',
  endurance: 'text-stamina',
  wisdom: 'text-mana'
}

const zoneBg: Record<string, string> = {
  comfort: 'bg-comfort',
  normal: 'bg-normal',
  growth: 'bg-growth'
}

export function TaskDetail({ task, onBack, onComplete }: TaskDetailProps) {
  const [isActive, setIsActive] = useState(false)
  const [exercises, setExercises] = useState<Exercise[]>(task.exercises || [])
  const [isCompleted, setIsCompleted] = useState(task.completed)

  const StatIcon = statIcons[task.statReward]

  const handleComplete = () => {
    setIsCompleted(true)
    onComplete(task)
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="sticky top-0 z-20 bg-background/95 backdrop-blur-sm border-b border-border pt-safe">
        <div className="flex items-center gap-3 px-4 h-14">
          <button 
            onClick={onBack}
            className="w-9 h-9 flex items-center justify-center rounded-full hover:bg-secondary transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <div className="flex-1 min-w-0">
            <h1 className="font-semibold text-foreground truncate">{task.name}</h1>
            <p className="text-xs text-muted-foreground capitalize">{task.zone} zone</p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-4 pb-24">
        <AnimatePresence mode="wait">
          {isCompleted ? (
            <motion.div
              key="completed"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="bg-card rounded-xl p-8 text-center border border-comfort/30"
            >
              <div className="w-16 h-16 mx-auto rounded-full bg-comfort/20 flex items-center justify-center mb-4">
                <Check className="w-8 h-8 text-comfort" />
              </div>
              <h3 className="text-lg font-semibold text-foreground mb-1">Quest Complete</h3>
              <p className="text-sm text-muted-foreground mb-6">
                +{task.xpReward} XP · +{task.statAmount} {task.statReward}
              </p>
              <Button onClick={onBack} variant="outline">
                Return to Quests
              </Button>
            </motion.div>
          ) : !isActive ? (
            <motion.div
              key="start"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="space-y-4"
            >
              {/* Rewards */}
              <div className="bg-card rounded-xl p-4 border border-border">
                <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wide mb-3">
                  Rewards
                </h3>
                <div className="flex items-center gap-6">
                  <div>
                    <span className="text-2xl font-bold text-xp">+{task.xpReward}</span>
                    <span className="text-sm text-muted-foreground ml-1">XP</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <StatIcon className={`w-5 h-5 ${statColors[task.statReward]}`} />
                    <span className={`text-2xl font-bold ${statColors[task.statReward]}`}>
                      +{task.statAmount}
                    </span>
                    <span className="text-sm text-muted-foreground capitalize">{task.statReward}</span>
                  </div>
                </div>
              </div>

              {/* Task details */}
              {task.activityType === 'gym' && task.exercises && (
                <div className="bg-card rounded-xl p-4 border border-border">
                  <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wide mb-3">
                    Exercises
                  </h3>
                  <div className="space-y-2">
                    {task.exercises.map((exercise) => (
                      <div key={exercise.id} className="flex items-center justify-between py-1.5">
                        <span className="text-sm text-foreground">{exercise.name}</span>
                        <span className="text-xs text-muted-foreground">{exercise.sets.length} sets</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {(task.activityType === 'focus' || task.activityType === 'cardio') && (
                <div className="bg-card rounded-xl p-4 border border-border">
                  <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wide mb-3">
                    Duration
                  </h3>
                  <div>
                    <span className="text-3xl font-bold text-foreground">{task.duration}</span>
                    <span className="text-muted-foreground ml-1">minutes</span>
                  </div>
                </div>
              )}

              {/* Start button */}
              <Button
                onClick={() => setIsActive(true)}
                className={`w-full h-14 text-base font-semibold ${zoneBg[task.zone]} hover:opacity-90 text-white`}
              >
                <Play className="w-5 h-5 mr-2" />
                Begin Quest
              </Button>
            </motion.div>
          ) : (
            <motion.div
              key="active"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              {task.activityType === 'gym' && exercises.length > 0 && (
                <WorkoutBuilder
                  exercises={exercises}
                  onExerciseUpdate={setExercises}
                  onComplete={handleComplete}
                />
              )}

              {(task.activityType === 'focus' || task.activityType === 'cardio') && task.duration && (
                <Timer
                  duration={task.duration * 60}
                  type={task.activityType === 'focus' ? 'focus' : 'rest'}
                  onComplete={handleComplete}
                  onCancel={() => setIsActive(false)}
                />
              )}

              {task.activityType === 'steps' && (
                <div className="bg-card rounded-xl p-6 text-center border border-border">
                  <div className="mb-4">
                    <span className="text-4xl font-bold text-foreground">{task.progress.toLocaleString()}</span>
                    <span className="text-muted-foreground"> / {task.target.toLocaleString()}</span>
                  </div>
                  <p className="text-sm text-muted-foreground mb-4">Steps tracked via Health</p>
                  {task.progress >= task.target && (
                    <Button onClick={handleComplete} className="bg-comfort hover:bg-comfort/90">
                      <Check className="w-4 h-4 mr-2" />
                      Claim Reward
                    </Button>
                  )}
                </div>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  )
}
