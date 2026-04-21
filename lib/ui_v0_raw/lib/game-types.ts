export type ZoneType = 'comfort' | 'normal' | 'growth'

export type ActivityType = 'steps' | 'cardio' | 'gym' | 'focus'

export interface Stats {
  strength: number
  discipline: number
  endurance: number
  wisdom: number
}

export interface Character {
  name: string
  level: number
  xp: number
  xpToNextLevel: number
  stats: Stats
  title: string
  avatar: string
}

export interface Exercise {
  id: string
  name: string
  sets: ExerciseSet[]
}

export interface ExerciseSet {
  id: string
  reps: number
  weight: number
  completed: boolean
}

export interface Task {
  id: string
  name: string
  description: string
  zone: ZoneType
  activityType: ActivityType
  progress: number
  target: number
  xpReward: number
  statReward: keyof Stats
  statAmount: number
  completed: boolean
  exercises?: Exercise[]
  duration?: number // for focus/cardio in minutes
}

export interface LeaderboardEntry {
  id: string
  name: string
  level: number
  xpToday: number
  avatar: string
  isCurrentUser?: boolean
  isRival?: boolean
}

export interface Achievement {
  id: string
  name: string
  description: string
  icon: string
  unlocked: boolean
  progress: number
  target: number
}

// Mock data
export const mockCharacter: Character = {
  name: 'Shadowblade',
  level: 12,
  xp: 2450,
  xpToNextLevel: 3000,
  stats: {
    strength: 24,
    discipline: 18,
    endurance: 21,
    wisdom: 15
  },
  title: 'Iron Sentinel',
  avatar: '⚔️'
}

export const mockTasks: Task[] = [
  {
    id: '1',
    name: 'Morning March',
    description: 'Walk 5,000 steps to warm up your body',
    zone: 'comfort',
    activityType: 'steps',
    progress: 3200,
    target: 5000,
    xpReward: 50,
    statReward: 'endurance',
    statAmount: 2,
    completed: false
  },
  {
    id: '2',
    name: 'Forge of Iron',
    description: 'Complete your gym routine',
    zone: 'normal',
    activityType: 'gym',
    progress: 0,
    target: 1,
    xpReward: 150,
    statReward: 'strength',
    statAmount: 3,
    completed: false,
    exercises: [
      {
        id: 'e1',
        name: 'Bench Press',
        sets: [
          { id: 's1', reps: 10, weight: 135, completed: false },
          { id: 's2', reps: 8, weight: 155, completed: false },
          { id: 's3', reps: 6, weight: 175, completed: false }
        ]
      },
      {
        id: 'e2',
        name: 'Squats',
        sets: [
          { id: 's4', reps: 12, weight: 185, completed: false },
          { id: 's5', reps: 10, weight: 205, completed: false },
          { id: 's6', reps: 8, weight: 225, completed: false }
        ]
      },
      {
        id: 'e3',
        name: 'Deadlift',
        sets: [
          { id: 's7', reps: 8, weight: 225, completed: false },
          { id: 's8', reps: 6, weight: 275, completed: false },
          { id: 's9', reps: 4, weight: 315, completed: false }
        ]
      }
    ]
  },
  {
    id: '3',
    name: 'Mind Sanctuary',
    description: 'Deep focus session - 45 minutes',
    zone: 'growth',
    activityType: 'focus',
    progress: 0,
    target: 45,
    xpReward: 200,
    statReward: 'wisdom',
    statAmount: 4,
    completed: false,
    duration: 45
  },
  {
    id: '4',
    name: 'Endurance Trial',
    description: '30 minutes of cardio training',
    zone: 'growth',
    activityType: 'cardio',
    progress: 0,
    target: 30,
    xpReward: 180,
    statReward: 'endurance',
    statAmount: 5,
    completed: false,
    duration: 30
  }
]

export const mockLeaderboard: LeaderboardEntry[] = [
  { id: '1', name: 'DragonSlayer', level: 28, xpToday: 850, avatar: '🐉' },
  { id: '2', name: 'IronWill', level: 25, xpToday: 720, avatar: '🛡️' },
  { id: '3', name: 'Shadowblade', level: 12, xpToday: 450, avatar: '⚔️', isCurrentUser: true },
  { id: '4', name: 'StormBringer', level: 14, xpToday: 380, avatar: '⚡', isRival: true },
  { id: '5', name: 'MoonWatcher', level: 10, xpToday: 290, avatar: '🌙' },
  { id: '6', name: 'FlameHeart', level: 9, xpToday: 210, avatar: '🔥' },
  { id: '7', name: 'FrostBite', level: 8, xpToday: 150, avatar: '❄️' },
]

export const mockAchievements: Achievement[] = [
  { id: '1', name: 'First Blood', description: 'Complete your first quest', icon: '🗡️', unlocked: true, progress: 1, target: 1 },
  { id: '2', name: 'Iron Body', description: 'Reach 50 strength', icon: '💪', unlocked: false, progress: 24, target: 50 },
  { id: '3', name: 'Marathon Runner', description: 'Walk 100,000 steps total', icon: '🏃', unlocked: false, progress: 45000, target: 100000 },
  { id: '4', name: 'Zen Master', description: 'Complete 30 focus sessions', icon: '🧘', unlocked: false, progress: 12, target: 30 },
  { id: '5', name: 'Weekly Warrior', description: 'Complete all daily tasks for 7 days', icon: '📅', unlocked: true, progress: 7, target: 7 },
  { id: '6', name: 'Champion', description: 'Reach level 25', icon: '👑', unlocked: false, progress: 12, target: 25 },
]
