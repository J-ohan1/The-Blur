'use client'

import { useEffect, useRef, useState, useCallback, useMemo } from 'react'
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

  /* ── Easter egg refs ──────────────────────── */

  const prevAlignedRef = useRef(false)
  const speedEasterRef = useRef(false)
  const frame42ToastRef = useRef(false)
  const lastSyncColorRef = useRef('')

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

  /* ── Easter egg: max speed + 30+ frames ──── */

  useEffect(() => {
    if (speed >= 4 && frames.length >= 30 && !isPlaying) {
      if (!speedEasterRef.current) {
        addToast('Maximum velocity engaged', 'success')
        speedEasterRef.current = true
      }
    } else {
      speedEasterRef.current = false
    }
  }, [speed, frames.length, isPlaying, addToast])

  /* ── Easter egg: 42 frames ────────────────── */

  useEffect(() => {
    if (frames.length === 42 && !frame42ToastRef.current) {
      frame42ToastRef.current = true
      addToast('The meaning of life, 42 frames at a time', 'success')
    }
    if (frames.length !== 42) frame42ToastRef.current = false
  }, [frames.length, addToast])

  /* ── Easter egg: invisible mode ───────────── */

  useEffect(() => {
    if (isPlaying || selectedBeams.length < 15) return
    const beams = selectedBeams.map((b) => currentFrame?.beams[b]).filter(Boolean)
    if (beams.every((b) => b!.iris === 0)) {
      addToast('Invisible mode activated — where did they go?', 'success')
    }
  }, [selectedBeams, currentFrame, isPlaying, addToast])

  /* ── Easter egg: beam synchronization ─────── */

  useEffect(() => {
    if (isPlaying) return
    const beams = Object.values(currentFrame?.beams ?? {})
    if (beams.length < 3) return
    const allSameColor = beams.every((b) => b.color === beams[0].color && b.color !== '#ffffff' && b.color !== '#000000')
    if (allSameColor && beams[0].color !== lastSyncColorRef.current) {
      lastSyncColorRef.current = beams[0].color
      addToast(`Beam synchronization achieved -- ${beams[0].color}`, 'success')
    } else if (!allSameColor) {
      lastSyncColorRef.current = ''
    }
  }, [currentFrame, isPlaying, addToast])

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
          {/* Center crosshair guides */}
          <div className="absolute inset-0 pointer-events-none">
            <div className="absolute left-1/2 top-0 bottom-0 w-px bg-neutral-800/20" />
            <div className="absolute top-1/2 left-0 right-0 h-px bg-neutral-800/20" />
            <span className="absolute top-1 right-2 text-[7px] text-neutral-800 pointer-events-none select-none">UP</span>
            <span className="absolute bottom-1 right-2 text-[7px] text-neutral-800 pointer-events-none select-none">DOWN</span>
            <span className="absolute top-1/2 left-2 -translate-y-1/2 text-[7px] text-neutral-800 pointer-events-none select-none">L</span>
            <span className="absolute top-1/2 right-2 -translate-y-1/2 text-[7px] text-neutral-800 pointer-events-none select-none">R</span>
          </div>

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

        {/* Beam strip (1x15 row) */}
        <div className="px-1 mb-1.5">
          <div className="flex items-center gap-0.5 px-1 py-1 rounded-lg bg-neutral-900/30 border border-neutral-800/30">
            <span className="text-[8px] text-neutral-700 w-6 flex-shrink-0 mr-1">BEAM</span>
            {Array.from({ length: 15 }, (_, i) => i + 1).map((num) => {
              const sel = selectedBeams.includes(num)
              const beam = currentFrame?.beams[num]
              return (
                <motion.button
                  key={num}
                  className={`flex-shrink-0 w-7 h-6 rounded flex items-center justify-center text-[8px] font-bold border transition-colors cursor-pointer ${
                    sel
                      ? 'border-white bg-neutral-800/50 text-white'
                      : 'border-neutral-800/40 text-neutral-500 hover:text-neutral-300 hover:border-neutral-700'
                  }`}
                  style={beam && sel ? { backgroundColor: beam.color, color: beam.dimmer > 50 ? 'black' : 'white' } : undefined}
                  onClick={(e) => {
                    e.stopPropagation()
                    if (!isPlaying) selectBeam(num, e.shiftKey)
                  }}
                  whileHover={{ scale: 1.08 }}
                  whileTap={{ scale: 0.94 }}
                >
                  {num}
                </motion.button>
              )
            })}
          </div>
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
            <FrameContextMenu
              x={frameCtx.x}
              y={frameCtx.y}
              index={frameCtx.index}
              onDuplicate={(idx) => { duplicateFrame(idx); setFrameCtx(null) }}
              onInsertAfter={(idx) => { insertFrameAfter(idx); setFrameCtx(null) }}
              onRemove={(idx) => { removeFrame(idx); setFrameCtx(null) }}
            />
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
            Select a beam to edit its properties
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

        {/* Color Wheel */}
        <ColorWheel
          color={first.color}
          disabled={isPlaying}
          onChange={(color) => set('color', color)}
        />

        <div className="border-t border-neutral-800/30" />

        {/* Sliders */}
        <Slider label="Iris" value={first.iris} min={0} max={100} disabled={isPlaying} onChange={(v) => set('iris', v)} />
        <Slider label="Dimmer" value={first.dimmer} min={0} max={100} disabled={isPlaying} onChange={(v) => set('dimmer', v)} />

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
            Position (Canvas)
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
          <span className="text-[7px] text-neutral-800 mt-1 block">
            Y = tilt direction (up/down)
          </span>
        </div>
      </div>
    </div>
  )
}

/* ═══════════════════════════════════════════════════
   Color Wheel Component
   ═══════════════════════════════════════════════════ */

function ColorWheel({
  color,
  disabled,
  onChange,
}: {
  color: string
  disabled: boolean
  onChange: (color: string) => void
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const brightnessRef = useRef<HTMLCanvasElement>(null)
  const isDraggingBrightness = useRef(false)
  const hsvRef = useRef({ h: 0, s: 0, v: 1 })

  /* Sync ref when color prop changes */
  useEffect(() => {
    const rgb = hexToRgb(color)
    if (!rgb) return
    const hsv = rgbToHsv(rgb.r, rgb.g, rgb.b)
    hsvRef.current = hsv
  }, [color])

  /* Draw the entire color wheel */
  const drawAll = useCallback(() => {
    const canvas = canvasRef.current
    const bCanvas = brightnessRef.current
    if (!canvas || !bCanvas) return

    const hsv = hsvRef.current
    const size = canvas.width
    const cx = size / 2
    const cy = size / 2
    const outerR = size / 2 - 2
    const innerR = outerR - 14

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    ctx.clearRect(0, 0, size, size)

    // Hue ring
    for (let angle = 0; angle < 360; angle += 1) {
      const startAngle = ((angle - 1) * Math.PI) / 180
      const endAngle = ((angle + 1) * Math.PI) / 180
      ctx.beginPath()
      ctx.arc(cx, cy, outerR, startAngle, endAngle)
      ctx.arc(cx, cy, innerR, endAngle, startAngle, true)
      ctx.closePath()
      ctx.fillStyle = `hsl(${angle}, 80%, 50%)`
      ctx.fill()
    }

    // Inner fill (saturation)
    const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, innerR - 1)
    grad.addColorStop(0, `hsl(${hsv.h}, 0%, 100%)`)
    grad.addColorStop(1, `hsl(${hsv.h}, 100%, 50%)`)
    ctx.beginPath()
    ctx.arc(cx, cy, innerR - 1, 0, Math.PI * 2)
    ctx.fillStyle = grad
    ctx.fill()

    // Hue indicator on ring
    const indicatorAngle = (hsv.h * Math.PI) / 180
    const midR = (outerR + innerR) / 2
    const ix = cx + Math.cos(indicatorAngle) * midR
    const iy = cy + Math.sin(indicatorAngle) * midR
    ctx.beginPath()
    ctx.arc(ix, iy, 5, 0, Math.PI * 2)
    ctx.fillStyle = '#ffffff'
    ctx.fill()
    ctx.strokeStyle = '#000000'
    ctx.lineWidth = 1
    ctx.stroke()

    // Sat/val indicator in center
    const satValX = cx - innerR + 2 + hsv.s * (innerR * 2 - 4)
    const satValY = cy - innerR + 2 + (1 - hsv.v) * (innerR * 2 - 4)
    ctx.beginPath()
    ctx.arc(satValX, satValY, 4, 0, Math.PI * 2)
    ctx.fillStyle = color
    ctx.fill()
    ctx.strokeStyle = '#ffffff'
    ctx.lineWidth = 1.5
    ctx.stroke()

    // Brightness slider
    const bCtx = bCanvas.getContext('2d')
    if (!bCtx) return
    const w = bCanvas.width
    const h = bCanvas.height
    bCtx.clearRect(0, 0, w, h)
    const bGrad = bCtx.createLinearGradient(0, 0, 0, h)
    bGrad.addColorStop(0, `hsl(${hsv.h}, ${Math.round(hsv.s * 100)}%, 100%)`)
    bGrad.addColorStop(1, `hsl(${hsv.h}, ${Math.round(hsv.s * 100)}%, 0%)`)
    bCtx.fillStyle = bGrad
    bCtx.beginPath()
    bCtx.roundRect(0, 0, w, h, 3)
    bCtx.fill()
    const thumbY = (1 - hsv.v) * (h - 4) + 2
    bCtx.beginPath()
    bCtx.roundRect(1, thumbY - 3, w - 2, 6, 2)
    bCtx.fillStyle = '#ffffff'
    bCtx.fill()
    bCtx.strokeStyle = '#000000'
    bCtx.lineWidth = 1
    bCtx.stroke()
  }, [color])

  /* Draw when color changes */
  useEffect(() => {
    drawAll()
  }, [drawAll])

  /* Handle ring click */
  const handleClick = useCallback(
    (e: React.MouseEvent) => {
      if (disabled) return
      const canvas = canvasRef.current
      const bCanvas = brightnessRef.current
      if (!canvas || !bCanvas) return
      const rect = canvas.getBoundingClientRect()
      const x = e.clientX - rect.left
      const y = e.clientY - rect.top
      const cx = canvas.width / 2
      const cy = canvas.height / 2
      const dx = x - cx
      const dy = y - cy
      const dist = Math.sqrt(dx * dx + dy * dy)
      const outerR = canvas.width / 2 - 2
      const innerR = outerR - 14
      const hsv = hsvRef.current

      if (dist >= innerR && dist <= outerR) {
        // Hue ring click
        const angle = Math.atan2(dy, dx) * (180 / Math.PI)
        const hueVal = (angle + 360) % 360
        hsvRef.current = { ...hsv, h: hueVal }
        const rgb = hsvToRgb(hueVal, hsv.s, hsv.v)
        onChange(rgbToHex(rgb.r, rgb.g, rgb.b))
      } else if (dist < innerR - 1) {
        // Saturation/brightness area
        const normalizedX = Math.max(0, Math.min(1, (x - (cx - innerR + 2)) / (innerR * 2 - 4)))
        const normalizedY = Math.max(0, Math.min(1, (y - (cy - innerR + 2)) / (innerR * 2 - 4)))
        hsvRef.current = { ...hsv, s: normalizedX, v: 1 - normalizedY }
        const rgb = hsvToRgb(hsv.h, normalizedX, 1 - normalizedY)
        onChange(rgbToHex(rgb.r, rgb.g, rgb.b))
      }
    },
    [disabled, onChange],
  )

  const handleBrightnessClick = useCallback(
    (e: React.MouseEvent) => {
      if (disabled) return
      const canvas = brightnessRef.current
      if (!canvas) return
      const rect = canvas.getBoundingClientRect()
      const y = e.clientY - rect.top
      const val = 1 - Math.max(0, Math.min(1, y / canvas.height))
      const hsv = hsvRef.current
      hsvRef.current = { ...hsv, v: val }
      const rgb = hsvToRgb(hsv.h, hsv.s, val)
      onChange(rgbToHex(rgb.r, rgb.g, rgb.b))
    },
    [disabled, onChange],
  )

  return (
    <div>
      <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 block mb-1.5">
        Color
      </span>
      <div className="flex flex-col items-center gap-1.5">
        <canvas
          ref={canvasRef}
          width={120}
          height={120}
          className={`rounded-full ${disabled ? 'opacity-40 cursor-not-allowed' : 'cursor-pointer'}`}
          onClick={handleClick}
          onMouseDown={(e) => {
            handleClick(e)
          }}
        />
        <canvas
          ref={brightnessRef}
          width={120}
          height={12}
          className={`rounded ${disabled ? 'opacity-40 cursor-not-allowed' : 'cursor-pointer'}`}
          onClick={handleBrightnessClick}
          onMouseDown={(e) => {
            isDraggingBrightness.current = true
            handleBrightnessClick(e)
          }}
        />
        <span className="text-[8px] text-neutral-700 font-mono">{color}</span>
      </div>
    </div>
  )
}

/* ── Color conversion helpers ─────────────────── */

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  return result
    ? { r: parseInt(result[1], 16), g: parseInt(result[2], 16), b: parseInt(result[3], 16) }
    : null
}

function rgbToHex(r: number, g: number, b: number): string {
  return '#' + [r, g, b].map((x) => Math.max(0, Math.min(255, Math.round(x))).toString(16).padStart(2, '0')).join('')
}

function rgbToHsv(r: number, g: number, b: number): { h: number; s: number; v: number } {
  r /= 255; g /= 255; b /= 255
  const max = Math.max(r, g, b), min = Math.min(r, g, b)
  const d = max - min
  let h = 0
  const s = max === 0 ? 0 : d / max
  const v = max
  if (d !== 0) {
    if (max === r) h = ((g - b) / d + 6) % 6
    else if (max === g) h = (b - r) / d + 2
    else h = (r - g) / d + 4
    h *= 60
  }
  return { h, s, v }
}

function hsvToRgb(h: number, s: number, v: number): { r: number; g: number; b: number } {
  const c = v * s
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1))
  const m = v - c
  let r = 0, g = 0, b = 0
  if (h < 60) { r = c; g = x }
  else if (h < 120) { r = x; g = c }
  else if (h < 180) { g = c; b = x }
  else if (h < 240) { g = x; b = c }
  else if (h < 300) { r = x; b = c }
  else { r = c; b = x }
  return {
    r: Math.round((r + m) * 255),
    g: Math.round((g + m) * 255),
    b: Math.round((b + m) * 255),
  }
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

/* ═══════════════════════════════════════════════════
   Viewport-aware Context Menu
   ═══════════════════════════════════════════════════ */

function FrameContextMenu({
  x,
  y,
  index,
  onDuplicate,
  onInsertAfter,
  onRemove,
}: {
  x: number
  y: number
  index: number
  onDuplicate: (idx: number) => void
  onInsertAfter: (idx: number) => void
  onRemove: (idx: number) => void
}) {
  const menuHeight = 120 // approximate height of 3 menu items
  const menuWidth = 176
  const pos = useMemo(() => {
    const vh = window.innerHeight
    const vw = window.innerWidth
    const flipY = y + menuHeight > vh
    const flipX = x + menuWidth > vw
    return {
      left: flipX ? x - menuWidth : x,
      top: flipY ? y - menuHeight : y,
    }
  }, [x, y])

  return (
    <motion.div
      className="fixed z-[100] w-44 rounded-lg border border-neutral-800 bg-neutral-950/95 backdrop-blur-md p-1 shadow-xl"
      style={{ left: pos.left, top: pos.top }}
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 0.12 }}
    >
      <button
        className="w-full px-3 py-2 text-[11px] text-neutral-300 hover:bg-neutral-800/50 hover:text-white rounded-md transition-colors cursor-pointer text-left"
        onClick={() => onDuplicate(index)}
      >
        Duplicate Frame
      </button>
      <button
        className="w-full px-3 py-2 text-[11px] text-neutral-300 hover:bg-neutral-800/50 hover:text-white rounded-md transition-colors cursor-pointer text-left"
        onClick={() => onInsertAfter(index)}
      >
        Insert After
      </button>
      <button
        className="w-full px-3 py-2 text-[11px] text-neutral-400 hover:bg-neutral-800/50 hover:text-red-400 rounded-md transition-colors cursor-pointer text-left"
        onClick={() => onRemove(index)}
      >
        Delete Frame
      </button>
    </motion.div>
  )
}
