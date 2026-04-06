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

export const BEAMS_PER_FIXTURE = 15

export interface LaserGroup {
  id: string
  name: string
  mode: 'fixture' | 'individual'
  selectedFixtures: number[]
  selectedBeams: string[]
  createdAt: number
}

export interface FaderValue {
  value: number // 0-255
}

interface BlurState {
  // App phase
  phase: 'landing' | 'welcome' | 'main'
  activePanel: 'home' | 'control' | 'player' | 'group' | 'customisation'

  // Current user
  currentUser: PlayerData
  players: PlayerData[]

  // Player panel
  playerSearch: string
  playerFilter: PlayerRole | 'all'
  toasts: ToastMessage[]

  // Group panel
  groups: LaserGroup[]
  selectedGroupId: string | null
  groupModalOpen: boolean
  editingGroupId: string | null
  groupMode: 'fixture' | 'individual'
  selectedFixtures: number[]
  selectedBeams: string[]
  groupNameInput: string
  deleteConfirmId: string | null

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
  tiltDirection: number // -1 left, 0 center, 1 right
  panDirection: number // -1 left, 0 center, 1 right

  // Customisation panel
  customisation: {
    colorHue: number
    colorSaturation: number
    colorBrightness: number
    faders: Record<string, number> // phase, speed, iris, dimmer, wing, tilt, pan, brightness, zoom
  }

  // Actions
  enterPanel: () => void
  setActivePanel: (panel: 'home' | 'control' | 'player' | 'group' | 'customisation') => void
  toggleProfileDropdown: () => void
  closeProfileDropdown: () => void
  checkEasterEgg: () => void
  closeEasterEgg: () => void
  updateTimeSpent: () => void
  getTimeSpent: () => string
  addToast: (text: string, type: 'warning' | 'success' | 'error') => void
  dismissToast: (id: string) => void

  // Control
  setMasterOnOff: (v: boolean) => void
  setHoldOnOff: (v: boolean) => void
  setFadeOnOff: (v: boolean) => void
  setHoldFadeOnOff: (v: boolean) => void
  setSelectedEffect: (id: string | null) => void
  setTiltDirection: (dir: number) => void
  setPanDirection: (dir: number) => void

  // Player panel
  setPlayerSearch: (v: string) => void
  setPlayerFilter: (v: PlayerRole | 'all') => void
  whitelistPlayer: (targetId: string) => void
  removePlayer: (targetId: string) => void
  kickPlayer: (targetId: string) => void

  // Group panel
  setSelectedGroupId: (id: string | null) => void
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
  getSelectedGroup: () => LaserGroup | null

  // Customisation
  setCustomColor: (hue: number, sat: number, brightness: number) => void
  setCustomFader: (name: string, value: number) => void
  applyOddEven: (mode: 'odd' | 'even') => void
  applyLeftRight: (mode: 'left' | 'right') => void
  applyQuickColor: (color: string) => void
  applyColorPattern: (pattern: string) => void
}

/* ─── Role helpers ───────────────────────────────── */

export function roleDotColor(role: PlayerRole): string {
  switch (role) {
    case 'staff': return 'bg-white shadow-[0_0_4px_rgba(255,255,255,0.4)]'
    case 'hardcoded_whitelist': return 'bg-neutral-300 shadow-[0_0_4px_rgba(163,163,163,0.4)]'
    case 'temp_whitelist': return 'bg-neutral-500 shadow-[0_0_4px_rgba(115,115,115,0.4)]'
    case 'normal': return 'bg-neutral-600'
    case 'blacklisted': return 'bg-neutral-800 shadow-[0_0_4px_rgba(38,38,38,0.6)]'
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

/* ─── Name validation (comprehensive content filter) ── */

// Comprehensive forbidden patterns covering profanity, sexual content, slurs, self-harm, etc.
const FORBIDDEN_PATTERNS = [
  // Sexual / explicit
  /\b(sex|sexual|intercourse|coitus|oral|anal|vaginal|genital|penis|vagina|clitoris|ejaculat|orgasm|masturbat|porn|porno|pornography|erotic|hentai|nude|naked|nudity|fetish|kink|bondage|sadomasoch| bdsm|threesome|orgy|prostitut|escort|stripper|rape|molest|pedophil|pedophile|child.?molest|minor.?sex|underage.?sex)\b/i,
  /\b(fuck|shit|ass|bitch|damn|crap|dick|cock|piss|slut|whore|cunt|twat|wanker|bastard|motherfucker|cocksucker|dumbass|jackass|goddamn|asshole|dipshit|bullshit|dumbfuck|shithead|asshat|douche|douchebag)\b/i,
  // Slurs
  /\b(nigger|nigga|negro|chink|gook|spic|wetback|kike|faggot|fag|tranny|retard|retarded|mongoloid|cripple|midget)\b/i,
  // Self-harm / violence
  /\b(kill\s?(yourself|urself|myself)|kys|suicide|self.?harm|self.?injur|cut\s?(myself|yourself|wrists)|hang\s?(myself|yourself)|overdose|end\s?my\s?life|no\s?reason\s?to\s?live|unalive|unaliving)\b/i,
  // Drugs
  /\b(heroin|cocaine|methamphetamine|meth|marijuana|weed|lsd|ecstasy|mdma|crack|fentanyl|opioid|drug\s?abuse|drug\s?addict|shoot\s?up)\b/i,
  // Hate speech
  /\b(heil\s?hitler|white\s?supremac|nazi|ethnic.?cleans|genocide|holocaust|lynch|lynching|gas\s?chamber)\b/i,
  // Cheating/exploiting
  /\b(hack|exploit|cheat|inject|script.?exec|loadstring|executor|cheat\s?engine)\b/i,
  // Misc profanity / bypass attempts
  /\b(milf|dilf|gilf|cum|semen|sperm|scat|bestialit|zoophilia|necrophil|incest|pedophile|groomer|grooming|predator)\b/i,
  /\b(suck\s?(my|it|your)\s?(dick|cock)|eat\s?(my|a)\s?(ass|dick)|fuck\s?(you|off|this|that)|go\s?die|go\s?kill\s?yourself)\b/i,
  // Number/letter bypass patterns for common words
  /\b(s[e3]x[ty]?\w*|f[u4]ck\w*|sh[i1]t\w*|n[i1]gg[e3]r\w*|f[a4]g[go0]t\w*|r[e3]t[a4]rd\w*|p[e3]d[o0]ph[i1]l\w*)/i,
]

// Additional word-level check for fragments and bypasses
const FORBIDDEN_WORDS = [
  'sex', 'fuck', 'shit', 'damn', 'bitch', 'ass', 'dick', 'cock', 'cunt', 'slut', 'whore',
  'nigger', 'nigga', 'faggot', 'fag', 'retard', 'retarded', 'rape', 'molest', 'pedophil',
  'kill yourself', 'kys', 'suicide', 'self-harm', 'porn', 'hentai', 'nude', 'naked',
  'heroin', 'cocaine', 'meth', 'lsd', 'ecstasy', 'genocide', 'incest', 'bestiality',
  'groomer', 'grooming', 'predator', 'prostitute', 'escort', 'orgasm', 'masturbat',
  'penis', 'vagina', 'anal', 'oral', 'bdsm', 'bondage', 'fetish', 'erotic',
  'milf', 'cum', 'semen', 'sperm', 'necrophil', 'zoophilia', 'scat',
  'heil hitler', 'nazi', 'white supremacist',
]

export function validateGroupName(name: string): { valid: boolean; reason: string } {
  const trimmed = name.trim()
  if (trimmed.length === 0) return { valid: false, reason: 'Group name is required' }
  if (trimmed.length < 2) return { valid: false, reason: 'Name must be at least 2 characters' }
  if (trimmed.length > 30) return { valid: false, reason: 'Name must be 30 characters or less' }

  // Check regex patterns
  for (const pattern of FORBIDDEN_PATTERNS) {
    if (pattern.test(trimmed)) return { valid: false, reason: 'Name contains inappropriate content' }
  }

  // Check word-level (case-insensitive, includes multi-word phrases)
  const lower = trimmed.toLowerCase()
  // Remove common separators for bypass detection
  const stripped = lower.replace(/[\s\-_.]+/g, '')
  for (const word of FORBIDDEN_WORDS) {
    const wordStripped = word.replace(/\s+/g, '')
    if (lower.includes(word.toLowerCase()) || stripped.includes(wordStripped)) {
      return { valid: false, reason: 'Name contains inappropriate content' }
    }
  }

  // Only allow alphanumeric, spaces, hyphens, underscores
  if (!/^[a-zA-Z0-9\s\-_]+$/.test(trimmed)) {
    return { valid: false, reason: 'Name can only contain letters, numbers, spaces, hyphens, and underscores' }
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
  selectedGroupId: null,
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
  tiltDirection: 0,
  panDirection: 0,

  // Customisation
  customisation: {
    colorHue: 0,
    colorSaturation: 100,
    colorBrightness: 100,
    faders: {
      phase: 128,
      speed: 128,
      iris: 255,
      dimmer: 255,
      wing: 128,
      tilt: 128,
      pan: 128,
      brightness: 255,
      zoom: 128,
    },
  },

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

  addToast: (text: string, type: 'warning' | 'success' | 'error') => {
    const id = `toast-${++toastIdCounter}`
    set((s) => ({ toasts: [...s.toasts, { id, text, type }] }))
    setTimeout(() => get().dismissToast(id), 3000)
  },

  dismissToast: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),

  // Control
  setMasterOnOff: (v) => {
    const { groups, selectedGroupId } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ masterOnOff: v })
  },
  setHoldOnOff: (v) => {
    const { groups, selectedGroupId } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ holdOnOff: v })
  },
  setFadeOnOff: (v) => {
    const { groups, selectedGroupId } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ fadeOnOff: v })
  },
  setHoldFadeOnOff: (v) => {
    const { groups, selectedGroupId } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ holdFadeOnOff: v })
  },
  setSelectedEffect: (id) => {
    if (id !== null) {
      const { groups, selectedGroupId } = get()
      if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
      if (!selectedGroupId) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    }
    set({ selectedEffect: id })
  },
  setTiltDirection: (dir) => {
    const { groups, selectedGroupId } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ tiltDirection: dir })
  },
  setPanDirection: (dir) => {
    const { groups, selectedGroupId } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ panDirection: dir })
  },

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

  // Group panel
  setSelectedGroupId: (id) => set({ selectedGroupId: id }),

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
    const { editingGroupId, groupNameInput, groupMode, selectedFixtures, selectedBeams, groups, selectedGroupId } = get()
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
    const { groups, selectedGroupId } = get()
    const group = groups.find((g) => g.id === id)
    set({ groups: groups.filter((g) => g.id !== id), deleteConfirmId: null, selectedGroupId: selectedGroupId === id ? null : selectedGroupId })
    get().addToast(`Group "${group?.name}" deleted`, 'success')
  },

  confirmDeleteGroup: (id) => set({ deleteConfirmId: id }),
  cancelDeleteGroup: () => set({ deleteConfirmId: null }),

  getSelectedGroup: () => {
    const { groups, selectedGroupId } = get()
    if (!selectedGroupId) return null
    return groups.find((g) => g.id === selectedGroupId) ?? null
  },

  // Customisation
  setCustomColor: (hue, sat, brightness) => {
    set((s) => ({
      customisation: {
        ...s.customisation,
        colorHue: hue,
        colorSaturation: sat,
        colorBrightness: brightness,
      },
    }))
  },

  setCustomFader: (name, value) => {
    set((s) => ({
      customisation: {
        ...s.customisation,
        faders: { ...s.customisation.faders, [name]: value },
      },
    }))
  },

  applyOddEven: (mode) => {
    const { groups, selectedGroupId, addToast } = get()
    if (groups.length === 0) { addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { addToast('No group selected to perform the operation.', 'warning'); return }
    addToast(`${mode === 'odd' ? 'Odd' : 'Even'} selection applied`, 'success')
  },

  applyLeftRight: (mode) => {
    const { groups, selectedGroupId, addToast } = get()
    if (groups.length === 0) { addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { addToast('No group selected to perform the operation.', 'warning'); return }
    addToast(`${mode === 'left' ? 'Left' : 'Right'} selection applied`, 'success')
  },

  applyQuickColor: (color) => {
    const { groups, selectedGroupId, addToast } = get()
    if (groups.length === 0) { addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { addToast('No group selected to perform the operation.', 'warning'); return }
    addToast(`Color applied`, 'success')
  },

  applyColorPattern: (pattern) => {
    const { groups, selectedGroupId, addToast } = get()
    if (groups.length === 0) { addToast('No groups. Please create a group first.', 'warning'); return }
    if (!selectedGroupId) { addToast('No group selected to perform the operation.', 'warning'); return }
    addToast(`Color pattern applied`, 'success')
  },
}))
