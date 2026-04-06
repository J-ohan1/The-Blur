import { create } from 'zustand'

/* ─── Types ─────────────────────────────────────── */

export type EffectType = 'movement' | 'pattern' | 'chase' | 'strobe' | 'wave' | 'custom'

export interface BeamFrameState {
  x: number       // 0–100 canvas percentage
  y: number       // 0–100 canvas percentage
  color: string   // hex color
  iris: number    // 0–100 (beam opening size)
  dimmer: number  // 0–100 (brightness)
  visible: boolean
}

export interface EffectFrame {
  id: string
  beams: Record<number, BeamFrameState> // beam 1–15
  duration: number // milliseconds per frame
}

export interface SavedCustomEffect {
  id: string
  name: string
  type: EffectType
  tags: string[]
  frames: EffectFrame[]
  source: 'local' | 'hub'
  createdAt: number
}

/* ─── Helpers ───────────────────────────────────── */

let _frameIdCounter = 0
function nextFrameId(): string {
  return `f-${++_frameIdCounter}-${Date.now()}`
}

function defaultBeam(x: number, y: number): BeamFrameState {
  return { x, y, color: '#ffffff', iris: 80, dimmer: 100, visible: true }
}

function blankFrame(): EffectFrame {
  const beams: Record<number, BeamFrameState> = {}
  for (let i = 1; i <= 15; i++) {
    // 1x15 straight row — evenly spaced horizontally, centered vertically
    beams[i] = defaultBeam(3 + (i - 1) * 6.5, 50)
  }
  return { id: nextFrameId(), beams, duration: 200 }
}

function createInitialFrames(count = 30): EffectFrame[] {
  return Array.from({ length: count }, () => blankFrame())
}

/* ─── State Interface ───────────────────────────── */

interface EffectEditorState {
  /* View */
  effectPanelView: 'list' | 'editor'

  /* Editor frames */
  frames: EffectFrame[]
  currentFrameIndex: number

  /* Playback */
  isPlaying: boolean
  loop: boolean
  speed: number // 0.25–4

  /* Canvas selection */
  selectedBeams: number[]
  onionSkin: boolean
  applyToAllFrames: boolean

  /* Save dialog */
  saveDialogOpen: boolean
  saveName: string
  saveType: EffectType
  saveTags: string[]
  saveTagInput: string
  saveGlow: boolean

  /* Preset browser */
  presetBrowserOpen: boolean

  /* Saved effects */
  savedEffects: SavedCustomEffect[]

  /* Undo / redo */
  undoStack: string[]   // JSON snapshots
  redoStack: string[]

  /* ─── Actions ─────────────────────────────── */

  openEditor: (presetData?: SavedCustomEffect) => void
  closeEditor: () => void

  /* Frame management */
  addFrame: () => void
  insertFrameAfter: (index: number) => void
  removeFrame: (index: number) => void
  duplicateFrame: (index: number) => void
  setCurrentFrame: (index: number) => void

  /* Beam selection */
  selectBeam: (beamNum: number, multi?: boolean) => void
  selectAllBeams: () => void
  deselectAllBeams: () => void
  setApplyToAllFrames: (v: boolean) => void

  /* Beam state (with undo) */
  updateBeamInFrame: (beamNum: number, updates: Partial<BeamFrameState>) => void
  moveBeamInFrame: (beamNum: number, x: number, y: number) => void
  setBeamPositionRaw: (beamNum: number, x: number, y: number) => void

  /* Playback */
  play: () => void
  pause: () => void
  stop: () => void
  toggleLoop: () => void
  setSpeed: (speed: number) => void
  toggleOnionSkin: () => void
  advanceFrame: () => void

  /* Undo / redo */
  pushUndo: () => void
  undo: () => void
  redo: () => void

  /* Save dialog */
  openSaveDialog: () => void
  closeSaveDialog: () => void
  setSaveName: (name: string) => void
  setSaveType: (type: EffectType) => void
  addSaveTag: (tag: string) => void
  removeSaveTag: (tag: string) => void
  setSaveTagInput: (input: string) => void
  saveLocal: () => void

  /* Preset browser */
  openPresetBrowser: () => void
  closePresetBrowser: () => void
  loadPreset: (effect: SavedCustomEffect) => void

  /* Saved effects */
  deleteSavedEffect: (id: string) => void
}

/* ─── Store ─────────────────────────────────────── */

export const useEffectEditorStore = create<EffectEditorState>((set, get) => ({
  effectPanelView: 'list',
  frames: createInitialFrames(30),
  currentFrameIndex: 0,
  isPlaying: false,
  loop: true,
  speed: 1,
  selectedBeams: [],
  onionSkin: false,
  applyToAllFrames: false,

  saveDialogOpen: false,
  saveName: '',
  saveType: 'custom',
  saveTags: [],
  saveTagInput: '',
  saveGlow: false,

  presetBrowserOpen: false,
  savedEffects: [],

  undoStack: [],
  redoStack: [],

  /* ── Editor open/close ────────────────────── */

  openEditor: (presetData) => {
    const frames = presetData
      ? JSON.parse(JSON.stringify(presetData.frames))
      : createInitialFrames(30)
    set({
      effectPanelView: 'editor',
      frames,
      currentFrameIndex: 0,
      isPlaying: false,
      selectedBeams: [],
      undoStack: [],
      redoStack: [],
    })
  },

  closeEditor: () => set({ effectPanelView: 'list', isPlaying: false }),

  /* ── Frame management ─────────────────────── */

  addFrame: () => {
    set((s) => {
      const newFrame = blankFrame()
      const frames = [...s.frames, newFrame]
      return {
        frames,
        currentFrameIndex: frames.length - 1,
        undoStack: [...s.undoStack.slice(-49), JSON.stringify(s.frames)],
        redoStack: [],
      }
    })
  },

  insertFrameAfter: (index) => {
    set((s) => {
      const newFrame = blankFrame()
      const frames = [...s.frames]
      frames.splice(index + 1, 0, newFrame)
      return {
        frames,
        currentFrameIndex: index + 1,
        undoStack: [...s.undoStack.slice(-49), JSON.stringify(s.frames)],
        redoStack: [],
      }
    })
  },

  removeFrame: (index) => {
    set((s) => {
      if (s.frames.length <= 1) return s
      const frames = s.frames.filter((_, i) => i !== index)
      let ci = s.currentFrameIndex
      if (ci >= frames.length) ci = frames.length - 1
      else if (ci > index) ci--
      return {
        frames,
        currentFrameIndex: ci,
        undoStack: [...s.undoStack.slice(-49), JSON.stringify(s.frames)],
        redoStack: [],
      }
    })
  },

  duplicateFrame: (index) => {
    set((s) => {
      const source = s.frames[index]
      const clone: EffectFrame = {
        ...JSON.parse(JSON.stringify(source)),
        id: nextFrameId(),
      }
      const frames = [...s.frames]
      frames.splice(index + 1, 0, clone)
      return {
        frames,
        currentFrameIndex: index + 1,
        undoStack: [...s.undoStack.slice(-49), JSON.stringify(s.frames)],
        redoStack: [],
      }
    })
  },

  setCurrentFrame: (index) => {
    const { frames } = get()
    if (index >= 0 && index < frames.length) set({ currentFrameIndex: index })
  },

  /* ── Beam selection ───────────────────────── */

  selectBeam: (beamNum, multi = false) => {
    set((s) => {
      if (multi) {
        if (s.selectedBeams.includes(beamNum)) {
          return { selectedBeams: s.selectedBeams.filter((b) => b !== beamNum) }
        }
        return { selectedBeams: [...s.selectedBeams, beamNum].sort((a, b) => a - b) }
      }
      return { selectedBeams: [beamNum] }
    })
  },

  selectAllBeams: () => set({ selectedBeams: Array.from({ length: 15 }, (_, i) => i + 1) }),
  deselectAllBeams: () => set({ selectedBeams: [] }),
  setApplyToAllFrames: (v) => set({ applyToAllFrames: v }),

  /* ── Beam state with undo ─────────────────── */

  updateBeamInFrame: (beamNum, updates) => {
    set((s) => {
      const snapshot = JSON.stringify(s.frames)
      const newUndo = [...s.undoStack, snapshot].slice(-50)

      const updateBeam = (b: BeamFrameState) => ({ ...b, ...updates })

      if (s.applyToAllFrames) {
        const frames = s.frames.map((f) => ({
          ...f,
          beams: { ...f.beams, [beamNum]: updateBeam(f.beams[beamNum]) },
        }))
        return { frames, undoStack: newUndo, redoStack: [] }
      }

      const frames = s.frames.map((f, i) =>
        i === s.currentFrameIndex
          ? { ...f, beams: { ...f.beams, [beamNum]: updateBeam(f.beams[beamNum]) } }
          : f
      )
      return { frames, undoStack: newUndo, redoStack: [] }
    })
  },

  moveBeamInFrame: (beamNum, x, y) => {
    get().pushUndo()
    get().setBeamPositionRaw(beamNum, x, y)
  },

  /** Move beam without pushing undo (used after manual pushUndo) */
  setBeamPositionRaw: (beamNum, x, y) => {
    set((s) => {
      const cx = Math.max(0, Math.min(100, x))
      const cy = Math.max(0, Math.min(100, y))

      if (s.applyToAllFrames) {
        const frames = s.frames.map((f) => ({
          ...f,
          beams: {
            ...f.beams,
            [beamNum]: { ...f.beams[beamNum], x: cx, y: cy },
          },
        }))
        return { frames }
      }

      const frames = s.frames.map((f, i) =>
        i === s.currentFrameIndex
          ? { ...f, beams: { ...f.beams, [beamNum]: { ...f.beams[beamNum], x: cx, y: cy } } }
          : f
      )
      return { frames }
    })
  },

  /* ── Playback ─────────────────────────────── */

  play: () => set({ isPlaying: true }),
  pause: () => set({ isPlaying: false }),
  stop: () => set({ isPlaying: false, currentFrameIndex: 0 }),
  toggleLoop: () => set((s) => ({ loop: !s.loop })),
  setSpeed: (speed) => set({ speed: Math.max(0.25, Math.min(4, speed)) }),
  toggleOnionSkin: () => set((s) => ({ onionSkin: !s.onionSkin })),
  advanceFrame: () => {
    const { frames, currentFrameIndex, loop } = get()
    if (currentFrameIndex < frames.length - 1) {
      set({ currentFrameIndex: currentFrameIndex + 1 })
    } else if (loop) {
      set({ currentFrameIndex: 0 })
    } else {
      set({ isPlaying: false })
    }
  },

  /* ── Undo / redo ──────────────────────────── */

  pushUndo: () => {
    const { frames, undoStack } = get()
    set({ undoStack: [...undoStack.slice(-49), JSON.stringify(frames)], redoStack: [] })
  },

  undo: () => {
    const { frames, undoStack, redoStack } = get()
    if (undoStack.length === 0) return
    const prev = undoStack[undoStack.length - 1]
    set({
      frames: JSON.parse(prev),
      undoStack: undoStack.slice(0, -1),
      redoStack: [...redoStack, JSON.stringify(frames)],
      currentFrameIndex: Math.min(get().currentFrameIndex, JSON.parse(prev).length - 1),
    })
  },

  redo: () => {
    const { frames, undoStack, redoStack } = get()
    if (redoStack.length === 0) return
    const next = redoStack[redoStack.length - 1]
    set({
      frames: JSON.parse(next),
      undoStack: [...undoStack, JSON.stringify(frames)],
      redoStack: redoStack.slice(0, -1),
    })
  },

  /* ── Save dialog ──────────────────────────── */

  openSaveDialog: () =>
    set({ saveDialogOpen: true, saveName: '', saveType: 'custom', saveTags: [], saveTagInput: '', saveGlow: false }),
  closeSaveDialog: () => set({ saveDialogOpen: false }),
  setSaveName: (name) => {
    const isBlur = name.toLowerCase().trim() === 'blur'
    set({ saveName: name, saveGlow: isBlur })
    if (isBlur) setTimeout(() => set({ saveGlow: false }), 1500)
  },
  setSaveType: (type) => set({ saveType: type }),
  addSaveTag: (tag) => {
    const trimmed = tag.trim().toLowerCase()
    if (trimmed.length > 0 && !get().saveTags.includes(trimmed)) {
      set((s) => ({ saveTags: [...s.saveTags, trimmed], saveTagInput: '' }))
    }
  },
  removeSaveTag: (tag) => set((s) => ({ saveTags: s.saveTags.filter((t) => t !== tag) })),
  setSaveTagInput: (input) => set({ saveTagInput: input }),
  saveLocal: () => {
    const { frames, saveName, saveType, saveTags } = get()
    const name = saveName.trim()
    if (!name) return
    const effect: SavedCustomEffect = {
      id: `fx-${Date.now()}`,
      name,
      type: saveType,
      tags: [...saveTags],
      frames: JSON.parse(JSON.stringify(frames)),
      source: 'local',
      createdAt: Date.now(),
    }
    set((s) => ({ savedEffects: [...s.savedEffects, effect], saveDialogOpen: false }))
  },

  /* ── Preset browser ───────────────────────── */

  openPresetBrowser: () => set({ presetBrowserOpen: true }),
  closePresetBrowser: () => set({ presetBrowserOpen: false }),
  loadPreset: (effect) => {
    const frames = JSON.parse(JSON.stringify(effect.frames))
    set({
      frames,
      currentFrameIndex: 0,
      isPlaying: false,
      selectedBeams: [],
      undoStack: [],
      redoStack: [],
      presetBrowserOpen: false,
      effectPanelView: 'editor',
    })
  },

  /* ── Saved effects ────────────────────────── */

  deleteSavedEffect: (id) => {
    set((s) => ({ savedEffects: s.savedEffects.filter((e) => e.id !== id) }))
  },
}))
