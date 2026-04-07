import { create } from 'zustand'
import { useEffectEditorStore } from './effect-editor-store'
import type { EffectType } from './effect-editor-store'

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

export interface HubEffect {
  id: string
  name: string
  authorName: string
  authorId: string
  type: EffectType
  tags: string[]
 downloads: number
  codeLines: string[]
 createdAt: number
}

export interface SavedPosition {
  id: string
  name: string
}

export interface Keybind {
  id: string
  label: string
  key: string           // e.g. "Q", "Shift+F", "Ctrl+1", etc.
  code: string          // e.g. "KeyQ", "ShiftLeft", "Digit1"
  action: string        // what it does — freeform description like "Toggle On/Off", "Activate Fan Out"
  category: 'toggle' | 'effect' | 'position' | 'custom'
}

export interface TimecodeCell {
  id: string
  type: 'effect' | 'toggle' | 'position' | 'wait'
  action: string
  label: string
  waitMultiplier: number // 1 = 1 beat, 0.5 = half, 2 = double
  duration: number // how many columns this cell spans (default 1)
}

export interface TimecodeTrack {
  groupId: string
  groupName: string
  cells: Record<number, TimecodeCell>
}

export interface SavedTimecode {
  id: string
  name: string
  bpm: number
  tracks: TimecodeTrack[]
  createdAt: number
}

interface BlurState {
  // App phase
  phase: 'landing' | 'welcome' | 'main'
  activePanel: 'home' | 'control' | 'player' | 'group' | 'customisation' | 'info' | 'effect' | 'hub' | 'keybind' | 'timecode'

  // Current user
  currentUser: PlayerData
  players: PlayerData[]

  // Player panel
  playerSearch: string
  playerFilter: PlayerRole | 'all'
  toasts: ToastMessage[]

  // Group panel
  groups: LaserGroup[]
  selectedGroupIds: string[]
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

  // Hub panel
  hubSearch: string
  hubFilter: 'all' | EffectType
  hubViewingUser: string | null  // authorId or null for all
  hubEffects: HubEffect[]

  // Position section (Control panel)
  positions: SavedPosition[]
  activePosition: string | null
  positionTimer: ReturnType<typeof setTimeout> | null

  // Keybinds
  keybinds: Keybind[]
  keybindListeningId: string | null  // ID of keybind currently listening for a key press

  // Timecode
  timecodeProjects: SavedTimecode[]
  activeTimecodeId: string | null
  timecodePlaying: boolean
  timecodeCurrentStep: number
  timecodeTimer: ReturnType<typeof setTimeout> | null

  // Customisation panel
  customisation: {
    colorHue: number
    colorSaturation: number
    colorBrightness: number
    faders: Record<string, number> // phase, speed, iris, dimmer, wing, tilt, pan, brightness, zoom
  }

  // Actions
  enterPanel: () => void
  setActivePanel: (panel: 'home' | 'control' | 'player' | 'group' | 'customisation' | 'info' | 'effect' | 'hub' | 'keybind') => void
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
  toggleGroupSelection: (id: string) => void
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

  // Hub panel
  setHubSearch: (v: string) => void
  setHubFilter: (v: 'all' | EffectType) => void
  viewHubUser: (authorId: string | null) => void
  addHubEffectToCustom: (hubEffect: HubEffect) => void

  // Position
  addPosition: (name: string) => void
  removePosition: (id: string) => void
  activatePosition: (id: string) => void

  // Keybinds
  addKeybind: (label: string, action: string, category: Keybind['category']) => void
  setKeybindKey: (id: string, key: string, code: string) => void
  removeKeybind: (id: string) => void
  startListening: (id: string) => void
  stopListening: () => void
  getKeybindByAction: (action: string) => Keybind | undefined

  // Timecode
  createTimecode: (name: string) => void
  deleteTimecode: (id: string) => void
  loadTimecode: (id: string) => void
  setTimecodeBpm: (bpm: number) => void
  setTimecodeName: (name: string) => void
  addTimecodeEntry: (groupId: string, col: number, entry: Omit<TimecodeCell, 'id' | 'duration'>) => void
  removeTimecodeEntry: (groupId: string, col: number) => void
  cycleWaitMultiplier: (groupId: string, col: number) => void
  resizeTimecodeEntry: (groupId: string, col: number, newDuration: number) => void
  playTimecode: () => void
  stopTimecode: () => void
  getActiveTimecode: () => SavedTimecode | undefined
}

/* ─── Role helpers ───────────────────────────────── */

export function roleDotColor(role: PlayerRole): string {
  switch (role) {
    case 'staff': return 'bg-blue-400 shadow-[0_0_6px_rgba(96,165,250,0.6)]'
    case 'hardcoded_whitelist': return 'bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.6)]'
    case 'temp_whitelist': return 'bg-yellow-400 shadow-[0_0_6px_rgba(250,204,21,0.6)]'
    case 'normal': return 'bg-neutral-400'
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

/* ─── Mock Hub Effects ─────────────────────────── */

const MOCK_HUB_EFFECTS: HubEffect[] = [
  { id: 'hub-1', name: 'Rainbow Storm', authorName: 'LaserKing99', authorId: '3', type: 'wave', tags: ['wave', 'color', 'rainbow'], downloads: 234, codeLines: ['beam.setTilt(frame)', 'beam.setColor(hue)'], createdAt: Date.now() - 86400000 * 5 },
  { id: 'hub-2', name: 'Midnight Chase', authorName: 'NightOwl', authorId: '4', type: 'chase', tags: ['chase', 'dark'], downloads: 187, codeLines: ['beam.sequence()'], createdAt: Date.now() - 86400000 * 3 },
  { id: 'hub-3', name: 'Hyper Strobe', authorName: 'PixelMaster', authorId: '5', type: 'strobe', tags: ['strobe', 'fast'], downloads: 312, codeLines: ['beam.strobe(50)'], createdAt: Date.now() - 86400000 * 7 },
  { id: 'hub-4', name: 'Ocean Wave', authorName: 'Alex_Dev', authorId: '2', type: 'wave', tags: ['wave', 'smooth'], downloads: 156, codeLines: ['wave.sin(0.5)'], createdAt: Date.now() - 86400000 * 2 },
  { id: 'hub-5', name: 'Fire Cascade', authorName: 'LaserKing99', authorId: '3', type: 'pattern', tags: ['pattern', 'fire'], downloads: 203, codeLines: ['cascade.fire()'], createdAt: Date.now() - 86400000 * 10 },
  { id: 'hub-6', name: 'Galaxy Spiral', authorName: 'StarLight', authorId: '11', type: 'movement', tags: ['movement', 'spiral'], downloads: 98, codeLines: ['beam.spiral(360)'], createdAt: Date.now() - 86400000 * 1 },
  { id: 'hub-7', name: 'Neon Bounce', authorName: 'NightOwl', authorId: '4', type: 'chase', tags: ['chase', 'color', 'bounce'], downloads: 145, codeLines: ['beam.bounce(15)'], createdAt: Date.now() - 86400000 * 4 },
  { id: 'hub-8', name: 'Heartbeat', authorName: 'PixelMaster', authorId: '5', type: 'pattern', tags: ['pattern', 'pulse'], downloads: 278, codeLines: ['pulse.heartbeat()'], createdAt: Date.now() - 86400000 * 8 },
  { id: 'hub-9', name: 'Thunder Strike', authorName: 'Alex_Dev', authorId: '2', type: 'strobe', tags: ['strobe', 'flash'], downloads: 167, codeLines: ['flash.strike()'], createdAt: Date.now() - 86400000 * 6 },
  { id: 'hub-10', name: 'Aurora Borealis', authorName: 'BlueFlame', authorId: '12', type: 'wave', tags: ['wave', 'color', 'aurora'], downloads: 421, codeLines: ['beam.aurora(7)'], createdAt: Date.now() - 86400000 * 12 },
  { id: 'hub-11', name: 'Matrix Rain', authorName: 'LaserKing99', authorId: '3', type: 'pattern', tags: ['pattern', 'rain'], downloads: 189, codeLines: ['rain.matrix()'], createdAt: Date.now() - 86400000 * 9 },
  { id: 'hub-12', name: 'Laser Sword', authorName: 'xXDragonXx', authorId: '7', type: 'movement', tags: ['movement', 'sword'], downloads: 256, codeLines: ['beam.sword(45)'], createdAt: Date.now() - 86400000 * 3 },
  { id: 'hub-13', name: 'Cosmic Dust', authorName: 'StarLight', authorId: '11', type: 'pattern', tags: ['pattern', 'sparkle'], downloads: 134, codeLines: ['dust.cosmic()'], createdAt: Date.now() - 86400000 * 5 },
  { id: 'hub-14', name: 'Vortex Spin', authorName: 'BlueFlame', authorId: '12', type: 'movement', tags: ['movement', 'vortex'], downloads: 298, codeLines: ['spin.vortex(720)'], createdAt: Date.now() - 86400000 * 2 },
  { id: 'hub-15', name: 'Pixel Storm', authorName: 'CoolBuilder', authorId: '8', type: 'strobe', tags: ['strobe', 'random'], downloads: 176, codeLines: ['random.pixel()'], createdAt: Date.now() - 86400000 * 4 },
  { id: 'hub-16', name: 'Sunset Fade', authorName: 'NightOwl', authorId: '4', type: 'custom', tags: ['color', 'fade', 'warm'], downloads: 145, codeLines: ['color.sunset(30)'], createdAt: Date.now() - 86400000 * 7 },
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
  selectedGroupIds: [],
  groupModalOpen: false,
  editingGroupId: null,
  groupMode: 'fixture',
  selectedFixtures: [],
  selectedBeams: [],
  groupNameInput: '',
  deleteConfirmId: null,

  // Hub
  hubSearch: '',
  hubFilter: 'all',
  hubViewingUser: null,
  hubEffects: MOCK_HUB_EFFECTS,

  // Position
  positions: [
    { id: 'pos-1', name: 'Fan Out' },
    { id: 'pos-2', name: 'Center' },
    { id: 'pos-3', name: 'Split' },
    { id: 'pos-4', name: 'Wave Line' },
    { id: 'pos-5', name: 'Symmetric' },
  ],
  activePosition: null,
  positionTimer: null,

  // Keybinds
  keybinds: [],
  keybindListeningId: null,

  // Timecode
  timecodeProjects: [],
  activeTimecodeId: null,
  timecodePlaying: false,
  timecodeCurrentStep: -1,
  timecodeTimer: null,

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
    const { groups, selectedGroupIds } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ masterOnOff: v })
  },
  setHoldOnOff: (v) => {
    const { groups, selectedGroupIds } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ holdOnOff: v })
  },
  setFadeOnOff: (v) => {
    const { groups, selectedGroupIds } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ fadeOnOff: v })
  },
  setHoldFadeOnOff: (v) => {
    const { groups, selectedGroupIds } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ holdFadeOnOff: v })
  },
  setSelectedEffect: (id) => {
    if (id !== null) {
      const { groups, selectedGroupIds } = get()
      if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
      if (selectedGroupIds.length === 0) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    }
    set({ selectedEffect: id })
  },
  setTiltDirection: (dir) => {
    const { groups, selectedGroupIds } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { get().addToast('No group selected to perform the operation.', 'warning'); return }
    set({ tiltDirection: dir })
  },
  setPanDirection: (dir) => {
    const { groups, selectedGroupIds } = get()
    if (groups.length === 0) { get().addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { get().addToast('No group selected to perform the operation.', 'warning'); return }
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
  toggleGroupSelection: (id) => {
    const { selectedGroupIds } = get()
    if (selectedGroupIds.includes(id)) {
      set({ selectedGroupIds: selectedGroupIds.filter((gid) => gid !== id) })
    } else {
      set({ selectedGroupIds: [...selectedGroupIds, id] })
    }
  },

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
    const { groups, selectedGroupIds } = get()
    const group = groups.find((g) => g.id === id)
    set({ groups: groups.filter((g) => g.id !== id), deleteConfirmId: null, selectedGroupIds: selectedGroupIds.filter((gid) => gid !== id) })
    get().addToast(`Group "${group?.name}" deleted`, 'success')
  },

  confirmDeleteGroup: (id) => set({ deleteConfirmId: id }),
  cancelDeleteGroup: () => set({ deleteConfirmId: null }),

  getSelectedGroup: () => {
    const { groups, selectedGroupIds } = get()
    if (selectedGroupIds.length === 0) return null
    return groups.find((g) => g.id === selectedGroupIds[0]) ?? null
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
    const { groups, selectedGroupIds, addToast } = get()
    if (groups.length === 0) { addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { addToast('No group selected to perform the operation.', 'warning'); return }
    addToast(`${mode === 'odd' ? 'Odd' : 'Even'} selection applied`, 'success')
  },

  applyLeftRight: (mode) => {
    const { groups, selectedGroupIds, addToast } = get()
    if (groups.length === 0) { addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { addToast('No group selected to perform the operation.', 'warning'); return }
    addToast(`${mode === 'left' ? 'Left' : 'Right'} selection applied`, 'success')
  },

  applyQuickColor: (color) => {
    const { groups, selectedGroupIds, addToast } = get()
    if (groups.length === 0) { addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { addToast('No group selected to perform the operation.', 'warning'); return }
    addToast(`Color applied`, 'success')
  },

  applyColorPattern: (pattern) => {
    const { groups, selectedGroupIds, addToast } = get()
    if (groups.length === 0) { addToast('No groups. Please create a group first.', 'warning'); return }
    if (selectedGroupIds.length === 0) { addToast('No group selected to perform the operation.', 'warning'); return }
    addToast(`Color pattern applied`, 'success')
  },

  // Hub panel
  setHubSearch: (v) => set({ hubSearch: v }),
  setHubFilter: (v) => set({ hubFilter: v }),
  viewHubUser: (authorId) => set({ hubViewingUser: authorId, hubSearch: '' }),

  addHubEffectToCustom: (hubEffect) => {
    const { addToast } = get()
    // Check if already added
    const effectEditorState = useEffectEditorStore.getState()
    const alreadyAdded = effectEditorState.savedEffects.some((e) => e.name === hubEffect.name && e.source === 'hub')
    if (alreadyAdded) {
      addToast(`"${hubEffect.name}" is already in your custom effects`, 'warning')
      return
    }
    // Add to effect editor store as hub-sourced effect
    const newEffect: import('./effect-editor-store').SavedCustomEffect = {
      id: `hub-${hubEffect.id}`,
      name: hubEffect.name,
      type: hubEffect.type,
      tags: [...hubEffect.tags, 'hub-import'],
      frames: [], // Frame data would come from Firebase in production
      source: 'hub',
      createdAt: Date.now(),
    }
    useEffectEditorStore.getState().addHubEffect(newEffect)
    addToast(`"${hubEffect.name}" added to custom effects`, 'success')
  },

  // Position
  addPosition: (name) => {
    const validation = validateGroupName(name)
    if (!validation.valid) { get().addToast(validation.reason, 'warning'); return }
    set((s) => ({
      positions: [...s.positions, { id: `pos-${Date.now()}`, name: name.trim() }],
    }))
    get().addToast(`Position "${name.trim()}" saved`, 'success')
  },
  removePosition: (id) => {
    const { positions } = get()
    const pos = positions.find((p) => p.id === id)
    set({ positions: positions.filter((p) => p.id !== id), activePosition: null })
    if (pos) get().addToast(`Position "${pos.name}" removed`, 'success')
  },
  activatePosition: (id) => {
    // Clear any existing timer
    const { positionTimer } = get()
    if (positionTimer) clearTimeout(positionTimer)
    // Set active, auto-deactivate after 1 second
    set({ activePosition: id, positionTimer: setTimeout(() => {
      set({ activePosition: null, positionTimer: null })
    }, 1000) })
  },

  // Keybinds
  addKeybind: (label, action, category) => {
    const newBind: Keybind = {
      id: `kb-${Date.now()}`,
      label,
      key: '...',
      code: '',
      action,
      category,
    }
    set((s) => ({ keybinds: [...s.keybinds, newBind], keybindListeningId: newBind.id }))
  },

  setKeybindKey: (id, key, code) => {
    set((s) => ({
      keybinds: s.keybinds.map((k) => (k.id === id ? { ...k, key, code } : k)),
      keybindListeningId: null,
    }))
  },

  removeKeybind: (id) => {
    set((s) => ({ keybinds: s.keybinds.filter((k) => k.id !== id), keybindListeningId: s.keybindListeningId === id ? null : s.keybindListeningId }))
  },

  startListening: (id) => set({ keybindListeningId: id }),
  stopListening: () => set({ keybindListeningId: null }),

  getKeybindByAction: (action) => {
    return get().keybinds.find((k) => k.action === action)
  },

  // Timecode
  createTimecode: (name) => {
    const { groups } = get()
    if (groups.length === 0) { get().addToast('No groups. Create a group first.', 'warning'); return }
    const tracks: TimecodeTrack[] = groups.map((g) => ({
      groupId: g.id,
      groupName: g.name,
      cells: {},
    }))
    const project: SavedTimecode = {
      id: `tc-${Date.now()}`,
      name: name.trim(),
      bpm: 120,
      tracks,
      createdAt: Date.now(),
    }
    set((s) => ({
      timecodeProjects: [...s.timecodeProjects, project],
      activeTimecodeId: project.id,
      timecodePlaying: false,
      timecodeCurrentStep: -1,
    }))
    get().addToast(`Timecode "${project.name}" created`, 'success')
  },

  deleteTimecode: (id) => {
    const project = get().timecodeProjects.find((p) => p.id === id)
    const { timecodeTimer } = get()
    if (timecodeTimer) clearTimeout(timecodeTimer)
    set((s) => ({
      timecodeProjects: s.timecodeProjects.filter((p) => p.id !== id),
      activeTimecodeId: s.activeTimecodeId === id ? null : s.activeTimecodeId,
      timecodePlaying: false,
      timecodeCurrentStep: -1,
      timecodeTimer: null,
    }))
    if (project) get().addToast(`Timecode "${project.name}" deleted`, 'success')
  },

  loadTimecode: (id) => {
    const { timecodeTimer } = get()
    if (timecodeTimer) clearTimeout(timecodeTimer)
    set({ activeTimecodeId: id, timecodePlaying: false, timecodeCurrentStep: -1, timecodeTimer: null })
  },

  setTimecodeBpm: (bpm) => {
    const { activeTimecodeId } = get()
    if (!activeTimecodeId) return
    set((s) => ({
      timecodeProjects: s.timecodeProjects.map((p) =>
        p.id === activeTimecodeId ? { ...p, bpm: Math.max(20, Math.min(999, bpm)) } : p
      ),
    }))
  },

  setTimecodeName: (name) => {
    const { activeTimecodeId } = get()
    if (!activeTimecodeId) return
    set((s) => ({
      timecodeProjects: s.timecodeProjects.map((p) =>
        p.id === activeTimecodeId ? { ...p, name: name.trim() } : p
      ),
    }))
  },

  addTimecodeEntry: (groupId, col, entry) => {
    const { activeTimecodeId } = get()
    if (!activeTimecodeId) return
    const cell: TimecodeCell = {
      ...entry,
      id: `tcell-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      waitMultiplier: entry.type === 'wait' ? 1 : 0,
      duration: 1,
    }
    set((s) => ({
      timecodeProjects: s.timecodeProjects.map((p) =>
        p.id === activeTimecodeId
          ? {
              ...p,
              tracks: p.tracks.map((t) =>
                t.groupId === groupId
                  ? { ...t, cells: { ...t.cells, [col]: cell } }
                  : t
              ),
            }
          : p
      ),
    }))
  },

  removeTimecodeEntry: (groupId, col) => {
    const { activeTimecodeId } = get()
    if (!activeTimecodeId) return
    set((s) => ({
      timecodeProjects: s.timecodeProjects.map((p) =>
        p.id === activeTimecodeId
          ? {
              ...p,
              tracks: p.tracks.map((t) => {
                if (t.groupId !== groupId) return t
                const newCells = { ...t.cells }
                delete newCells[col]
                return { ...t, cells: newCells }
              }),
            }
          : p
      ),
    }))
  },

  resizeTimecodeEntry: (groupId, col, newDuration) => {
    const { activeTimecodeId } = get()
    if (!activeTimecodeId) return
    const clamped = Math.max(1, Math.min(64, newDuration))
    set((s) => ({
      timecodeProjects: s.timecodeProjects.map((p) =>
        p.id === activeTimecodeId
          ? {
              ...p,
              tracks: p.tracks.map((t) => {
                if (t.groupId !== groupId) return t
                const cell = t.cells[col]
                if (!cell) return t
                // Check for overlap: if extending, make sure target cols are free
                if (clamped > cell.duration) {
                  for (let c = col; c < col + clamped; c++) {
                    if (c !== col && t.cells[c]) return t // collision
                  }
                }
                return {
                  ...t,
                  cells: { ...t.cells, [col]: { ...cell, duration: clamped } },
                }
              }),
            }
          : p
      ),
    }))
  },

  cycleWaitMultiplier: (groupId, col) => {
    const { activeTimecodeId } = get()
    if (!activeTimecodeId) return
    const multipliers = [0.25, 0.5, 1, 2, 4]
    set((s) => ({
      timecodeProjects: s.timecodeProjects.map((p) =>
        p.id === activeTimecodeId
          ? {
              ...p,
              tracks: p.tracks.map((t) => {
                if (t.groupId !== groupId) return t
                const cell = t.cells[col]
                if (!cell || cell.type !== 'wait') return t
                const idx = multipliers.indexOf(cell.waitMultiplier)
                const next = multipliers[(idx + 1) % multipliers.length]
                return {
                  ...t,
                  cells: { ...t.cells, [col]: { ...cell, waitMultiplier: next } },
                }
              }),
            }
          : p
      ),
    }))
  },

  playTimecode: () => {
    const { activeTimecodeId, timecodeProjects, timecodeTimer, timecodePlaying } = get()
    if (timecodeTimer) clearTimeout(timecodeTimer)
    if (!activeTimecodeId) { get().addToast('No timecode selected', 'warning'); return }
    const project = timecodeProjects.find((p) => p.id === activeTimecodeId)
    if (!project) return

    if (timecodePlaying) {
      set({ timecodePlaying: false, timecodeCurrentStep: -1, timecodeTimer: null })
      return
    }

    let maxCol = 0
    for (const track of project.tracks) {
      for (const [colStr, cell] of Object.entries(track.cells)) {
        const col = Number(colStr)
        const endCol = col + (cell.duration || 1) - 1
        if (endCol > maxCol) maxCol = endCol
      }
    }
    if (maxCol === 0) { get().addToast('No entries to play', 'warning'); return }

    const stepMs = 60000 / project.bpm
    let currentStep = 0

    set({ timecodePlaying: true, timecodeCurrentStep: 0 })

    const playNext = () => {
      const proj = get().timecodeProjects.find((p) => p.id === activeTimecodeId)
      if (!proj || !get().timecodePlaying) {
        set({ timecodePlaying: false, timecodeCurrentStep: -1, timecodeTimer: null })
        return
      }

      set({ timecodeCurrentStep: currentStep })

      let waitMs = 0
      for (const track of proj.tracks) {
        const cell = track.cells[currentStep]
        if (cell?.type === 'wait') {
          waitMs = Math.max(waitMs, cell.waitMultiplier * stepMs)
        }
      }

      currentStep++
      const delay = waitMs > 0 ? waitMs : stepMs
      if (currentStep > maxCol) {
        const timer = setTimeout(() => {
          set({ timecodePlaying: false, timecodeCurrentStep: -1, timecodeTimer: null })
        }, delay)
        set({ timecodeTimer: timer })
        return
      }
      const timer = setTimeout(playNext, delay)
      set({ timecodeTimer: timer })
    }

    playNext()
  },

  stopTimecode: () => {
    const { timecodeTimer } = get()
    if (timecodeTimer) clearTimeout(timecodeTimer)
    set({ timecodePlaying: false, timecodeCurrentStep: -1, timecodeTimer: null })
  },

  getActiveTimecode: () => {
    const { activeTimecodeId, timecodeProjects } = get()
    return timecodeProjects.find((p) => p.id === activeTimecodeId)
  },
}))
