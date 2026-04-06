import { create } from 'zustand'

interface EffectItem {
  id: string
  name: string
  category: 'wave' | 'chase' | 'pattern' | 'color' | 'advanced'
}

interface BlurState {
  // App phase: landing -> welcome -> main
  phase: 'landing' | 'welcome' | 'main'

  // Navigation: which panel is active
  activePanel: 'home' | 'control'

  // User info
  username: string
  isWhitelisted: boolean
  isTemporaryWhitelisted: boolean

  // UI toggles
  showProfileDropdown: boolean
  showEasterEgg: boolean

  // Easter egg
  easterEggClicks: number
  lastEasterEggClick: number

  // Time tracking
  startTime: number
  timeSpent: number

  // Control Panel — hold button states (only true while mouse is held)
  holdOnOff: boolean
  holdFadeOnOff: boolean

  // Selected effect
  selectedEffect: string | null

  // Effects list
  effects: EffectItem[]

  // Actions
  enterPanel: () => void
  setActivePanel: (panel: 'home' | 'control') => void
  toggleProfileDropdown: () => void
  closeProfileDropdown: () => void
  checkEasterEgg: () => void
  closeEasterEgg: () => void
  updateTimeSpent: () => void
  getTimeSpent: () => string
  setHoldOnOff: (v: boolean) => void
  setHoldFadeOnOff: (v: boolean) => void
  setSelectedEffect: (id: string | null) => void
}

export const EFFECTS: EffectItem[] = [
  { id: 'strobe', name: 'Strobe', category: 'pattern' },
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
  phase: 'landing',
  activePanel: 'home',

  username: 'Johan',
  isWhitelisted: true,
  isTemporaryWhitelisted: false,

  showProfileDropdown: false,
  showEasterEgg: false,

  easterEggClicks: 0,
  lastEasterEggClick: 0,

  startTime: Date.now(),
  timeSpent: 0,

  holdOnOff: false,
  holdFadeOnOff: false,

  selectedEffect: null,
  effects: EFFECTS,

  enterPanel: () => {
    set({ phase: 'welcome' })
    setTimeout(() => {
      set({ phase: 'main', activePanel: 'home', startTime: Date.now() })
    }, 2500)
  },

  setActivePanel: (panel) => set({ activePanel: panel, showProfileDropdown: false }),

  toggleProfileDropdown: () => set((s) => ({ showProfileDropdown: !s.showProfileDropdown })),
  closeProfileDropdown: () => set({ showProfileDropdown: false }),

  checkEasterEgg: () => {
    const now = Date.now()
    const { easterEggClicks, lastEasterEggClick } = get()
    if (now - lastEasterEggClick < 2000) {
      const count = easterEggClicks + 1
      if (count >= 3) {
        set({ showEasterEgg: true, easterEggClicks: 0, lastEasterEggClick: 0 })
      } else {
        set({ easterEggClicks: count, lastEasterEggClick: now })
      }
    } else {
      set({ easterEggClicks: 1, lastEasterEggClick: now })
    }
  },

  closeEasterEgg: () => set({ showEasterEgg: false }),

  updateTimeSpent: () => {
    const { phase, startTime } = get()
    if (phase === 'main') set({ timeSpent: Math.floor((Date.now() - startTime) / 1000) })
  },

  getTimeSpent: () => {
    const { timeSpent } = get()
    const h = Math.floor(timeSpent / 3600)
    const m = Math.floor((timeSpent % 3600) / 60)
    const s = timeSpent % 60
    if (h > 0) return `${h}h ${m}m ${s}s`
    if (m > 0) return `${m}m ${s}s`
    return `${s}s`
  },

  setHoldOnOff: (v) => set({ holdOnOff: v }),
  setHoldFadeOnOff: (v) => set({ holdFadeOnOff: v }),
  setSelectedEffect: (id) => set({ selectedEffect: id }),
}))
