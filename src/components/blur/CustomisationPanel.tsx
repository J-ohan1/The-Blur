'use client'

import { useRef, useCallback, useEffect } from 'react'
import { motion } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'

/* ─── Quick pick colors ──────────────────────────── */

const QUICK_COLORS = [
  '#ffffff', '#ff0000', '#ff6600', '#ffcc00', '#33cc33',
  '#0099ff', '#6633ff', '#ff33cc', '#ff6699', '#99ffcc',
  '#cccccc', '#666666', '#333333', '#000000',
]

/* ─── Color patterns ─────────────────────────────── */

const COLOR_PATTERNS = [
  { id: 'rainbow', name: 'Rainbow' },
  { id: 'warm', name: 'Warm' },
  { id: 'cool', name: 'Cool' },
  { id: 'neon', name: 'Neon' },
  { id: 'pastel', name: 'Pastel' },
  { id: 'monochrome', name: 'Mono' },
]

/* ─── Fader definitions ──────────────────────────── */

const FADER_DEFS = [
  { key: 'phase', label: 'Phase', min: 0, max: 255 },
  { key: 'speed', label: 'Speed', min: 0, max: 255 },
  { key: 'iris', label: 'Iris', min: 0, max: 255 },
  { key: 'dimmer', label: 'Dimmer', min: 0, max: 255 },
  { key: 'wing', label: 'Wing', min: 0, max: 255 },
  { key: 'tilt', label: 'Tilt', min: 0, max: 255 },
  { key: 'pan', label: 'Pan', min: 0, max: 255 },
  { key: 'brightness', label: 'Bright', min: 0, max: 255 },
  { key: 'zoom', label: 'Zoom', min: 0, max: 255 },
]

export function CustomisationPanel() {
  const {
    groups,
    selectedGroupId,
    customisation,
    setCustomColor,
    setCustomFader,
    applyOddEven,
    applyLeftRight,
    applyQuickColor,
    applyColorPattern,
  } = useBlurStore()

  const selectedGroup = groups.find((g) => g.id === selectedGroupId)

  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14 gap-3"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* Header with selected group info */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-semibold text-white">Customisation</h2>
          {selectedGroup ? (
            <p className="text-[11px] text-neutral-600 mt-0.5">
              {selectedGroup.name}
            </p>
          ) : (
            <p className="text-[11px] text-neutral-700 mt-0.5">
              {groups.length === 0 ? 'No groups -- create one first' : 'No group selected'}
            </p>
          )}
        </div>
      </div>

      {/* Main content: Left + Right frames */}
      <div className="flex-1 flex gap-3 min-h-0">
        {/* ─── Left Frame: Color Wheel + Selection ─── */}
        <div className="w-[280px] flex-shrink-0 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
          <FrameHeader>Color</FrameHeader>

          <div className="flex-1 overflow-y-auto custom-scrollbar p-4 flex flex-col gap-5">
            {/* Color Wheel + Brightness */}
            <ColorWheelSection
              hue={customisation.colorHue}
              saturation={customisation.colorSaturation}
              brightness={customisation.colorBrightness}
              onColorChange={setCustomColor}
            />

            {/* Selection buttons: All, Odd, Even, Left, Right */}
            <div>
              <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 block mb-2">
                Selection
              </span>
              <div className="grid grid-cols-3 gap-1.5">
                <SelectionButton label="All" onClick={() => applyOddEven('odd')} />
                <SelectionButton label="Odd" onClick={() => applyOddEven('odd')} />
                <SelectionButton label="Even" onClick={() => applyOddEven('even')} />
                <SelectionButton label="Left" onClick={() => applyLeftRight('left')} />
                <SelectionButton label="Right" onClick={() => applyLeftRight('right')} />
                <SelectionButton label="Reset" onClick={() => applyOddEven('odd')} />
              </div>
            </div>

            {/* Quick pick colors */}
            <div>
              <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 block mb-2">
                Quick Colors
              </span>
              <div className="grid grid-cols-7 gap-1.5">
                {QUICK_COLORS.map((color) => (
                  <button
                    key={color}
                    className="w-full aspect-square rounded-md border border-neutral-800/50 hover:border-neutral-600 transition-colors cursor-pointer"
                    style={{ backgroundColor: color }}
                    onClick={() => applyQuickColor(color)}
                  />
                ))}
              </div>
            </div>

            {/* Color patterns */}
            <div>
              <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 block mb-2">
                Color Patterns
              </span>
              <div className="grid grid-cols-3 gap-1.5">
                {COLOR_PATTERNS.map((p) => (
                  <button
                    key={p.id}
                    className="px-2 py-1.5 rounded-lg border border-neutral-800/50 text-[10px] font-medium text-neutral-500 hover:text-neutral-300 hover:border-neutral-700 transition-colors cursor-pointer"
                    onClick={() => applyColorPattern(p.id)}
                  >
                    {p.name}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* ─── Right Frame: Faders ─── */}
        <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
          <FrameHeader>Faders</FrameHeader>

          <div className="flex-1 overflow-y-auto custom-scrollbar p-4">
            <div className="grid grid-cols-3 gap-x-6 gap-y-4">
              {FADER_DEFS.map((fader) => (
                <FaderControl
                  key={fader.key}
                  label={fader.label}
                  value={customisation.faders[fader.key]}
                  min={fader.min}
                  max={fader.max}
                  onChange={(v) => setCustomFader(fader.key, v)}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  )
}

/* ─── Frame Header ───────────────────────────────── */

function FrameHeader({ children }: { children: React.ReactNode }) {
  return (
    <div className="h-8 flex items-center px-4 border-b border-neutral-800/50 flex-shrink-0">
      <span className="text-[12px] font-semibold tracking-wide text-neutral-300">{children}</span>
    </div>
  )
}

/* ─── Selection Button ───────────────────────────── */

function SelectionButton({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button
      className="px-2 py-1.5 rounded-lg border border-neutral-800/50 text-[10px] font-medium text-neutral-500 hover:text-neutral-300 hover:border-neutral-700 transition-colors cursor-pointer"
      onClick={onClick}
    >
      {label}
    </button>
  )
}

/* ─── Color Wheel Section ────────────────────────── */

function ColorWheelSection({
  hue,
  saturation,
  brightness,
  onColorChange,
}: {
  hue: number
  saturation: number
  brightness: number
  onColorChange: (hue: number, sat: number, brightness: number) => void
}) {
  const wheelCanvasRef = useRef<HTMLCanvasElement>(null)
  const brightnessCanvasRef = useRef<HTMLCanvasElement>(null)
  const isDraggingWheel = useRef(false)
  const isDraggingBrightness = useRef(false)

  const wheelSize = 180

  // Draw the color wheel
  const drawWheel = useCallback(() => {
    const canvas = wheelCanvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const cx = wheelSize / 2
    const cy = wheelSize / 2
    const outerRadius = wheelSize / 2 - 4
    const innerRadius = outerRadius - 24

    ctx.clearRect(0, 0, wheelSize, wheelSize)

    // Draw color wheel (HSV hue ring)
    for (let angle = 0; angle < 360; angle += 1) {
      const startAngle = ((angle - 1) * Math.PI) / 180
      const endAngle = ((angle + 1) * Math.PI) / 180

      ctx.beginPath()
      ctx.arc(cx, cy, outerRadius, startAngle, endAngle)
      ctx.arc(cx, cy, innerRadius, endAngle, startAngle, true)
      ctx.closePath()
      ctx.fillStyle = `hsl(${angle}, 100%, 50%)`
      ctx.fill()
    }

    // Draw indicator on the hue ring
    const indicatorAngle = (hue * Math.PI) / 180
    const midRadius = (outerRadius + innerRadius) / 2
    const ix = cx + midRadius * Math.cos(indicatorAngle - Math.PI / 2)
    const iy = cy + midRadius * Math.sin(indicatorAngle - Math.PI / 2)

    ctx.beginPath()
    ctx.arc(ix, iy, 7, 0, Math.PI * 2)
    ctx.strokeStyle = '#ffffff'
    ctx.lineWidth = 2
    ctx.stroke()
    ctx.beginPath()
    ctx.arc(ix, iy, 5, 0, Math.PI * 2)
    ctx.fillStyle = `hsl(${hue}, 100%, 50%)`
    ctx.fill()

    // Draw inner circle with saturation gradient
    const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, innerRadius - 2)
    const baseColor = `hsl(${hue}, ${saturation}%, ${brightness / 2.55}%)`
    grad.addColorStop(0, `hsl(${hue}, ${saturation}%, ${Math.min(100, brightness / 2.55 + 20)}%)`)
    grad.addColorStop(1, baseColor)

    ctx.beginPath()
    ctx.arc(cx, cy, innerRadius - 2, 0, Math.PI * 2)
    ctx.fillStyle = grad
    ctx.fill()
  }, [hue, saturation, brightness])

  // Draw brightness slider
  const drawBrightnessSlider = useCallback(() => {
    const canvas = brightnessCanvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const w = 20
    const h = 180

    ctx.clearRect(0, 0, w, h)

    // White to black gradient
    const grad = ctx.createLinearGradient(0, 0, 0, h)
    grad.addColorStop(0, '#ffffff')
    grad.addColorStop(1, '#000000')
    ctx.fillStyle = grad

    // Rounded rect
    const r = 4
    ctx.beginPath()
    ctx.moveTo(r, 0)
    ctx.lineTo(w - r, 0)
    ctx.quadraticCurveTo(w, 0, w, r)
    ctx.lineTo(w, h - r)
    ctx.quadraticCurveTo(w, h, w - r, h)
    ctx.lineTo(r, h)
    ctx.quadraticCurveTo(0, h, 0, h - r)
    ctx.lineTo(0, r)
    ctx.quadraticCurveTo(0, 0, r, 0)
    ctx.closePath()
    ctx.fill()

    // Indicator
    const indicatorY = h - (brightness / 255) * h
    ctx.beginPath()
    ctx.roundRect(-2, indicatorY - 3, w + 4, 6, 3)
    ctx.fillStyle = '#ffffff'
    ctx.fill()
    ctx.beginPath()
    ctx.roundRect(0, indicatorY - 2, w, 4, 2)
    ctx.strokeStyle = '#000000'
    ctx.lineWidth = 1
    ctx.stroke()
  }, [brightness])

  useEffect(() => {
    drawWheel()
    drawBrightnessSlider()
  }, [drawWheel, drawBrightnessSlider])

  // Handle wheel interaction
  const handleWheelInteract = useCallback((e: React.MouseEvent) => {
    const canvas = wheelCanvasRef.current
    if (!canvas) return
    const rect = canvas.getBoundingClientRect()
    const x = e.clientX - rect.left - wheelSize / 2
    const y = e.clientY - rect.top - wheelSize / 2
    const dist = Math.sqrt(x * x + y * y)
    const outerRadius = wheelSize / 2 - 4
    const innerRadius = outerRadius - 24

    if (dist >= innerRadius && dist <= outerRadius) {
      let angle = Math.atan2(y, x) * (180 / Math.PI) + 90
      if (angle < 0) angle += 360
      onColorChange(angle, saturation, brightness)
    }
  }, [saturation, brightness, onColorChange])

  // Handle brightness slider interaction
  const handleBrightnessInteract = useCallback((e: React.MouseEvent) => {
    const canvas = brightnessCanvasRef.current
    if (!canvas) return
    const rect = canvas.getBoundingClientRect()
    const y = Math.max(0, Math.min(180, e.clientY - rect.top))
    const val = Math.round(((180 - y) / 180) * 255)
    onColorChange(hue, saturation, val)
  }, [hue, saturation, onColorChange])

  // Mouse events
  useEffect(() => {
    const handleUp = () => {
      isDraggingWheel.current = false
      isDraggingBrightness.current = false
    }
    const handleMove = (e: MouseEvent) => {
      if (isDraggingWheel.current) {
        const canvas = wheelCanvasRef.current
        if (!canvas) return
        const rect = canvas.getBoundingClientRect()
        const x = e.clientX - rect.left - wheelSize / 2
        const y = e.clientY - rect.top - wheelSize / 2
        const dist = Math.sqrt(x * x + y * y)
        const outerRadius = wheelSize / 2 - 4
        const innerRadius = outerRadius - 24
        if (dist >= innerRadius - 10 && dist <= outerRadius + 10) {
          let angle = Math.atan2(y, x) * (180 / Math.PI) + 90
          if (angle < 0) angle += 360
          onColorChange(angle, saturation, brightness)
        }
      }
      if (isDraggingBrightness.current) {
        const canvas = brightnessCanvasRef.current
        if (!canvas) return
        const rect = canvas.getBoundingClientRect()
        const y = Math.max(0, Math.min(180, e.clientY - rect.top))
        const val = Math.round(((180 - y) / 180) * 255)
        onColorChange(hue, saturation, val)
      }
    }
    window.addEventListener('mouseup', handleUp)
    window.addEventListener('mousemove', handleMove)
    return () => {
      window.removeEventListener('mouseup', handleUp)
      window.removeEventListener('mousemove', handleMove)
    }
  }, [hue, saturation, brightness, onColorChange])

  const currentColor = `hsl(${hue}, ${saturation}%, ${Math.round(brightness / 2.55)}%)`

  return (
    <div className="flex items-start justify-center gap-3">
      {/* Color wheel */}
      <canvas
        ref={wheelCanvasRef}
        width={wheelSize}
        height={wheelSize}
        className="cursor-crosshair"
        onMouseDown={(e) => {
          isDraggingWheel.current = true
          handleWheelInteract(e)
        }}
      />

      {/* Brightness slider */}
      <div className="flex flex-col items-center gap-2">
        <canvas
          ref={brightnessCanvasRef}
          width={20}
          height={180}
          className="cursor-pointer"
          onMouseDown={(e) => {
            isDraggingBrightness.current = true
            handleBrightnessInteract(e)
          }}
        />
        <div
          className="w-5 h-5 rounded-md border border-neutral-700"
          style={{ backgroundColor: currentColor }}
        />
      </div>
    </div>
  )
}

/* ─── Fader Control ──────────────────────────────── */

function FaderControl({
  label,
  value,
  min,
  max,
  onChange,
}: {
  label: string
  value: number
  min: number
  max: number
  onChange: (v: number) => void
}) {
  const sliderRef = useRef<HTMLDivElement>(null)
  const isDragging = useRef(false)
  const percentage = ((value - min) / (max - min)) * 100

  const updateValue = useCallback((clientX: number) => {
    const slider = sliderRef.current
    if (!slider) return
    const rect = slider.getBoundingClientRect()
    const x = Math.max(0, Math.min(rect.width, clientX - rect.left))
    const pct = x / rect.width
    const newValue = Math.round(min + pct * (max - min))
    onChange(newValue)
  }, [min, max, onChange])

  useEffect(() => {
    const handleUp = () => { isDragging.current = false }
    const handleMove = (e: MouseEvent) => {
      if (isDragging.current) updateValue(e.clientX)
    }
    window.addEventListener('mouseup', handleUp)
    window.addEventListener('mousemove', handleMove)
    return () => {
      window.removeEventListener('mouseup', handleUp)
      window.removeEventListener('mousemove', handleMove)
    }
  }, [updateValue])

  return (
    <div className="flex flex-col gap-2">
      {/* Label + Value */}
      <div className="flex items-center justify-between">
        <span className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600">
          {label}
        </span>
        <span className="text-[10px] font-mono text-neutral-400">
          {value}
        </span>
      </div>

      {/* Slider track */}
      <div
        ref={sliderRef}
        className="relative h-2 rounded-full bg-neutral-800/60 cursor-pointer group"
        onMouseDown={(e) => {
          isDragging.current = true
          updateValue(e.clientX)
        }}
      >
        {/* Filled portion */}
        <div
          className="absolute left-0 top-0 h-full rounded-full bg-neutral-400 transition-[width] duration-75"
          style={{ width: `${percentage}%` }}
        />

        {/* Thumb */}
        <div
          className="absolute top-1/2 -translate-y-1/2 w-3 h-3 rounded-full bg-white shadow-sm transition-[left] duration-75 group-hover:scale-110"
          style={{ left: `calc(${percentage}% - 6px)` }}
        />

        {/* Hover zone */}
        <div className="absolute inset-0" />
      </div>
    </div>
  )
}
