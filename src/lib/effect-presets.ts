import { EFFECTS } from '@/store/blur-store'
import type { SavedCustomEffect, BeamFrameState, EffectFrame } from '@/store/effect-editor-store'

/* ─── Helpers ───────────────────────────────────── */

function beam(x: number, y: number, overrides?: Partial<BeamFrameState>): BeamFrameState {
  return { x, y, color: '#ffffff', iris: 80, dimmer: 100, visible: true, ...overrides }
}

/** 1x15 row position: evenly spaced horizontally, centered vertically */
function rowPos(i: number): { x: number; y: number } {
  return { x: 3 + (i - 1) * 6.5, y: 50 }
}

let _presetFrameId = 0
function presetFrame(beams: Record<number, BeamFrameState>, duration = 200): EffectFrame {
  return { id: `pf-${++_presetFrameId}`, beams, duration }
}

/** Seeded pseudo-random for deterministic presets */
function seededRandom(seed: number) {
  let s = seed
  return () => {
    s = (s * 16807 + 7) % 2147483647
    return s / 2147483647
  }
}

function hsl(h: number, s = 80, l = 60): string {
  return `hsl(${h}, ${s}%, ${l}%)`
}

/* ═══════════════════════════════════════════════════
   Frame generators by category
   ═══════════════════════════════════════════════════ */

function makeBaseBeams(): Record<number, BeamFrameState> {
  const beams: Record<number, BeamFrameState> = {}
  for (let i = 1; i <= 15; i++) {
    const { x, y } = rowPos(i)
    beams[i] = beam(x, y)
  }
  return beams
}

/* ── Wave generators ─────────────────────────── */

function genWaveUp(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const phase = (fi / count) * Math.PI * 2
    for (let i = 1; i <= 15; i++) {
      const { x } = rowPos(i)
      const offset = Math.sin(phase + (i - 1) * 0.5) * 35
      beams[i] = beam(x, 50 - Math.abs(offset))
    }
    return presetFrame(beams, 180)
  })
}

function genWaveDown(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const phase = (fi / count) * Math.PI * 2
    for (let i = 1; i <= 15; i++) {
      const { x } = rowPos(i)
      const offset = Math.sin(phase + (i - 1) * 0.5) * 35
      beams[i] = beam(x, 50 + Math.abs(offset))
    }
    return presetFrame(beams, 180)
  })
}

function genWaveIn(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const t = fi / (count - 1)
    const breathe = Math.sin((fi / count) * Math.PI * 2) * 0.5 + 0.5
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const targetX = 50
      beams[i] = beam(x + (targetX - x) * breathe, y + (targetY(y, i) - y) * breathe)
    }
    return presetFrame(beams, 200)
  })
}

function targetY(baseY: number, i: number): number {
  return baseY + ((i - 8) / 7) * 20
}

function genWaveOut(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const t = fi / (count - 1)
    const spread = Math.sin((fi / count) * Math.PI * 2) * 0.5 + 0.5
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const outY = y + ((i - 8) / 7) * 38 * spread
      beams[i] = beam(x + (x - 50) * spread * 0.3, outY)
    }
    return presetFrame(beams, 200)
  })
}

function genWaveLeft(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const phase = (fi / count) * Math.PI * 2
    for (let i = 1; i <= 15; i++) {
      const { x } = rowPos(i)
      const offset = Math.sin(phase + (i - 1) * 0.5) * 25
      beams[i] = beam(x - offset, 50)
    }
    return presetFrame(beams, 180)
  })
}

function genWaveRight(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const phase = (fi / count) * Math.PI * 2
    for (let i = 1; i <= 15; i++) {
      const { x } = rowPos(i)
      const offset = Math.sin(phase + (i - 1) * 0.5) * 25
      beams[i] = beam(x + offset, 50)
    }
    return presetFrame(beams, 180)
  })
}

function genWaveCircular(): EffectFrame[] {
  const count = 16
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const angle = (fi / count) * Math.PI * 2
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const beamAngle = angle + ((i - 1) / 15) * Math.PI * 2
      const radius = 20
      beams[i] = beam(x + Math.cos(beamAngle) * radius, y + Math.sin(beamAngle) * radius)
    }
    return presetFrame(beams, 160)
  })
}

function genWaveSpiral(): EffectFrame[] {
  const count = 16
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const angle = ((fi / count) * Math.PI * 2) + ((i - 1) / 15) * Math.PI * 4
      const radius = 10 + (fi / count) * 25
      beams[i] = beam(x + Math.cos(angle) * radius, y + Math.sin(angle) * radius)
    }
    return presetFrame(beams, 160)
  })
}

function genWaveRainbow(): EffectFrame[] {
  const count = 15
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const hue = ((fi + i - 1) / 15) * 360
      const phase = (fi / count) * Math.PI * 2
      const offset = Math.sin(phase + (i - 1) * 0.4) * 15
      beams[i] = beam(x, y + offset, { color: hsl(hue) })
    }
    return presetFrame(beams, 180)
  })
}

function genWaveSequential(): EffectFrame[] {
  const count = 15
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const isActive = i <= fi + 1
      beams[i] = beam(x, y, {
        dimmer: isActive ? 100 : 10,
        iris: isActive ? 100 : 30,
        color: isActive ? '#ffffff' : '#333333',
      })
    }
    return presetFrame(beams, 200)
  })
}

function genWaveReverse(): EffectFrame[] {
  return genWaveSequential().reverse().map((f) => ({ ...f, id: `pf-${++_presetFrameId}` }))
}

function genWaveRandom(): EffectFrame[] {
  const count = 10
  return Array.from({ length: count }, (_, fi) => {
    const rng = seededRandom(fi * 7919 + 42)
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      beams[i] = beam(x + (rng() - 0.5) * 20, y + (rng() - 0.5) * 40, {
        color: hsl(Math.floor(rng() * 360)),
      })
    }
    return presetFrame(beams, 200)
  })
}

function genWavePulse(): EffectFrame[] {
  const count = 10
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const wave = Math.sin((fi / count) * Math.PI * 2)
    const dimmer = Math.floor(50 + wave * 50)
    const iris = Math.floor(60 + wave * 40)
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      beams[i] = beam(x, y, { dimmer, iris })
    }
    return presetFrame(beams, 200)
  })
}

function genWaveSinusoidal(): EffectFrame[] {
  const count = 14
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x } = rowPos(i)
      const phase = (fi / count) * Math.PI * 2
      const y = 50 + Math.sin(phase + (i - 1) * 0.6) * 35
      beams[i] = beam(x, y)
    }
    return presetFrame(beams, 150)
  })
}

/* ── Chase generators ────────────────────────── */

function genChase(): EffectFrame[] {
  return Array.from({ length: 15 }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      beams[i] = beam(x, y, {
        dimmer: i === fi + 1 ? 100 : 8,
        iris: i === fi + 1 ? 100 : 25,
        color: i === fi + 1 ? '#ffffff' : '#222222',
      })
    }
    return presetFrame(beams, 180)
  })
}

function genChaseReverse(): EffectFrame[] {
  return Array.from({ length: 15 }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const active = 15 - fi
      beams[i] = beam(x, y, {
        dimmer: i === active ? 100 : 8,
        iris: i === active ? 100 : 25,
        color: i === active ? '#ffffff' : '#222222',
      })
    }
    return presetFrame(beams, 180)
  })
}

function genChaseComet(): EffectFrame[] {
  const count = 18
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const headPos = (fi / count) * 14
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const dist = Math.abs(i - 1 - headPos)
      if (dist < 0.5) {
        beams[i] = beam(x, y - 10, { dimmer: 100, iris: 100, color: '#ffffff' })
      } else if (dist < 4) {
        const fade = 1 - (dist / 4)
        beams[i] = beam(x, y, { dimmer: Math.floor(fade * 60), iris: Math.floor(fade * 60 + 20), color: hsl(220, 60, Math.floor(30 + fade * 40)) })
      } else {
        beams[i] = beam(x, y, { dimmer: 5, iris: 20, color: '#111111' })
      }
    }
    return presetFrame(beams, 120)
  })
}

/* ── Pattern generators ─────────────────────── */

function genStrobe(): EffectFrame[] {
  return Array.from({ length: 8 }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const on = fi % 2 === 0
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      beams[i] = beam(x, y, { dimmer: on ? 100 : 5, iris: on ? 100 : 20 })
    }
    return presetFrame(beams, on ? 100 : 100)
  })
}

function genRandomIndividual(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const rng = seededRandom(fi * 4217 + 13)
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      beams[i] = beam(x, y, { dimmer: rng() > 0.5 ? 100 : 8, iris: rng() > 0.5 ? 100 : 30 })
    }
    return presetFrame(beams, 150)
  })
}

function genRandomFixture(): EffectFrame[] {
  const count = 10
  return Array.from({ length: count }, (_, fi) => {
    const rng = seededRandom(fi * 3001 + 7)
    const beams: Record<number, BeamFrameState> = {}
    // Every 3 beams = one "fixture"
    const activeGroup = Math.floor(rng() * 5)
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const group = Math.floor((i - 1) / 3)
      beams[i] = beam(x, y, {
        dimmer: group === activeGroup ? 100 : 8,
        iris: group === activeGroup ? 100 : 30,
      })
    }
    return presetFrame(beams, 250)
  })
}

function genAlternate(): EffectFrame[] {
  return Array.from({ length: 4 }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const oddOn = fi % 2 === 0
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const on = oddOn ? i % 2 === 1 : i % 2 === 0
      beams[i] = beam(x, y, { dimmer: on ? 100 : 8, iris: on ? 100 : 30 })
    }
    return presetFrame(beams, 300)
  })
}

function genCenterOut(): EffectFrame[] {
  const count = 8
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const spread = fi / (count - 1)
    for (let i = 1; i <= 15; i++) {
      const { x } = rowPos(i)
      const centerBeam = 8
      const dist = Math.abs(i - centerBeam)
      const active = dist <= Math.floor(spread * 8)
      beams[i] = beam(x, 50 + ((i - 8) / 7) * 38 * spread, {
        dimmer: active ? 100 : 8,
        iris: active ? 100 : 30,
      })
    }
    return presetFrame(beams, 220)
  })
}

function genCenterIn(): EffectFrame[] {
  return genCenterOut().reverse().map((f) => ({ ...f, id: `pf-${++_presetFrameId}` }))
}

function genSplit(): EffectFrame[] {
  const count = 10
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const phase = (fi / count) * Math.PI * 2
    const leftOn = Math.sin(phase) > 0
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const isLeft = i <= 7
      beams[i] = beam(x, isLeft && leftOn ? 30 : !isLeft && !leftOn ? 70 : y, {
        dimmer: isLeft === leftOn ? 100 : 8,
        iris: isLeft === leftOn ? 100 : 30,
      })
    }
    return presetFrame(beams, 200)
  })
}

function genCollision(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const progress = fi / (count - 1)
    const isSecondHalf = fi >= count / 2
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const isLeft = i <= 7
      if (isSecondHalf) {
        // Outward
        const out = (fi - count / 2) / (count / 2)
        beams[i] = beam(x + (isLeft ? -1 : 1) * out * 15, y, { dimmer: 100, iris: 100 })
      } else {
        // Inward
        const inProgress = 1 - progress * 2
        beams[i] = beam(x + (isLeft ? 1 : -1) * inProgress * 15, y, { dimmer: 100, iris: 100 })
      }
    }
    return presetFrame(beams, 150)
  })
}

function genCascade(): EffectFrame[] {
  const count = 15
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const delay = i - 1
      const isActive = fi >= delay && fi < delay + 5
      const brightness = isActive ? 100 : 8
      beams[i] = beam(x, isActive ? y - 15 : y, { dimmer: brightness, iris: isActive ? 100 : 30 })
    }
    return presetFrame(beams, 120)
  })
}

function genTwinkle(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const rng = seededRandom(fi * 557 + 99)
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const twinkle = rng()
      beams[i] = beam(x, y, {
        dimmer: Math.floor(twinkle * 100),
        iris: Math.floor(40 + twinkle * 60),
        color: hsl(Math.floor(rng() * 360), 40, Math.floor(50 + twinkle * 30)),
      })
    }
    return presetFrame(beams, 130)
  })
}

/* ── Color generators ────────────────────────── */

function genRainbowCycle(): EffectFrame[] {
  const count = 15
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const hue = ((fi + i - 1) / 15) * 360
      beams[i] = beam(x, y, { color: hsl(hue) })
    }
    return presetFrame(beams, 180)
  })
}

function genColorWash(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const hue = (fi / count) * 360
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      beams[i] = beam(x, y, { color: hsl(hue) })
    }
    return presetFrame(beams, 200)
  })
}

function genColorBounce(): EffectFrame[] {
  const count = 20
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const bounce = fi < count / 2 ? fi / (count / 2) : (count - fi) / (count / 2)
    const hue = bounce * 360
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      beams[i] = beam(x, y, { color: hsl(hue) })
    }
    return presetFrame(beams, 150)
  })
}

/* ── Advanced generators ─────────────────────── */

function genMeteor(): EffectFrame[] {
  const count = 16
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x } = rowPos(i)
      const meteorPos = (fi / count) * 16 - 1
      const dist = i - 1 - meteorPos
      if (dist > -1 && dist < 0.5) {
        beams[i] = beam(x, 50 - 20, { dimmer: 100, iris: 100, color: '#ffffff' })
      } else if (dist >= -3 && dist < 0) {
        const fade = 1 + dist / 3
        beams[i] = beam(x, 50, { dimmer: Math.floor(fade * 80), iris: Math.floor(fade * 60 + 20), color: hsl(30, 80, Math.floor(40 + fade * 40)) })
      } else {
        beams[i] = beam(x, 50, { dimmer: 3, iris: 15, color: '#111111' })
      }
    }
    return presetFrame(beams, 80)
  })
}

function genBreathing(): EffectFrame[] {
  const count = 16
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const wave = Math.sin((fi / count) * Math.PI * 2)
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      beams[i] = beam(x, y, {
        dimmer: Math.floor(30 + wave * 40 + 30),
        iris: Math.floor(50 + wave * 30 + 20),
      })
    }
    return presetFrame(beams, 250)
  })
}

function genFlicker(): EffectFrame[] {
  const count = 16
  return Array.from({ length: count }, (_, fi) => {
    const rng = seededRandom(fi * 919 + 31)
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const val = rng() > 0.4 ? 100 : Math.floor(rng() * 30)
      beams[i] = beam(x, y, { dimmer: val, iris: val > 50 ? 100 : Math.floor(rng() * 40 + 20) })
    }
    return presetFrame(beams, 80)
  })
}

function genSparkle(): EffectFrame[] {
  const count = 16
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const rng = seededRandom(fi * 191 + i * 37)
      const sparkle = rng() > 0.75
      beams[i] = beam(x, sparkle ? y - 15 : y, {
        dimmer: sparkle ? 100 : Math.floor(20 + rng() * 30),
        iris: sparkle ? 100 : 30,
        color: sparkle ? hsl(Math.floor(rng() * 60 + 40)) : '#aaaaaa',
      })
    }
    return presetFrame(beams, 100)
  })
}

function genFirework(): EffectFrame[] {
  const count = 12
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const progress = fi / (count - 1)
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const angle = ((i - 1) / 15) * Math.PI * 2
      const radius = progress * 35
      const dimmer = Math.floor(100 * (1 - progress * 0.6))
      beams[i] = beam(
        50 + Math.cos(angle) * radius,
        50 + Math.sin(angle) * radius,
        { dimmer, iris: Math.floor(60 + 40 * (1 - progress)), color: hsl(Math.floor((i - 1) * 24 + fi * 15)) }
      )
    }
    return presetFrame(beams, 140)
  })
}

function genExplosion(): EffectFrame[] {
  const count = 10
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const progress = fi / (count - 1)
    for (let i = 1; i <= 15; i++) {
      const { x, y } = rowPos(i)
      const outProgress = Math.min(1, progress * 2)
      const fadeProgress = Math.max(0, (progress - 0.3) / 0.7)
      const angle = ((i - 1) / 15) * Math.PI * 2
      const radius = outProgress * 38
      beams[i] = beam(
        50 + Math.cos(angle) * radius,
        50 + Math.sin(angle) * radius,
        {
          dimmer: Math.floor(100 * (1 - fadeProgress)),
          iris: Math.floor(100 * (1 - fadeProgress * 0.5)),
          color: hsl(Math.floor(20 + fadeProgress * 20), 90, Math.floor(60 - fadeProgress * 30)),
        }
      )
    }
    return presetFrame(beams, 120)
  })
}

function genStacking(): EffectFrame[] {
  const count = 15
  return Array.from({ length: count }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    for (let i = 1; i <= 15; i++) {
      const { x } = rowPos(i)
      const stackY = 85 - (fi + 1) * 4
      const active = i === (fi % 15) + 1
      const prevStackY = 85 - fi * 4
      beams[i] = beam(
        x,
        active ? 10 : (fi >= i - 1 ? Math.max(10, prevStackY) : 50),
        { dimmer: active ? 100 : (fi >= i - 1 ? 70 : 8), iris: active ? 100 : 50 }
      )
    }
    return presetFrame(beams, 200)
  })
}

/* ═══════════════════════════════════════════════════
   Generator registry — maps effect ID to frames
   ═══════════════════════════════════════════════════ */

const GENERATORS: Record<string, () => EffectFrame[]> = {
  'wave-up': genWaveUp,
  'wave-down': genWaveDown,
  'wave-in': genWaveIn,
  'wave-out': genWaveOut,
  'wave-left': genWaveLeft,
  'wave-right': genWaveRight,
  'wave-circular': genWaveCircular,
  'wave-spiral': genWaveSpiral,
  'wave-rainbow': genWaveRainbow,
  'wave-sequential': genWaveSequential,
  'wave-reverse': genWaveReverse,
  'wave-random': genWaveRandom,
  'wave-pulse': genWavePulse,
  'wave-sinusoidal': genWaveSinusoidal,
  'chase': genChase,
  'chase-reverse': genChaseReverse,
  'chase-comet': genChaseComet,
  'strobe': genStrobe,
  'rand-individual': genRandomIndividual,
  'rand-fixture': genRandomFixture,
  'alternate': genAlternate,
  'center-out': genCenterOut,
  'center-in': genCenterIn,
  'split': genSplit,
  'collision': genCollision,
  'cascade': genCascade,
  'twinkle': genTwinkle,
  'rainbow-cycle': genRainbowCycle,
  'color-wash': genColorWash,
  'color-bounce': genColorBounce,
  'meteor': genMeteor,
  'breathing': genBreathing,
  'flicker': genFlicker,
  'sparkle': genSparkle,
  'firework': genFirework,
  'explosion': genExplosion,
  'stacking': genStacking,
}

const CATEGORY_TYPE_MAP: Record<string, EffectType> = {
  wave: 'wave',
  chase: 'chase',
  pattern: 'pattern',
  color: 'wave',
  advanced: 'custom',
}

/* ═══════════════════════════════════════════════════
   Build all presets from built-in EFFECTS
   ═══════════════════════════════════════════════════ */

const BASE_TIMESTAMP = Date.now() - 200000

export const EFFECT_PRESETS: SavedCustomEffect[] = EFFECTS.map((effect, idx) => {
  const generator = GENERATORS[effect.id]
  const frames = generator ? generator() : createDefaultFrames()
  return {
    id: `preset-${effect.id}`,
    name: effect.name,
    type: CATEGORY_TYPE_MAP[effect.category] ?? 'custom',
    tags: [effect.category, 'premade'],
    frames,
    source: 'local' as const,
    createdAt: BASE_TIMESTAMP - idx * 1000,
  }
})

/** Fallback frames for any effect without a dedicated generator */
function createDefaultFrames(): EffectFrame[] {
  const baseBeams = makeBaseBeams()
  return Array.from({ length: 10 }, (_, fi) => {
    const beams: Record<number, BeamFrameState> = {}
    const phase = (fi / 10) * Math.PI * 2
    for (let i = 1; i <= 15; i++) {
      const b = baseBeams[i]
      beams[i] = beam(b.x, b.y + Math.sin(phase + i * 0.5) * 15)
    }
    return presetFrame(beams, 200)
  })
}
