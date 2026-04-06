import { create } from 'zustand'

interface EffectItem {
  id: string
  name: string
  category: 'wave' | 'chase' | 'pattern' | 'color' | 'advanced'
}

interface BlurState {
  // App phase: landing -> welcome -> main
  phase: 'landing' | 'welcome' | 'main'

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

  // Control Panel toggles
  masterOnOff: boolean
  holdOnOff: boolean
  fadeOnOff: boolean
  holdFadeOnOff: boolean

  // Selected effect
  selectedEffect: string | null

  // All effects
  effects: EffectItem[]

  // Actions
  enterPanel: () => void
  toggleProfileDropdown: () => void
  closeProfileDropdown: () => void
  checkEasterEgg: () => void
  closeEasterEgg: () => void
  updateTimeSpent: () => void
  getTimeSpent: () => string

  // Control Panel actions
  setMasterOnOff: (v: boolean) => void
  setHoldOnOff: (v: boolean) => void
  setFadeOnOff: (v: boolean) => void
  setHoldFadeOnOff: (v: boolean) => void
  setSelectedEffect: (id: string | null) => void
}

export const EFFECTS: EffectItem[] = [
  // Strobe
  { id: 'strobe', name: 'Strobe', category: 'pattern' },
  // Random
  { id: 'rand-individual', name: 'Random Individual', category: 'pattern' },
  { id: 'rand-fixture', name: 'Random Fixture', category: 'pattern' },
  // Waves (15)
  { id: 'wave-up', name: 'Wave Up', category: 'wave' },
  { id: 'wave-down', name: 'Wave Down', category: 'wave' },
  { id: 'wave-in', name: 'Wave In', category: 'wave' },
  { id: 'wave-out', name: 'Wave Out', category: 'wave' },
  { id: 'wave-left', name: 'Wave Left', category: 'wave' },
  { id: 'wave-right', name: 'Wave Right', category: 'wave' },
  { id: 'wave-circular', name: 'Wave Circular', category: 'wave' },
  { id: 'wave-spiral', name: 'Wave Spiral', category: 'wave' },
  { id: 'wave-rainbow', name: 'Wave Rainbow', category: 'wave' },
  { id: 'wave-sequential', name: 'Wave Sequential', category: 'wave' },
  { id: 'wave-reverse', name: 'Wave Reverse', category: 'wave' },
  { id: 'wave-random', name: 'Wave Random', category: 'wave' },
  { id: 'wave-pulse', name: 'Wave Pulse', category: 'wave' },
  { id: 'wave-sinusoidal', name: 'Wave Sinusoidal', category: 'wave' },
  // Chase
  { id: 'chase', name: 'Chase', category: 'chase' },
  { id: 'chase-reverse', name: 'Chase Reverse', category: 'chase' },
  { id: 'chase-comet', name: 'Chase Comet', category: 'chase' },
  // Pattern
  { id: 'alternate', name: 'Alternate', category: 'pattern' },
  { id: 'center-out', name: 'Center Out', category: 'pattern' },
  { id: 'center-in', name: 'Center In', category: 'pattern' },
  { id: 'split', name: 'Split', category: 'pattern' },
  { id: 'collision', name: 'Collision', category: 'pattern' },
  { id: 'cascade', name: 'Cascade', category: 'pattern' },
  { id: 'twinkle', name: 'Twinkle', category: 'pattern' },
  // Color
  { id: 'rainbow-cycle', name: 'Rainbow Cycle', category: 'color' },
  { id: 'color-wash', name: 'Color Wash', category: 'color' },
  { id: 'color-bounce', name: 'Color Bounce', category: 'color' },
  // Advanced
  { id: 'meteor', name: 'Meteor', category: 'advanced' },
  { id: 'breathing', name: 'Breathing', category: 'advanced' },
  { id: 'flicker', name: 'Flicker', category: 'advanced' },
  { id: 'sparkle', name: 'Sparkle', category: 'advanced' },
  { id: 'firework', name: 'Firework', category: 'advanced' },
  { id: 'explosion', name: 'Explosion', category: 'advanced' },
  { id: 'stacking', name: 'Stacking', category: 'advanced' },
]

export const useBlurStore = create<BlurState>((set, get) => ({
  // Phase
  phase: 'landing',

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

  // Control Panel toggles
  masterOnOff: true,
  holdOnOff: false,
  fadeOnOff: false,
  holdFadeOnOff: false,

  // Selected effect
  selectedEffect: null,

  // Effects list
  effects: EFFECTS,

  // Actions
  enterPanel: () => {
    set({ phase: 'welcome' })
    setTimeout(() => {
      set({ phase: 'main', startTime: Date.now() })
    }, 2500)
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

    if (hours > 0) return `${hours}h ${minutes}m ${seconds}s`
    if (minutes > 0) return `${minutes}m ${seconds}s`
    return `${seconds}s`
  },

  // Control Panel actions
  setMasterOnOff: (v) => set({ masterOnOff: v }),
  setHoldOnOff: (v) => set({ holdOnOff: v }),
  setFadeOnOff: (v) => set({ fadeOnOff: v }),
  setHoldFadeOnOff: (v) => set({ holdFadeOnOff: v }),
  setSelectedEffect: (id) => set({ selectedEffect: id }),
}))
