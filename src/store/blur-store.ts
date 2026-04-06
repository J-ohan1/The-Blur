import { create } from 'zustand'

interface BlurState {
  // App phase: landing -> welcome -> main
  phase: 'landing' | 'welcome' | 'main'

  // Navigation
  activeNav: string
  navItems: string[]

  // User info
  username: string
  isWhitelisted: boolean
  isTemporaryWhitelisted: boolean
  headshotUrl: string

  // UI toggles
  showProfileDropdown: boolean
  showEasterEgg: boolean

  // Easter egg: click version 3 times in 2 seconds
  easterEggClicks: number
  lastEasterEggClick: number

  // Time tracking
  startTime: number
  timeSpent: number

  // Actions
  enterPanel: () => void
  setActiveNav: (nav: string) => void
  toggleProfileDropdown: () => void
  closeProfileDropdown: () => void
  checkEasterEgg: () => void
  closeEasterEgg: () => void
  updateTimeSpent: () => void
  getTimeSpent: () => string
  resetEasterEgg: () => void
}

export const useBlurStore = create<BlurState>((set, get) => ({
  // Phase
  phase: 'landing',

  // Nav
  activeNav: 'Home',
  navItems: ['Home', 'Lasers', 'Effects', 'Settings'],

  // User
  username: 'Johan',
  isWhitelisted: true,
  isTemporaryWhitelisted: false,
  headshotUrl: '',

  // UI
  showProfileDropdown: false,
  showEasterEgg: false,

  // Easter egg
  easterEggClicks: 0,
  lastEasterEggClick: 0,

  // Time
  startTime: Date.now(),
  timeSpent: 0,

  // Actions
  enterPanel: () => {
    set({ phase: 'welcome' })
    setTimeout(() => {
      set({ phase: 'main', startTime: Date.now() })
    }, 2500)
  },

  setActiveNav: (nav: string) => {
    set({ activeNav: nav, showProfileDropdown: false })
  },

  toggleProfileDropdown: () => {
    set((s) => ({ showProfileDropdown: !s.showProfileDropdown }))
  },

  closeProfileDropdown: () => {
    set({ showProfileDropdown: false })
  },

  checkEasterEgg: () => {
    const now = Date.now()
    const { easterEggClicks, lastEasterEggClick } = get()
    const timeDiff = now - lastEasterEggClick

    if (timeDiff < 2000) {
      const newCount = easterEggClicks + 1
      if (newCount >= 3) {
        set({ showEasterEgg: true, easterEggClicks: 0, lastEasterEggClick: 0 })
      } else {
        set({ easterEggClicks: newCount, lastEasterEggClick: now })
      }
    } else {
      set({ easterEggClicks: 1, lastEasterEggClick: now })
    }
  },

  closeEasterEgg: () => {
    set({ showEasterEgg: false })
  },

  resetEasterEgg: () => {
    set({ easterEggClicks: 0, lastEasterEggClick: 0 })
  },

  updateTimeSpent: () => {
    const { phase, startTime } = get()
    if (phase === 'main') {
      set({ timeSpent: Math.floor((Date.now() - startTime) / 1000) })
    }
  },

  getTimeSpent: () => {
    const { timeSpent } = get()
    const hours = Math.floor(timeSpent / 3600)
    const minutes = Math.floor((timeSpent % 3600) / 60)
    const seconds = timeSpent % 60

    if (hours > 0) {
      return `${hours}h ${minutes}m ${seconds}s`
    }
    if (minutes > 0) {
      return `${minutes}m ${seconds}s`
    }
    return `${seconds}s`
  },
}))
