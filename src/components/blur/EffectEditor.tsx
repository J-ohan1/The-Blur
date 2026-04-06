'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  useEffectEditorStore,
  type BeamFrameState,
} from '@/store/effect-editor-store'
import { useBlurStore } from '@/store/blur-store'

/* ─── Shared class strings ──────────────────────── */

const TB = 'px-3 py-1.5 rounded-lg text-[11px] font-medium border transition-colors cursor-pointer'
const TB_DEF = `${TB} border-neutral-800/40 text-neutral-500 hover:text-neutral-300 hover:border-neutral-700`
const TB_PRI = `${TB} bg-white text-black hover:bg-neutral-200 border-transparent`
const TB_ICO = `${TB} w-8 h-8 !px-0 flex items-center justify-center border-neutral-800/30 text-neutral-500 hover:text-white hover:border-neutral-700 text-[11px] font-bold`
const TB_ACT = 'bg-neutral-800/50 !border-neutral-600 !text-white'

/* ═══════════════════════════════════════════════════
   Effect Editor
   ═══════════════════════════════════════════════════ */

export function EffectEditor() {
  /* ── Store selectors ───────────────────────── */

  const frames = useEffectEditorStore((s) => s.frames)
  const currentFrameIndex = useEffectEditorStore((s) => s.currentFrameIndex)
  const isPlaying = useEffectEditorStore((s) => s.isPlaying)
  const speed = useEffectEditorStore((s) => s.speed)
  const loop = useEffectEditorStore((s) => s.loop)
  const selectedBeams = useEffectEditorStore((s) => s.selectedBeams)
  const onionSkin = useEffectEditorStore((s) => s.onionSkin)
  const applyToAllFrames = useEffectEditorStore((s) => s.applyToAllFrames)

  const closeEditor = useEffectEditorStore((s) => s.closeEditor)
  const openSaveDialog = useEffectEditorStore((s) => s.openSaveDialog)
  const openPresetBrowser = useEffectEditorStore((s) => s.openPresetBrowser)
  const undo = useEffectEditorStore((s) => s.undo)
  const redo = useEffectEditorStore((s) => s.redo)
  const play = useEffectEditorStore((s) => s.play)
  const pause = useEffectEditorStore((s) => s.pause)
  const stop = useEffectEditorStore((s) => s.stop)
  const toggleLoop = useEffectEditorStore((s) => s.toggleLoop)
  const setSpeed = useEffectEditorStore((s) => s.setSpeed)
  const toggleOnionSkin = useEffectEditorStore((s) => s.toggleOnionSkin)
  const advanceFrame = useEffectEditorStore((s) => s.advanceFrame)
  const setCurrentFrame = useEffectEditorStore((s) => s.setCurrentFrame)
  const addFrame = useEffectEditorStore((s) => s.addFrame)
  const removeFrame = useEffectEditorStore((s) => s.removeFrame)
  const duplicateFrame = useEffectEditorStore((s) => s.duplicateFrame)
  const insertFrameAfter = useEffectEditorStore((s) => s.insertFrameAfter)
  const selectBeam = useEffectEditorStore((s) => s.selectBeam)
  const selectAllBeams = useEffectEditorStore((s) => s.selectAllBeams)
  const deselectAllBeams = useEffectEditorStore((s) => s.deselectAllBeams)
  const setApplyToAllFrames = useEffectEditorStore((s) => s.setApplyToAllFrames)
  const updateBeamInFrame = useEffectEditorStore((s) => s.updateBeamInFrame)
  const pushUndo = useEffectEditorStore((s) => s.pushUndo)
  const setBeamPositionRaw = useEffectEditorStore((s) => s.setBeamPositionRaw)

  const addToast = useBlurStore((s) => s.addToast)

  const currentFrame = frames[currentFrameIndex] ?? frames[0]

  /* ── Canvas drag ──────────────────────────── */

  const canvasRef = useRef<HTMLDivElement>(null)
  const dragRef = useRef<{
    beamNum: number
    startMouseX: number
    startMouseY: number
    startBeamX: number
    startBeamY: number
  } | null>(null)
  const [dragVisual, setDragVisual] = useState<{
    beamNum: number
    dx: number
    dy: number
  } | null>(null)

  /* ── Frame context menu ───────────────────── */

  const [frameCtx, setFrameCtx] = useState<{
    x: number
    y: number
    index: number
  } | null>(null)

  /* ── Easter egg ref ───────────────────────── */

  const prevAlignedRef = useRef(false)

  /* ── Beam mouse down ──────────────────────── */

  const handleBeamMouseDown = useCallback(
    (e: React.MouseEvent, beamNum: number) => {
      if (isPlaying) return
      e.stopPropagation()
      selectBeam(beamNum, e.shiftKey)
      const st = useEffectEditorStore.getState()
      const beam = st.frames[st.currentFrameIndex]?.beams[beamNum]
      if (!beam) return
      pushUndo()
      dragRef.current = {
        beamNum,
        startMouseX: e.clientX,
        startMouseY: e.clientY,
        startBeamX: beam.x,
        startBeamY: beam.y,
      }
      setDragVisual({ beamNum, dx: 0, dy: 0 })
    },
    [isPlaying, selectBeam, pushUndo],
  )

  /* ── Global drag listeners ────────────────── */

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      const d = dragRef.current
      const c = canvasRef.current
      if (!d || !c) return
      const r = c.getBoundingClientRect()
      setDragVisual({
        beamNum: d.beamNum,
        dx: ((e.clientX - d.startMouseX) / r.width) * 100,
        dy: ((e.clientY - d.startMouseY) / r.height) * 100,
      })
    }
    const onUp = () => {
      const d = dragRef.current
      if (!d) return
      // Read latest visual offset from a ref-like approach
      setDragVisual((prev) => {
        if (prev) {
          setBeamPositionRaw(d.beamNum, d.startBeamX + prev.dx, d.startBeamY + prev.dy)
        }
        return null
      })
      dragRef.current = null
    }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
    }
  }, [setBeamPositionRaw])

  /* ── Canvas click (deselect) ──────────────── */

  const handleCanvasClick = useCallback(() => {
    if (!isPlaying) deselectAllBeams()
  }, [isPlaying, deselectAllBeams])

  /* ── Playback timer ───────────────────────── */

  const frameDuration = currentFrame?.duration ?? 200

  useEffect(() => {
    if (!isPlaying) return
    const ms = Math.max(16, frameDuration / speed)
    const id = setInterval(() => useEffectEditorStore.getState().advanceFrame(), ms)
    return () => clearInterval(id)
  }, [isPlaying, currentFrameIndex, speed, frameDuration])

  /* ── Keyboard shortcuts ───────────────────── */

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return
      const s = useEffectEditorStore.getState()
      if (s.effectPanelView !== 'editor') return

      if (e.key === ' ') {
        e.preventDefault()
        void (s.isPlaying ? s.pause() : s.play())
      } else if (e.key === 's' && !e.ctrlKey && !e.metaKey) {
        e.preventDefault()
        s.stop()
      } else if (e.key === 'z' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        void (e.shiftKey ? s.redo() : s.undo())
      } else if ((e.key === 'S') && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        s.openSaveDialog()
      } else if (e.key === 'd' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        s.duplicateFrame(s.currentFrameIndex)
      } else if (e.key === 'Delete' || e.key === 'Backspace') {
        s.removeFrame(s.currentFrameIndex)
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault()
        s.setCurrentFrame(Math.max(0, s.currentFrameIndex - 1))
      } else if (e.key === 'ArrowRight') {
        e.preventDefault()
        s.setCurrentFrame(Math.min(s.frames.length - 1, s.currentFrameIndex + 1))
      } else if (e.key === 'a' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault()
        s.selectAllBeams()
      } else if (e.key === 'Escape') {
        s.deselectAllBeams()
        setFrameCtx(null)
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  /* ── Easter egg: all beams aligned ────────── */

  useEffect(() => {
    if (isPlaying) return
    const beams = Object.values(currentFrame?.beams ?? {})
    if (beams.length < 2) return
    const avgX = beams.reduce((a, b) => a + b.x, 0) / beams.length
    const avgY = beams.reduce((a, b) => a + b.y, 0) / beams.length
    const aligned = beams.every((b) => Math.abs(b.x - avgX) < 2 && Math.abs(b.y - avgY) < 2)
    if (aligned && !prevAlignedRef.current) addToast('All beams aligned — maximum power', 'success')
    prevAlignedRef.current = aligned
  }, [isPlaying, currentFrame, addToast])

  /* ── Frame auto-scroll ────────────────────── */

  const tlRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const el = tlRef.current?.querySelector(`[data-fn="${currentFrameIndex}"]`)
    el?.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' })
  }, [currentFrameIndex])

  /* ═══════════ RENDER ══════════════════════════ */

  return (
    <motion.div
      className="flex flex-col h-full"
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      transition={{ duration: 0.25 }}
      onClick={() => frameCtx && setFrameCtx(null)}
    >
      {/* ── Toolbar ───────────────────────────── */}
      <div className="flex items-center gap-2 px-1 pb-2 flex-shrink-0">
        <button className={TB_DEF} onClick={closeEditor}>&larr; Back</button>
        <div className="w-px h-5 bg-neutral-800/50" />
        <button
          className={TB_DEF}
          onClick={() => {
            closeEditor()
            setTimeout(() => useEffectEditorStore.getState().openEditor(), 50)
          }}
        >
          New
        </button>
        <button className={TB_PRI} onClick={openSaveDialog}>Save</button>
        <button className={TB_DEF} onClick={openPresetBrowser}>Presets</button>
        <div className="w-px h-5 bg-neutral-800/50" />
        <button className={TB_DEF} onClick={undo} title="Ctrl+Z">Undo</button>
        <button className={TB_DEF} onClick={redo} title="Ctrl+Shift+Z">Redo</button>
        <div className="flex-1" />
        <span className="text-[10px] text-neutral-700 tabular-nums">
          {frames.length}F &middot; {selectedBeams.length} sel
        </span>
      </div>

      {/* ── Canvas + Properties ───────────────── */}
      <div className="flex-1 flex min-h-0 gap-2">
        {/* Canvas */}
        <div
          ref={canvasRef}
          className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden relative cursor-crosshair"
          style={{
            backgroundImage: 'radial-gradient(circle, rgba(255,255,255,0.04) 1px, transparent 1px)',
            backgroundSize: '24px 24px',
          }}
          onClick={handleCanvasClick}
          onContextMenu={(e) => e.preventDefault()}
        >
          {/* Onion skin */}
          {onionSkin && currentFrameIndex > 0 && (
            <div className="absolute inset-0 pointer-events-none">
              {Object.entries(frames[currentFrameIndex - 1]?.beams ?? {}).map(
                ([k, b]) => {
                  if (!b.visible) return null
                  const n = parseInt(k)
                  return (
                    <div
                      key={`os-${n}`}
                      className="absolute rounded-lg flex items-center justify-center pointer-events-none"
                      style={{
                        left: `${b.x}%`,
                        top: `${b.y}%`,
                        width: 24,
                        height: 24,
                        transform: 'translate(-50%, -50%)',
                        backgroundColor: b.color,
                        opacity: 0.12,
                        border: '1px dashed rgba(255,255,255,0.15)',
                      }}
                    >
                      <span className="text-[7px] text-white/30 pointer-events-none">{n}</span>
                    </div>
                  )
                },
              )}
            </div>
          )}

          {/* Beams */}
          {Object.entries(currentFrame?.beams ?? {}).map(([k, beam]) => {
            const n = parseInt(k)
            const sel = selectedBeams.includes(n)
            const dragged = dragVisual?.beamNum === n
            const bx = dragged ? beam.x + dragVisual.dx : beam.x
            const by = dragged ? beam.y + dragVisual.dy : beam.y
            const sz = 14 + (beam.iris / 100) * 18
            const op = beam.visible ? beam.dimmer / 100 : 0.12

            return (
              <div
                key={n}
                className={`absolute rounded-lg flex items-center justify-center select-none ${
                  dragged ? 'cursor-grabbing' : 'cursor-grab'
                }`}
                style={{
                  left: `${bx}%`,
                  top: `${by}%`,
                  width: sz,
                  height: sz,
                  transform: 'translate(-50%, -50%)',
                  backgroundColor: beam.color,
                  opacity: op,
                  boxShadow: sel
                    ? '0 0 0 2px white, 0 0 10px rgba(255,255,255,0.15)'
                    : 'none',
                  transition: isPlaying
                    ? 'left 60ms linear, top 60ms linear'
                    : 'box-shadow 0.15s',
                  zIndex: dragged ? 30 : sel ? 20 : 10,
                }}
                onMouseDown={(e) => handleBeamMouseDown(e, n)}
              >
                <span
                  className={`text-[8px] font-bold pointer-events-none ${
                    beam.dimmer > 50 ? 'text-black' : 'text-white'
                  }`}
                >
                  {n}
                </span>
              </div>
            )
          })}
        </div>

        {/* Properties */}
        <PropertiesPanel
          currentFrame={currentFrame}
          selectedBeams={selectedBeams}
          applyToAllFrames={applyToAllFrames}
          onApplyToAllChange={setApplyToAllFrames}
          onUpdateBeam={updateBeamInFrame}
          isPlaying={isPlaying}
        />
      </div>

      {/* ── Timeline ──────────────────────────── */}
      <div className="mt-2 flex-shrink-0">
        {/* Playback controls */}
        <div className="flex items-center gap-1.5 px-1 mb-1.5">
          <button
            className={`${TB_ICO} ${isPlaying ? TB_ACT : ''}`}
            onClick={isPlaying ? pause : play}
            title={isPlaying ? 'Pause (Space)' : 'Play (Space)'}
          >
            {isPlaying ? '||' : '>'}
          </button>
          <button className={TB_ICO} onClick={stop} title="Stop (S)">
            []
          </button>
          <div className="w-px h-4 bg-neutral-800/50" />
          <button
            className={TB_ICO}
            style={{ width: 28 }}
            onClick={() => setSpeed(speed - 0.25)}
          >
            &lt;
          </button>
          <span className="text-[10px] text-neutral-500 w-10 text-center font-mono tabular-nums">
            {speed.toFixed(2)}x
          </span>
          <button
            className={TB_ICO}
            style={{ width: 28 }}
            onClick={() => setSpeed(speed + 0.25)}
          >
            &gt;
          </button>
          <div className="w-px h-4 bg-neutral-800/50" />
          <button
            className={`${TB_ICO} ${loop ? TB_ACT : ''}`}
            onClick={toggleLoop}
          >
            Loop
          </button>
          <button
            className={`${TB_ICO} ${onionSkin ? TB_ACT : ''}`}
            onClick={toggleOnionSkin}
          >
            Onion
          </button>
          <div className="flex-1" />
          <span className="text-[10px] text-neutral-700 font-mono tabular-nums">
            F{currentFrameIndex + 1}/{frames.length}
          </span>
        </div>

        {/* Frame strip */}
        <div
          ref={tlRef}
          className="flex items-center gap-1 overflow-x-auto custom-scrollbar pb-1 px-1"
        >
          {frames.map((frame, idx) => {
            const cur = idx === currentFrameIndex
            const easter = frames.length === 31 && idx === 30

            return (
              <div
                key={frame.id}
                data-fn={idx}
                className={`relative flex-shrink-0 w-10 h-10 rounded-lg border flex flex-col items-center justify-center cursor-pointer transition-colors select-none ${
                  cur
                    ? 'border-white bg-neutral-800/50'
                    : 'border-neutral-800/60 bg-neutral-900/30 hover:border-neutral-700'
                }`}
                onClick={(e) => {
                  e.stopPropagation()
                  setCurrentFrame(idx)
                }}
                onContextMenu={(e) => {
                  e.preventDefault()
                  e.stopPropagation()
                  setFrameCtx({ x: e.clientX, y: e.clientY, index: idx })
                }}
              >
                {easter ? (
                  <motion.span
                    className="text-[7px] font-bold text-white leading-none"
                    animate={{
                      opacity: [0.5, 1, 0.5],
                      textShadow: [
                        '0 0 4px rgba(255,255,255,0)',
                        '0 0 14px rgba(255,255,255,0.7)',
                        '0 0 4px rgba(255,255,255,0)',
                      ],
                    }}
                    transition={{ duration: 2, repeat: Infinity }}
                  >
                    Extra
                  </motion.span>
                ) : (
                  <span className="text-[10px] font-bold text-neutral-300 leading-none">
                    {idx + 1}
                  </span>
                )}
                {easter && (
                  <span className="text-[6px] text-neutral-500 leading-none mt-0.5">Mile</span>
                )}
                {cur && isPlaying && (
                  <motion.div
                    className="absolute -top-1 left-1 right-1 h-[2px] bg-white rounded-full"
                    layoutId="playhead"
                  />
                )}
              </div>
            )
          })}

          {/* Add frame */}
          <motion.button
            className="flex-shrink-0 w-10 h-10 rounded-lg border border-dashed border-neutral-800 flex items-center justify-center text-neutral-600 hover:text-neutral-300 hover:border-neutral-600 transition-colors cursor-pointer"
            onClick={() => addFrame()}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            +
          </motion.button>
        </div>
      </div>

      {/* ── Frame context menu ────────────────── */}
      <AnimatePresence>
        {frameCtx && (
          <>
            <motion.div
              className="fixed inset-0 z-[90]"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setFrameCtx(null)}
            />
            <motion.div
              className="fixed z-[100] w-44 rounded-lg border border-neutral-800 bg-neutral-950/95 backdrop-blur-md p-1 shadow-xl"
              style={{ left: frameCtx.x, top: frameCtx.y }}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
            >
              <button
                className="w-full px-3 py-2 text-[11px] text-neutral-300 hover:bg-neutral-800/50 hover:text-white rounded-md transition-colors cursor-pointer text-left"
                onClick={() => { duplicateFrame(frameCtx.index); setFrameCtx(null) }}
              >
                Duplicate Frame
              </button>
              <button
                className="w-full px-3 py-2 text-[11px] text-neutral-300 hover:bg-neutral-800/50 hover:text-white rounded-md transition-colors cursor-pointer text-left"
                onClick={() => { insertFrameAfter(frameCtx.index); setFrameCtx(null) }}
              >
                Insert After
              </button>
              <button
                className="w-full px-3 py-2 text-[11px] text-neutral-400 hover:bg-neutral-800/50 hover:text-red-400 rounded-md transition-colors cursor-pointer text-left"
                onClick={() => { removeFrame(frameCtx.index); setFrameCtx(null) }}
              >
                Delete Frame
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </motion.div>
  )
}

/* ═══════════════════════════════════════════════════
   Properties Panel
   ═══════════════════════════════════════════════════ */

function PropertiesPanel({
  currentFrame,
  selectedBeams,
  applyToAllFrames,
  onApplyToAllChange,
  onUpdateBeam,
  isPlaying,
}: {
  currentFrame: { beams: Record<number, BeamFrameState> } | undefined
  selectedBeams: number[]
  applyToAllFrames: boolean
  onApplyToAllChange: (v: boolean) => void
  onUpdateBeam: (beamNum: number, updates: Partial<BeamFrameState>) => void
  isPlaying: boolean
}) {
  if (selectedBeams.length === 0) {
    return (
      <div className="w-52 flex-shrink-0 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
        <div className="h-8 flex items-center px-3 border-b border-neutral-800/50 flex-shrink-0">
          <span className="text-[11px] font-semibold text-neutral-300">Properties</span>
        </div>
        <div className="flex-1 flex items-center justify-center p-4">
          <span className="text-[10px] text-neutral-700 text-center leading-relaxed">
            Select a beam on the canvas to edit its properties
          </span>
        </div>
      </div>
    )
  }

  const first = currentFrame?.beams[selectedBeams[0]]
  if (!first) return null
  const isMulti = selectedBeams.length > 1

  const set = (key: keyof BeamFrameState, val: number | string | boolean) => {
    for (const bn of selectedBeams) onUpdateBeam(bn, { [key]: val })
  }

  const COLORS = [
    '#ffffff', '#ff3333', '#ff8800', '#ffdd00',
    '#33ff33', '#00ddff', '#5555ff', '#cc33ff',
    '#ff66aa', '#88ff88', '#88ccff', '#ffaa88',
  ]

  return (
    <div className="w-52 flex-shrink-0 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
      <div className="h-8 flex items-center px-3 border-b border-neutral-800/50 flex-shrink-0">
        <span className="text-[11px] font-semibold text-neutral-300">Properties</span>
        {isMulti && <span className="ml-2 text-[9px] text-neutral-600">({selectedBeams.length})</span>}
      </div>

      <div className="flex-1 overflow-y-auto custom-scrollbar p-3 space-y-3">
        {/* Apply to all frames checkbox */}
        <div
          className="flex items-center gap-2 cursor-pointer"
          onClick={() => onApplyToAllChange(!applyToAllFrames)}
        >
          <div
            className={`w-3.5 h-3.5 rounded border flex items-center justify-center transition-colors ${
              applyToAllFrames ? 'bg-white border-white' : 'border-neutral-700'
            }`}
          >
            {applyToAllFrames && (
              <svg width="8" height="6" viewBox="0 0 10 8" fill="none">
                <path d="M1 4L3.5 6.5L9 1" stroke="black" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            )}
          </div>
          <span className="text-[10px] text-neutral-500">Apply to all frames</span>
        </div>

        <div className="border-t border-neutral-800/30" />

        {/* Color */}
        <div>
          <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 block mb-1.5">
            Color
          </span>
          <div className="flex flex-wrap gap-1 mb-1.5">
            {COLORS.map((c) => (
              <div
                key={c}
                className="w-5 h-5 rounded border cursor-pointer transition-transform hover:scale-110"
                style={{
                  backgroundColor: c,
                  borderColor: first.color === c ? 'white' : 'rgba(255,255,255,0.1)',
                }}
                onClick={() => !isPlaying && set('color', c)}
              />
            ))}
          </div>
          <input
            type="text"
            value={first.color}
            onChange={(e) => set('color', e.target.value)}
            disabled={isPlaying}
            className="w-full h-7 px-2 text-[10px] font-mono text-neutral-300 bg-neutral-900/60 border border-neutral-800 rounded outline-none focus:border-neutral-600 transition-colors disabled:opacity-40"
          />
        </div>

        <div className="border-t border-neutral-800/30" />

        {/* Sliders */}
        <Slider label="Iris" value={first.iris} min={0} max={100} disabled={isPlaying} onChange={(v) => set('iris', v)} />
        <Slider label="Dimmer" value={first.dimmer} min={0} max={100} disabled={isPlaying} onChange={(v) => set('dimmer', v)} />

        <div className="border-t border-neutral-800/30" />

        <Slider label="Tilt" value={first.tilt} min={-45} max={45} disabled={isPlaying} onChange={(v) => set('tilt', v)} />
        <Slider label="Pan" value={first.pan} min={-45} max={45} disabled={isPlaying} onChange={(v) => set('pan', v)} />

        <div className="border-t border-neutral-800/30" />

        {/* Visible toggle */}
        <div className="flex items-center justify-between">
          <span className="text-[10px] text-neutral-500">Visible</span>
          <button
            className={`px-2.5 py-1 rounded text-[10px] font-bold border transition-colors cursor-pointer ${
              first.visible
                ? 'bg-neutral-800/50 border-neutral-700 text-white'
                : 'border-neutral-800/40 text-neutral-600'
            }`}
            onClick={() => set('visible', !first.visible)}
            disabled={isPlaying}
          >
            {first.visible ? 'ON' : 'OFF'}
          </button>
        </div>

        {/* Position read-only */}
        <div>
          <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 block mb-1">
            Position
          </span>
          <div className="flex gap-3">
            <div>
              <span className="text-[8px] text-neutral-700">X</span>
              <div className="text-[11px] text-neutral-400 font-mono tabular-nums">{first.x.toFixed(1)}%</div>
            </div>
            <div>
              <span className="text-[8px] text-neutral-700">Y</span>
              <div className="text-[11px] text-neutral-400 font-mono tabular-nums">{first.y.toFixed(1)}%</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

/* ═══════════════════════════════════════════════════
   Slider sub-component
   ═══════════════════════════════════════════════════ */

function Slider({
  label, value, min, max, disabled, onChange,
}: {
  label: string
  value: number
  min: number
  max: number
  disabled: boolean
  onChange: (v: number) => void
}) {
  return (
    <div>
      <div className="flex items-center justify-between mb-1">
        <span className="text-[10px] text-neutral-500">{label}</span>
        <span className="text-[10px] text-neutral-400 font-mono tabular-nums">{Math.round(value)}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={1}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        disabled={disabled}
        className="w-full h-1 appearance-none bg-neutral-800 rounded-full outline-none cursor-pointer
          [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3
          [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-white [&::-webkit-slider-thumb]:cursor-pointer
          disabled:opacity-40 disabled:cursor-not-allowed"
      />
    </div>
  )
}
