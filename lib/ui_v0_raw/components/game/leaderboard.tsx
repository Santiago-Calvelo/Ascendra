'use client'

import { motion } from 'framer-motion'
import { Crown, Swords } from 'lucide-react'
import type { LeaderboardEntry } from '@/lib/game-types'

interface LeaderboardProps {
  entries: LeaderboardEntry[]
}

export function Leaderboard({ entries }: LeaderboardProps) {
  const sortedEntries = [...entries].sort((a, b) => b.xpToday - a.xpToday)
  const currentUser = sortedEntries.find(e => e.isCurrentUser)
  const currentUserRank = currentUser ? sortedEntries.indexOf(currentUser) + 1 : 0

  return (
    <div className="space-y-3">
      {/* Your rank */}
      <div className="flex items-center gap-3 bg-primary/10 rounded-xl p-4 border border-primary/20">
        <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center text-lg font-bold text-primary">
          #{currentUserRank}
        </div>
        <div className="flex-1">
          <span className="text-sm text-foreground font-medium">Your Rank</span>
          <span className="text-xs text-muted-foreground block">{currentUser?.xpToday || 0} XP today</span>
        </div>
      </div>

      {/* Leaderboard */}
      <div className="bg-card rounded-xl border border-border overflow-hidden">
        <div className="p-3 border-b border-border">
          <span className="text-xs font-medium text-muted-foreground uppercase tracking-wide">Daily Rankings</span>
        </div>

        <div className="divide-y divide-border">
          {sortedEntries.map((entry, index) => (
            <LeaderboardRow 
              key={entry.id} 
              entry={entry} 
              rank={index + 1}
              index={index}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

interface LeaderboardRowProps {
  entry: LeaderboardEntry
  rank: number
  index: number
}

function LeaderboardRow({ entry, rank, index }: LeaderboardRowProps) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ delay: index * 0.03 }}
      className={`flex items-center gap-3 p-3 ${
        entry.isCurrentUser ? 'bg-primary/5' : ''
      }`}
    >
      {/* Rank */}
      <div className={`w-7 text-center text-sm font-medium ${
        rank === 1 ? 'text-gold' : rank === 2 ? 'text-foreground/70' : rank === 3 ? 'text-accent' : 'text-muted-foreground'
      }`}>
        {rank === 1 ? <Crown className="w-4 h-4 mx-auto" /> : rank}
      </div>

      {/* Avatar */}
      <div className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center text-sm">
        {entry.avatar}
      </div>

      {/* Name */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-1.5">
          <span className={`text-sm font-medium truncate ${
            entry.isCurrentUser ? 'text-primary' : 'text-foreground'
          }`}>
            {entry.name}
          </span>
          {entry.isRival && <Swords className="w-3 h-3 text-growth shrink-0" />}
        </div>
        <span className="text-[11px] text-muted-foreground">Lv.{entry.level}</span>
      </div>

      {/* XP */}
      <span className="text-sm font-semibold text-xp tabular-nums">{entry.xpToday}</span>
    </motion.div>
  )
}
