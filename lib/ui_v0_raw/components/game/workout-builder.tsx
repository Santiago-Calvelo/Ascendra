'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Plus, Minus, Check, ChevronDown, ChevronUp, Timer as TimerIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import type { Exercise, ExerciseSet } from '@/lib/game-types'
import { Timer } from './timer'

interface WorkoutBuilderProps {
  exercises: Exercise[]
  onComplete: () => void
  onExerciseUpdate: (exercises: Exercise[]) => void
}

export function WorkoutBuilder({ exercises, onComplete, onExerciseUpdate }: WorkoutBuilderProps) {
  const [expandedExercise, setExpandedExercise] = useState<string | null>(exercises[0]?.id || null)
  const [showRestTimer, setShowRestTimer] = useState(false)
  const [restDuration, setRestDuration] = useState(90)

  const toggleSet = (exerciseId: string, setId: string) => {
    const updated = exercises.map(ex => {
      if (ex.id === exerciseId) {
        return {
          ...ex,
          sets: ex.sets.map(set => 
            set.id === setId ? { ...set, completed: !set.completed } : set
          )
        }
      }
      return ex
    })
    onExerciseUpdate(updated)

    const exercise = updated.find(e => e.id === exerciseId)
    const completedSet = exercise?.sets.find(s => s.id === setId)
    if (completedSet?.completed) {
      setShowRestTimer(true)
    }
  }

  const updateSet = (exerciseId: string, setId: string, field: keyof ExerciseSet, value: number) => {
    const updated = exercises.map(ex => {
      if (ex.id === exerciseId) {
        return {
          ...ex,
          sets: ex.sets.map(set => 
            set.id === setId ? { ...set, [field]: value } : set
          )
        }
      }
      return ex
    })
    onExerciseUpdate(updated)
  }

  const addSet = (exerciseId: string) => {
    const updated = exercises.map(ex => {
      if (ex.id === exerciseId) {
        const lastSet = ex.sets[ex.sets.length - 1]
        return {
          ...ex,
          sets: [...ex.sets, {
            id: `s${Date.now()}`,
            reps: lastSet?.reps || 10,
            weight: lastSet?.weight || 0,
            completed: false
          }]
        }
      }
      return ex
    })
    onExerciseUpdate(updated)
  }

  const removeSet = (exerciseId: string, setId: string) => {
    const updated = exercises.map(ex => {
      if (ex.id === exerciseId && ex.sets.length > 1) {
        return {
          ...ex,
          sets: ex.sets.filter(set => set.id !== setId)
        }
      }
      return ex
    })
    onExerciseUpdate(updated)
  }

  const totalSets = exercises.reduce((acc, ex) => acc + ex.sets.length, 0)
  const completedSets = exercises.reduce((acc, ex) => acc + ex.sets.filter(s => s.completed).length, 0)
  const allComplete = completedSets === totalSets

  if (showRestTimer) {
    return (
      <div className="bg-card rounded-xl p-6 border border-border">
        <h3 className="text-center font-semibold text-foreground mb-4">Rest</h3>
        <Timer 
          duration={restDuration} 
          type="rest" 
          onComplete={() => setShowRestTimer(false)}
          onCancel={() => setShowRestTimer(false)}
        />
        <div className="flex items-center justify-center gap-2 mt-4">
          {[60, 90, 120].map(sec => (
            <button
              key={sec}
              onClick={() => setRestDuration(sec)}
              className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                restDuration === sec 
                  ? 'bg-primary text-primary-foreground' 
                  : 'bg-secondary text-foreground'
              }`}
            >
              {sec}s
            </button>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      {/* Progress */}
      <div className="bg-card rounded-xl p-4 border border-border">
        <div className="flex items-center justify-between text-sm mb-2">
          <span className="text-muted-foreground">Progress</span>
          <span className="font-medium text-foreground">{completedSets}/{totalSets}</span>
        </div>
        <div className="h-2 bg-secondary rounded-full overflow-hidden">
          <motion.div
            className="h-full bg-growth rounded-full"
            animate={{ width: `${(completedSets / totalSets) * 100}%` }}
          />
        </div>
      </div>

      {/* Exercises */}
      {exercises.map((exercise) => {
        const isExpanded = expandedExercise === exercise.id
        const exerciseComplete = exercise.sets.every(s => s.completed)
        
        return (
          <div
            key={exercise.id}
            className={`bg-card rounded-xl border overflow-hidden ${
              exerciseComplete ? 'border-comfort/40' : 'border-border'
            }`}
          >
            <button
              onClick={() => setExpandedExercise(isExpanded ? null : exercise.id)}
              className="w-full p-4 flex items-center justify-between"
            >
              <div className="flex items-center gap-3">
                <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${
                  exerciseComplete ? 'bg-comfort/20 text-comfort' : 'bg-secondary text-foreground/70'
                }`}>
                  {exerciseComplete ? <Check className="w-4 h-4" /> : 
                    <span className="text-xs font-medium">{exercise.sets.filter(s => s.completed).length}/{exercise.sets.length}</span>
                  }
                </div>
                <span className="font-medium text-foreground">{exercise.name}</span>
              </div>
              {isExpanded ? (
                <ChevronUp className="w-4 h-4 text-muted-foreground" />
              ) : (
                <ChevronDown className="w-4 h-4 text-muted-foreground" />
              )}
            </button>

            <AnimatePresence>
              {isExpanded && (
                <motion.div
                  initial={{ height: 0 }}
                  animate={{ height: 'auto' }}
                  exit={{ height: 0 }}
                  className="overflow-hidden"
                >
                  <div className="px-4 pb-4 space-y-2">
                    {exercise.sets.map((set, setIndex) => (
                      <div
                        key={set.id}
                        className={`flex items-center gap-2 p-2.5 rounded-lg ${
                          set.completed ? 'bg-comfort/10' : 'bg-secondary/50'
                        }`}
                      >
                        <span className="w-6 text-xs font-medium text-muted-foreground text-center">
                          {setIndex + 1}
                        </span>
                        
                        <div className="flex-1 grid grid-cols-2 gap-2">
                          <div>
                            <label className="text-[10px] text-muted-foreground">LBS</label>
                            <input
                              type="number"
                              value={set.weight}
                              onChange={(e) => updateSet(exercise.id, set.id, 'weight', Number(e.target.value))}
                              className="w-full bg-transparent text-foreground font-medium focus:outline-none"
                              disabled={set.completed}
                            />
                          </div>
                          <div>
                            <label className="text-[10px] text-muted-foreground">REPS</label>
                            <input
                              type="number"
                              value={set.reps}
                              onChange={(e) => updateSet(exercise.id, set.id, 'reps', Number(e.target.value))}
                              className="w-full bg-transparent text-foreground font-medium focus:outline-none"
                              disabled={set.completed}
                            />
                          </div>
                        </div>

                        <button
                          onClick={() => toggleSet(exercise.id, set.id)}
                          className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${
                            set.completed 
                              ? 'bg-comfort text-white' 
                              : 'bg-growth/20 text-growth'
                          }`}
                        >
                          <Check className="w-4 h-4" />
                        </button>

                        {exercise.sets.length > 1 && !set.completed && (
                          <button
                            onClick={() => removeSet(exercise.id, set.id)}
                            className="w-6 h-6 flex items-center justify-center text-muted-foreground hover:text-destructive shrink-0"
                          >
                            <Minus className="w-3 h-3" />
                          </button>
                        )}
                      </div>
                    ))}

                    <button
                      onClick={() => addSet(exercise.id)}
                      className="w-full py-2 flex items-center justify-center gap-1.5 text-sm text-muted-foreground hover:text-foreground border border-dashed border-border rounded-lg"
                    >
                      <Plus className="w-3 h-3" />
                      Add Set
                    </button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )
      })}

      {/* Actions */}
      <div className="flex gap-2 pt-2">
        <Button
          variant="outline"
          className="flex-1"
          onClick={() => setShowRestTimer(true)}
        >
          <TimerIcon className="w-4 h-4 mr-1.5" />
          Rest
        </Button>
        
        {allComplete && (
          <Button onClick={onComplete} className="flex-1 bg-comfort hover:bg-comfort/90">
            <Check className="w-4 h-4 mr-1.5" />
            Complete
          </Button>
        )}
      </div>
    </div>
  )
}
