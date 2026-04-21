'use client'

import { useState, useEffect, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Play, Pause, RotateCcw, Check, X } from 'lucide-react'

interface TimerProps {
  duration: number
  onComplete: () => void
  type: 'focus' | 'rest'
  onCancel?: () => void
}

export function Timer({ duration, onComplete, type, onCancel }: TimerProps) {
  const [timeLeft, setTimeLeft] = useState(duration)
  const [isRunning, setIsRunning] = useState(false)
  const [isComplete, setIsComplete] = useState(false)

  const percentage = ((duration - timeLeft) / duration) * 100

  useEffect(() => {
    let interval: NodeJS.Timeout | null = null
    if (isRunning && timeLeft > 0) {
      interval = setInterval(() => {
        setTimeLeft((prev) => {
          if (prev <= 1) {
            setIsRunning(false)
            setIsComplete(true)
            onComplete()
            return 0
          }
          return prev - 1
        })
      }, 1000)
    }
    return () => { if (interval) clearInterval(interval) }
  }, [isRunning, timeLeft, onComplete])

  const formatTime = useCallback((seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }, [])

  const handleReset = () => {
    setTimeLeft(duration)
    setIsRunning(false)
    setIsComplete(false)
  }

  const isFocus = type === 'focus'
  const accentColor = isFocus ? 'text-mana' : 'text-comfort'
  const bgColor = isFocus ? 'bg-mana' : 'bg-comfort'

  return (
    <div className="flex flex-col items-center py-4">
      {/* Timer Circle */}
      <div className="relative w-48 h-48 mb-6">
        <svg className="w-full h-full -rotate-90" viewBox="0 0 100 100">
          <circle
            cx="50"
            cy="50"
            r="45"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-secondary"
          />
          <motion.circle
            cx="50"
            cy="50"
            r="45"
            fill="none"
            strokeWidth="3"
            strokeLinecap="round"
            className={`stroke-current ${accentColor}`}
            strokeDasharray={283}
            animate={{ strokeDashoffset: 283 - (283 * percentage) / 100 }}
            transition={{ duration: 0.5 }}
          />
        </svg>

        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <AnimatePresence mode="wait">
            {isComplete ? (
              <motion.div
                key="complete"
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                className="flex flex-col items-center"
              >
                <div className="w-12 h-12 rounded-full bg-comfort/20 flex items-center justify-center mb-1">
                  <Check className="w-6 h-6 text-comfort" />
                </div>
                <span className="text-comfort font-medium text-sm">Done!</span>
              </motion.div>
            ) : (
              <motion.div
                key="timer"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="text-center"
              >
                <span className="text-4xl font-mono font-bold text-foreground">
                  {formatTime(timeLeft)}
                </span>
                <span className="text-xs text-muted-foreground block mt-1 capitalize">
                  {type}
                </span>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Controls */}
      {!isComplete ? (
        <div className="flex items-center gap-3">
          {onCancel && (
            <button
              onClick={onCancel}
              className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center text-muted-foreground hover:text-foreground"
            >
              <X className="w-4 h-4" />
            </button>
          )}

          <button
            onClick={handleReset}
            className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center text-muted-foreground hover:text-foreground"
          >
            <RotateCcw className="w-4 h-4" />
          </button>

          <button
            onClick={() => setIsRunning(!isRunning)}
            className={`w-14 h-14 rounded-full ${bgColor} flex items-center justify-center text-white`}
          >
            {isRunning ? (
              <Pause className="w-6 h-6" />
            ) : (
              <Play className="w-6 h-6 ml-0.5" />
            )}
          </button>
        </div>
      ) : (
        <button
          onClick={handleReset}
          className="px-4 py-2 bg-comfort text-white rounded-lg text-sm font-medium"
        >
          Restart
        </button>
      )}
    </div>
  )
}
