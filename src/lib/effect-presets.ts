import type { SavedCustomEffect, BeamFrameState, EffectFrame } from '@/store/effect-editor-store'

/* ─── Helpers ───────────────────────────────────── */

function beam(x: number, y: number, overrides?: Partial<BeamFrameState>): BeamFrameState {
  return { x, y, color: '#ffffff', iris: 80, dimmer: 100, tilt: 0, pan: 0, visible: true, ...overrides }
}

let _presetFrameId = 0
function presetFrame(beams: Record<number, BeamFrameState>, duration = 200): EffectFrame {
  return { id: `pf-${++_presetFrameId}`, beams, duration }
}

/* ─── Preset 1: Simple Chase ────────────────────── */

const chaseFrames = Array.from({ length: 15 }, (_, fi) => {
  const beams: Record<number, BeamFrameState> = {}
  for (let i = 1; i <= 15; i++) {
    const x = 5 + (i - 1) * 6.5
    beams[i] = beam(x, 50, {
      dimmer: i === fi + 1 ? 100 : 12,
      iris: i === fi + 1 ? 100 : 30,
      color: i === fi + 1 ? '#ffffff' : '#333333',
    })
  }
  return presetFrame(beams, 250)
})

export const CHASE_PRESET: SavedCustomEffect = {
  id: 'preset-chase',
  name: 'Simple Chase',
  type: 'chase',
  tags: ['basic', 'sequential'],
  frames: chaseFrames,
  source: 'local',
  createdAt: Date.now() - 100000,
}

/* ─── Preset 2: Sine Wave ──────────────────────── */

const waveFrames = Array.from({ length: 16 }, (_, fi) => {
  const beams: Record<number, BeamFrameState> = {}
  for (let i = 1; i <= 15; i++) {
    const x = 5 + (i - 1) * 6.5
    const phase = (fi / 16) * Math.PI * 2
    const offset = Math.sin(phase + (i - 1) * 0.5) * 35
    beams[i] = beam(x, 50 + offset)
  }
  return presetFrame(beams, 150)
})

export const WAVE_PRESET: SavedCustomEffect = {
  id: 'preset-wave',
  name: 'Sine Wave',
  type: 'wave',
  tags: ['basic', 'smooth'],
  frames: waveFrames,
  source: 'local',
  createdAt: Date.now() - 90000,
}

/* ─── Preset 3: Fan Out ─────────────────────────── */

const fanOutFrames = Array.from({ length: 10 }, (_, fi) => {
  const progress = fi / 9
  const beams: Record<number, BeamFrameState> = {}
  for (let i = 1; i <= 15; i++) {
    const targetX = 5 + (i - 1) * 6.5
    const targetY = 50 + ((i - 8) / 7) * 38
    beams[i] = beam(
      50 + (targetX - 50) * progress,
      50 + (targetY - 50) * progress,
      {
        color: `hsl(${(i - 1) * 24}, 80%, 60%)`,
        iris: 60 + progress * 40,
      }
    )
  }
  return presetFrame(beams, 200)
})

export const FAN_OUT_PRESET: SavedCustomEffect = {
  id: 'preset-fanout',
  name: 'Fan Out',
  type: 'movement',
  tags: ['basic', 'colour'],
  frames: fanOutFrames,
  source: 'local',
  createdAt: Date.now() - 80000,
}

/* ─── Preset 4: Random Scatter ──────────────────── */

function seededRandom(seed: number) {
  let s = seed
  return () => {
    s = (s * 16807 + 7) % 2147483647
    return s / 2147483647
  }
}

const scatterFrames = Array.from({ length: 12 }, (_, fi) => {
  const rng = seededRandom(fi * 7919 + 42)
  const beams: Record<number, BeamFrameState> = {}
  for (let i = 1; i <= 15; i++) {
    beams[i] = beam(8 + rng() * 84, 8 + rng() * 84, {
      color: `hsl(${Math.floor(rng() * 360)}, 70%, 60%)`,
      iris: 50 + rng() * 50,
    })
  }
  return presetFrame(beams, 180)
})

export const SCATTER_PRESET: SavedCustomEffect = {
  id: 'preset-scatter',
  name: 'Random Scatter',
  type: 'pattern',
  tags: ['basic', 'random'],
  frames: scatterFrames,
  source: 'local',
  createdAt: Date.now() - 70000,
}

/* ─── Preset 5: Pulse ───────────────────────────── */

const pulseFrames = Array.from({ length: 10 }, (_, fi) => {
  const beams: Record<number, BeamFrameState> = {}
  const wave = Math.sin((fi / 10) * Math.PI * 2)
  const dimmer = Math.floor(50 + wave * 50)
  const iris = Math.floor(60 + wave * 40)
  for (let i = 1; i <= 15; i++) {
    const x = 5 + (i - 1) * 6.5
    const row = Math.floor((i - 1) / 5)
    const y = 30 + row * 20
    beams[i] = beam(x, y, { dimmer, iris })
  }
  return presetFrame(beams, 200)
})

export const PULSE_PRESET: SavedCustomEffect = {
  id: 'preset-pulse',
  name: 'Breathing Pulse',
  type: 'strobe',
  tags: ['basic', 'smooth'],
  frames: pulseFrames,
  source: 'local',
  createdAt: Date.now() - 60000,
}

/* ─── Export all presets ─────────────────────────── */

export const EFFECT_PRESETS: SavedCustomEffect[] = [
  CHASE_PRESET,
  WAVE_PRESET,
  FAN_OUT_PRESET,
  SCATTER_PRESET,
  PULSE_PRESET,
]
