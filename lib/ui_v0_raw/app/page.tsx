'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { CharacterHeader } from '@/components/game/character-header'
import { TaskCard } from '@/components/game/task-card'
import { TaskDetail } from '@/components/game/task-detail'
import { CharacterSheet } from '@/components/game/character-sheet'
import { Leaderboard } from '@/components/game/leaderboard'
import { Achievements } from '@/components/game/achievements'
import { BottomNav, type TabType } from '@/components/game/bottom-nav'
import { 
  mockCharacter, 
  mockTasks, 
  mockLeaderboard, 
  mockAchievements,
  type Task,
  type Character
} from '@/lib/game-types'

export default function HabitQuestApp() {
  const [activeTab, setActiveTab] = useState<TabType>('quests')
  const [selectedTask, setSelectedTask] = useState<Task | null>(null)
  const [character, setCharacter] = useState<Character>(mockCharacter)
  const [tasks, setTasks] = useState<Task[]>(mockTasks)

  const handleTaskComplete = (completedTask: Task) => {
    setTasks(prev => prev.map(t => 
      t.id === completedTask.id ? { ...t, completed: true } : t
    ))
    setCharacter(prev => ({
      ...prev,
      xp: prev.xp + completedTask.xpReward,
      stats: {
        ...prev.stats,
        [completedTask.statReward]: prev.stats[completedTask.statReward] + completedTask.statAmount
      }
    }))
  }

  if (selectedTask) {
    return (
      <TaskDetail 
        task={selectedTask} 
        onBack={() => setSelectedTask(null)}
        onComplete={handleTaskComplete}
      />
    )
  }

  return (
    <div className="min-h-screen bg-background pb-20">
      <AnimatePresence mode="wait">
        {activeTab === 'quests' && (
          <motion.div
            key="quests"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            {/* Header */}
            <div className="pt-safe">
              <div className="py-4">
                <CharacterHeader character={character} />
              </div>
            </div>

            {/* Quests */}
            <div className="px-4">
              <div className="flex items-center justify-between mb-3">
                <h2 className="text-sm font-medium text-muted-foreground uppercase tracking-wide">
                  Daily Quests
                </h2>
                <span className="text-xs text-muted-foreground">
                  {tasks.filter(t => t.completed).length}/{tasks.length}
                </span>
              </div>

              <div className="space-y-2">
                {tasks.map((task, index) => (
                  <TaskCard 
                    key={task.id} 
                    task={task} 
                    index={index}
                    onSelect={setSelectedTask}
                  />
                ))}
              </div>
            </div>
          </motion.div>
        )}

        {activeTab === 'character' && (
          <motion.div
            key="character"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="pt-safe">
              <div className="p-4">
                <h1 className="text-lg font-semibold text-foreground mb-4">Character</h1>
                <CharacterSheet character={character} />
              </div>
            </div>
          </motion.div>
        )}

        {activeTab === 'leaderboard' && (
          <motion.div
            key="leaderboard"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="pt-safe">
              <div className="p-4">
                <h1 className="text-lg font-semibold text-foreground mb-4">Arena</h1>
                <Leaderboard entries={mockLeaderboard} />
              </div>
            </div>
          </motion.div>
        )}

        {activeTab === 'achievements' && (
          <motion.div
            key="achievements"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="pt-safe">
              <div className="p-4">
                <h1 className="text-lg font-semibold text-foreground mb-4">Achievements</h1>
                <Achievements achievements={mockAchievements} />
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />
    </div>
  )
}
