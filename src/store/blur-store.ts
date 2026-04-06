import { create } from 'zustand'

/* ─── Types ─────────────────────────────────────── */

export type PlayerRole = 'staff' | 'hardcoded_whitelist' | 'temp_whitelist' | 'normal' | 'blacklisted'

export interface PlayerData {
  id: string
  name: string
  role: PlayerRole
}

interface EffectItem {
  id: string
  name: string
  category: 'wave' | 'chase' | 'pattern' | 'color' | 'advanced'
}

interface ToastMessage {
  id: string
  text: string
  type: 'warning' | 'success' | 'error'
}

// Each "laser fixture" has 15 beams
export const BEAMS_PER_FIXTURE = 15

export interface LaserGroup {
  id: string
  name: string
  mode: 'fixture' | 'individual'
  // fixture mode: which fixture numbers are selected (1, 2, 3...)
  selectedFixtures: number[]
  // individual mode: which specific beams are selected e.g. "3-7" means fixture 3 beam 7
  selectedBeams: string[]
  createdAt: number
}

interface BlurState {
  // App phase
  phase: 'landing' | 'welcome' | 'main'
  activePanel: 'home' | 'control' | 'player' | 'group'

  // Current user
  currentUser: PlayerData
  players: PlayerData[]

  // Player panel
  playerSearch: string
  playerFilter: PlayerRole | 'all'
  toasts: ToastMessage[]

  // Group panel
  groups: LaserGroup[]
  groupModalOpen: boolean  // false = list view, true = creating/editing
  editingGroupId: string | null  // null = new, string = editing
  groupMode: 'fixture' | 'individual'
  selectedFixtures: number[]
  selectedBeams: string[]
  groupNameInput: string
  deleteConfirmId: string | null  // which group is awaiting delete confirmation

  // UI
  showProfileDropdown: boolean
  showEasterEgg: boolean

  // Easter egg
  easterEggClicks: number
  lastEasterEggClick: number

  // Time
  startTime: number
  timeSpent: number

  // Control Panel
  masterOnOff: boolean
  holdOnOff: boolean
  fadeOnOff: boolean
  holdFadeOnOff: boolean
  selectedEffect: string | null
  effects: EffectItem[]

  // Actions
  enterPanel: () => void
  setActivePanel: (panel: 'home' | 'control' | 'player' | 'group') => void
  toggleProfileDropdown: () => void
  closeProfileDropdown: () => void
  checkEasterEgg: () => void
  closeEasterEgg: () => void
  updateTimeSpent: () => void
  getTimeSpent: () => string

  // Control
  setMasterOnOff: (v: boolean) => void
  setHoldOnOff: (v: boolean) => void
  setFadeOnOff: (v: boolean) => void
  setHoldFadeOnOff: (v: boolean) => void
  setSelectedEffect: (id: string | null) => void

  // Player panel
  setPlayerSearch: (v: string) => void
  setPlayerFilter: (v: PlayerRole | 'all') => void
  whitelistPlayer: (targetId: string) => void
  removePlayer: (targetId: string) => void
  kickPlayer: (targetId: string) => void
  dismissToast: (id: string) => void

  // Group panel
  openGroupModal: (editId?: string) => void
  closeGroupModal: () => void
  setGroupMode: (mode: 'fixture' | 'individual') => void
  toggleFixture: (fixtureNum: number) => void
  toggleBeam: (beamKey: string) => void
  setGroupNameInput: (v: string) => void
  saveGroup: () => void
  deleteGroup: (id: string) => void
  confirmDeleteGroup: (id: string) => void
  cancelDeleteGroup: () => void
}

/* ─── Role helpers ───────────────────────────────── */

export function roleDotColor(role: PlayerRole): string {
  switch (role) {
    case 'staff': return 'bg-blue-400 shadow-[0_0_6px_rgba(96,165,250,0.6)]'
    case 'hardcoded_whitelist': return 'bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.6)]'
    case 'temp_whitelist': return 'bg-yellow-400 shadow-[0_0_6px_rgba(250,204,21,0.6)]'
    case 'normal': return 'bg-neutral-300'
    case 'blacklisted': return 'bg-red-500 shadow-[0_0_6px_rgba(239,68,68,0.6)]'
  }
}

export function roleLabel(role: PlayerRole): string {
  switch (role) {
    case 'staff': return 'Staff'
    case 'hardcoded_whitelist': return 'Whitelisted'
    case 'temp_whitelist': return 'Temp Whitelisted'
    case 'normal': return 'Player'
    case 'blacklisted': return 'Blacklisted'
  }
}

/* ─── Permission logic ───────────────────────────── */

type Action = 'whitelist' | 'remove' | 'kick'

export function canPerform(
  viewerRole: PlayerRole,
  targetRole: PlayerRole,
  action: Action
): { allowed: boolean; reason: string } {
  if (viewerRole === 'staff') {
    if (action === 'remove' && targetRole === 'hardcoded_whitelist') return { allowed: false, reason: "Can't remove hardcoded whitelisted users" }
    if (action === 'whitelist' && targetRole === 'staff') return { allowed: false, reason: 'Staff is already at the highest rank' }
    if (action === 'kick' && (targetRole === 'staff' || targetRole === 'hardcoded_whitelist')) return { allowed: false, reason: targetRole === 'staff' ? "Can't kick staff" : "Can't kick hardcoded whitelisted users" }
    if (action === 'remove' && targetRole === 'staff') return { allowed: false, reason: "Can't remove staff" }
    return { allowed: true, reason: '' }
  }
  if (viewerRole === 'hardcoded_whitelist') {
    if (targetRole === 'staff') return { allowed: false, reason: "Can't perform actions on staff" }
    if (targetRole === 'hardcoded_whitelist') return { allowed: false, reason: "Can't perform actions on whitelisted users" }
    if (action === 'remove' && targetRole === 'hardcoded_whitelist') return { allowed: false, reason: "Can't remove whitelisted users" }
    return { allowed: true, reason: '' }
  }
  return { allowed: false, reason: 'Lack of authorities' }
}

export function getActiveButtons(targetRole: PlayerRole): { whitelist: boolean; remove: boolean; kick: boolean } {
  if (targetRole === 'temp_whitelist') return { whitelist: false, remove: true, kick: true }
  return { whitelist: true, remove: false, kick: true }
}

/* ─── Name validation ────────────────────────────── */

const FORBIDDEN_PATTERNS = [
  /\b(fuck|shit|ass|bitch|damn|crap|dick|cock|piss|slut|whore|nigger|nigga|retard|faggot)\b/i,
  /\b(kill\s?(yourself|urself)|kys|suicide|self.harm)\b/i,
  /\b(hack|exploit|cheat|inject)\b/i,
]

export function validateGroupName(name: string): { valid: boolean; reason: string } {
  const trimmed = name.trim()
  if (trimmed.length === 0) return { valid: false, reason: 'Group name is required' }
  if (trimmed.length < 2) return { valid: false, reason: 'Name must be at least 2 characters' }
  if (trimmed.length > 30) return { valid: false, reason: 'Name must be 30 characters or less' }
  for (const pattern of FORBIDDEN_PATTERNS) {
    if (pattern.test(trimmed)) return { valid: false, reason: 'Name contains inappropriate content' }
  }
  return { valid: true, reason: '' }
}

/* ─── Effects data ───────────────────────────────── */

export const EFFECTS: EffectItem[] = [
  { id: 'strobe', name: 'Strobe', category: 'pattern' },
  { id: 'rand-individual', name: 'Random Individual', category: 'pattern' },
  { id: 'rand-fixture', name: 'Random Fixture', category: 'pattern' },
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
  { id: 'chase', name: 'Chase', category: 'chase' },
  { id: 'chase-reverse', name: 'Chase Reverse', category: 'chase' },
  { id: 'chase-comet', name: 'Chase Comet', category: 'chase' },
  { id: 'alternate', name: 'Alternate', category: 'pattern' },
  { id: 'center-out', name: 'Center Out', category: 'pattern' },
  { id: 'center-in', name: 'Center In', category: 'pattern' },
  { id: 'split', name: 'Split', category: 'pattern' },
  { id: 'collision', name: 'Collision', category: 'pattern' },
  { id: 'cascade', name: 'Cascade', category: 'pattern' },
  { id: 'twinkle', name: 'Twinkle', category: 'pattern' },
  { id: 'rainbow-cycle', name: 'Rainbow Cycle', category: 'color' },
  { id: 'color-wash', name: 'Color Wash', category: 'color' },
  { id: 'color-bounce', name: 'Color Bounce', category: 'color' },
  { id: 'meteor', name: 'Meteor', category: 'advanced' },
  { id: 'breathing', name: 'Breathing', category: 'advanced' },
  { id: 'flicker', name: 'Flicker', category: 'advanced' },
  { id: 'sparkle', name: 'Sparkle', category: 'advanced' },
  { id: 'firework', name: 'Firework', category: 'advanced' },
  { id: 'explosion', name: 'Explosion', category: 'advanced' },
  { id: 'stacking', name: 'Stacking', category: 'advanced' },
]

/* ─── Mock players ───────────────────────────────── */

const MOCK_PLAYERS: PlayerData[] = [
  { id: '1', name: 'Johan', role: 'staff' },
  { id: '2', name: 'Alex_Dev', role: 'hardcoded_whitelist' },
  { id: '3', name: 'LaserKing99', role: 'hardcoded_whitelist' },
  { id: '4', name: 'NightOwl', role: 'temp_whitelist' },
  { id: '5', name: 'PixelMaster', role: 'temp_whitelist' },
  { id: '6', name: 'SkyWalker', role: 'normal' },
  { id: '7', name: 'xXDragonXx', role: 'normal' },
  { id: '8', name: 'CoolBuilder', role: 'normal' },
  { id: '9', name: 'ShadowNinja', role: 'blacklisted' },
  { id: '10', name: 'ToxicGamer', role: 'blacklisted' },
  { id: '11', name: 'StarLight', role: 'normal' },
  { id: '12', name: 'BlueFlame', role: 'normal' },
]

/* ─── Store ──────────────────────────────────────── */

let toastIdCounter = 0

export const useBlurStore = create<BlurState>((set, get) => ({
  phase: 'landing',
  activePanel: 'home',

  currentUser: { id: '1', name: 'Johan', role: 'staff' },
  players: MOCK_PLAYERS,

  playerSearch: '',
  playerFilter: 'all',
  toasts: [],

  // Group
  groups: [],
  groupModalOpen: false,
  editingGroupId: null,
  groupMode: 'fixture',
  selectedFixtures: [],
  selectedBeams: [],
  groupNameInput: '',
  deleteConfirmId: null,

  // UI
  showProfileDropdown: false,
  showEasterEgg: false,
  easterEggClicks: 0,
  lastEasterEggClick: 0,
  startTime: Date.now(),
  timeSpent: 0,

  // Control
  masterOnOff: true,
  holdOnOff: false,
  fadeOnOff: false,
  holdFadeOnOff: false,
  selectedEffect: null,
  effects: EFFECTS,

  enterPanel: () => {
    set({ phase: 'welcome' })
    setTimeout(() => set({ phase: 'main', activePanel: 'home', startTime: Date.now() }), 2500)
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

  // Control
  setMasterOnOff: (v) => set({ masterOnOff: v }),
  setHoldOnOff: (v) => set({ holdOnOff: v }),
  setFadeOnOff: (v) => set({ fadeOnOff: v }),
  setHoldFadeOnOff: (v) => set({ holdFadeOnOff: v }),
  setSelectedEffect: (id) => set({ selectedEffect: id }),

  // Player panel
  setPlayerSearch: (v) => set({ playerSearch: v }),
  setPlayerFilter: (v) => set({ playerFilter: v }),

  whitelistPlayer: (targetId) => {
    const { currentUser, players } = get()
    const target = players.find((p) => p.id === targetId)
    if (!target) return
    const check = canPerform(currentUser.role, target.role, 'whitelist')
    if (!check.allowed) { get().addToast(check.reason, 'warning'); return }
    set({ players: players.map((p) => p.id === targetId ? { ...p, role: 'temp_whitelist' as const } : p) })
    get().addToast(`${target.name} has been temp whitelisted`, 'success')
  },

  removePlayer: (targetId) => {
    const { currentUser, players } = get()
    const target = players.find((p) => p.id === targetId)
    if (!target) return
    const check = canPerform(currentUser.role, target.role, 'remove')
    if (!check.allowed) { get().addToast(check.reason, 'warning'); return }
    set({ players: players.map((p) => p.id === targetId ? { ...p, role: 'normal' as const } : p) })
    get().addToast(`${target.name} has been removed`, 'success')
  },

  kickPlayer: (targetId) => {
    const { currentUser, players } = get()
    const target = players.find((p) => p.id === targetId)
    if (!target) return
    const check = canPerform(currentUser.role, target.role, 'kick')
    if (!check.allowed) { get().addToast(check.reason, 'warning'); return }
    set({ players: players.filter((p) => p.id !== targetId) })
    get().addToast(`${target.name} has been kicked`, 'success')
  },

  dismissToast: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),

  addToast: (text: string, type: 'warning' | 'success' | 'error') => {
    const id = `toast-${++toastIdCounter}`
    set((s) => ({ toasts: [...s.toasts, { id, text, type }] }))
    setTimeout(() => get().dismissToast(id), 3000)
  },

  // Group panel
  openGroupModal: (editId?: string) => {
    if (editId) {
      const group = get().groups.find((g) => g.id === editId)
      if (group) {
        set({
          groupModalOpen: true,
          editingGroupId: editId,
          groupMode: group.mode,
          selectedFixtures: [...group.selectedFixtures],
          selectedBeams: [...group.selectedBeams],
          groupNameInput: group.name,
        })
      }
    } else {
      set({
        groupModalOpen: true,
        editingGroupId: null,
        groupMode: 'fixture',
        selectedFixtures: [],
        selectedBeams: [],
        groupNameInput: '',
      })
    }
  },

  closeGroupModal: () => set({ groupModalOpen: false, editingGroupId: null }),

  setGroupMode: (mode) => set({ groupMode: mode, selectedFixtures: [], selectedBeams: [] }),

  toggleFixture: (num) => {
    const { selectedFixtures } = get()
    set({
      selectedFixtures: selectedFixtures.includes(num)
        ? selectedFixtures.filter((n) => n !== num)
        : [...selectedFixtures, num],
    })
  },

  toggleBeam: (key) => {
    const { selectedBeams } = get()
    set({
      selectedBeams: selectedBeams.includes(key)
        ? selectedBeams.filter((k) => k !== key)
        : [...selectedBeams, key],
    })
  },

  setGroupNameInput: (v) => set({ groupNameInput: v }),

  saveGroup: () => {
    const { editingGroupId, groupNameInput, groupMode, selectedFixtures, selectedBeams, groups } = get()
    const validation = validateGroupName(groupNameInput)
    if (!validation.valid) { get().addToast(validation.reason, 'warning'); return }

    const selected = groupMode === 'fixture' ? selectedFixtures : selectedBeams
    if (selected.length === 0) { get().addToast('Select at least one laser or beam', 'warning'); return }

    if (editingGroupId) {
      set({
        groups: groups.map((g) => g.id === editingGroupId ? {
          ...g, name: groupNameInput.trim(), mode: groupMode,
          selectedFixtures: [...selectedFixtures], selectedBeams: [...selectedBeams],
        } : g),
        groupModalOpen: false, editingGroupId: null,
      })
      get().addToast('Group updated', 'success')
    } else {
      const newGroup: LaserGroup = {
        id: `group-${Date.now()}`,
        name: groupNameInput.trim(),
        mode: groupMode,
        selectedFixtures: [...selectedFixtures],
        selectedBeams: [...selectedBeams],
        createdAt: Date.now(),
      }
      set({ groups: [...groups, newGroup], groupModalOpen: false })
      get().addToast(`Group "${newGroup.name}" created`, 'success')
    }
  },

  deleteGroup: (id) => {
    const { groups } = get()
    const group = groups.find((g) => g.id === id)
    set({ groups: groups.filter((g) => g.id !== id), deleteConfirmId: null })
    get().addToast(`Group "${group?.name}" deleted`, 'success')
  },

  confirmDeleteGroup: (id) => set({ deleteConfirmId: id }),
  cancelDeleteGroup: () => set({ deleteConfirmId: null }),
}))
