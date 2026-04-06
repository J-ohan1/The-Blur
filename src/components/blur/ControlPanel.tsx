'use client'

import { motion } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { EFFECTS_CATEGORIES } from './effects-categories'

/* ─── Control Panel Layout ────────────────────────────────
   ┌──────────────────┬──────────────────┐
   │  Custom Group    │  Custom Effects  │
   ├──────────────────┴──────────────────┤
   │              Effects               │
   │  ┌─toggles──┐  ┌──scroll list────┐ │
   │  │ On/Off    │  │ Strobe          │ │
   │  │ Hold O/O  │  │ Random Indiv.   │ │
   │  │ Fade O/O  │  │ Wave Up         │ │
   │  │ HoldF O/O │  │ ...             │ │
   │  └───────────┘  └─────────────────┘ │
   └─────────────────────────────────────┘
   ─────────────────────────────────────── */

export function ControlPanel() {
  const {
    masterOnOff,
    holdOnOff,
    fadeOnOff,
    holdFadeOnOff,
    selectedEffect,
    setMasterOnOff,
    setHoldOnOff,
    setFadeOnOff,
    setHoldFadeOnOff,
    setSelectedEffect,
  } = useBlurStore()

  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14 gap-3"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.5, delay: 0.25 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* ── Top Row: Custom Group + Custom Effects ── */}
      <div className="flex gap-3 h-[180px] flex-shrink-0">
        {/* Custom Group */}
        <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden">
          <PanelTitle>Custom Group</PanelTitle>
          <div className="flex-1 flex items-center justify-center">
            <span className="text-[11px] text-neutral-700">Coming soon</span>
          </div>
        </div>

        {/* Custom Effects */}
        <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden">
          <PanelTitle>Custom Effects</PanelTitle>
          <div className="flex-1 flex items-center justify-center">
            <span className="text-[11px] text-neutral-700">Coming soon</span>
          </div>
        </div>
      </div>

      {/* ── Bottom: Effects ── */}
      <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden">
        <PanelTitle>Effects</PanelTitle>

        <div className="flex h-[calc(100%-32px)]">
          {/* Left: Toggles */}
          <div className="w-[200px] flex-shrink-0 border-r border-neutral-800/50 p-4 flex flex-col gap-1">
            <ToggleSwitch
              label="On / Off"
              active={masterOnOff}
              onChange={setMasterOnOff}
            />
            <ToggleSwitch
              label="Hold On / Off"
              active={holdOnOff}
              onChange={setHoldOnOff}
            />
            <ToggleSwitch
              label="Fade On / Off"
              active={fadeOnOff}
              onChange={setFadeOnOff}
            />
            <ToggleSwitch
              label="Hold Fade On / Off"
              active={holdFadeOnOff}
              onChange={setHoldFadeOnOff}
            />
          </div>

          {/* Right: Scrollable Effects List */}
          <div className="flex-1 overflow-y-auto p-3 custom-scrollbar">
            {EFFECTS_CATEGORIES.map((cat) => (
              <div key={cat.category} className="mb-4 last:mb-0">
                {/* Category header */}
                <div className="px-2 py-1.5 mb-1.5">
                  <span className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600">
                    {cat.label}
                  </span>
                </div>

                {/* Effect items */}
                <div className="grid grid-cols-3 gap-1.5">
                  {cat.items.map((effect) => {
                    const isSelected = selectedEffect === effect.id
                    return (
                      <motion.button
                        key={effect.id}
                        className={`relative px-3 py-2 rounded-lg text-[12px] font-medium text-left transition-colors duration-150 cursor-pointer border ${
                          isSelected
                            ? 'bg-neutral-800/60 text-white border-neutral-600'
                            : 'text-neutral-500 border-transparent hover:text-neutral-300 hover:bg-neutral-800/30 hover:border-neutral-800'
                        }`}
                        onClick={() =>
                          setSelectedEffect(isSelected ? null : effect.id)
                        }
                        whileHover={{ scale: 1.01 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        {effect.name}
                        {isSelected && (
                          <motion.div
                            className="absolute inset-0 rounded-lg border border-white/10 pointer-events-none"
                            layoutId="effect-selected"
                            transition={{
                              type: 'spring',
                              stiffness: 400,
                              damping: 30,
                            }}
                          />
                        )}
                      </motion.button>
                    )
                  })}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </motion.div>
  )
}

/* ─── Sub-components ─────────────────────────────────── */

function PanelTitle({ children }: { children: React.ReactNode }) {
  return (
    <div className="h-8 flex items-center px-4 border-b border-neutral-800/50 flex-shrink-0">
      <span className="text-[12px] font-semibold tracking-wide text-neutral-300">
        {children}
      </span>
    </div>
  )
}

function ToggleSwitch({
  label,
  active,
  onChange,
}: {
  label: string
  active: boolean
  onChange: (v: boolean) => void
}) {
  return (
    <button
      className="flex items-center gap-3 w-full px-1 py-2 rounded-lg hover:bg-neutral-800/20 transition-colors duration-150 group cursor-pointer"
      onClick={() => onChange(!active)}
    >
      {/* Toggle track */}
      <div
        className={`relative w-9 h-5 rounded-full transition-colors duration-200 flex-shrink-0 ${
          active ? 'bg-red-500/80' : 'bg-neutral-800'
        }`}
      >
        {/* Toggle thumb */}
        <motion.div
          className="absolute top-0.5 w-4 h-4 rounded-full bg-white shadow-sm"
          animate={{ left: active ? '18px' : '2px' }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
        />
      </div>

      {/* Label */}
      <span
        className={`text-[11px] font-medium transition-colors duration-150 ${
          active ? 'text-neutral-200' : 'text-neutral-600'
        }`}
      >
        {label}
      </span>

      {/* O/X indicator */}
      <span className="ml-auto text-[11px] font-bold">
        {active ? (
          <span className="text-emerald-400">O</span>
        ) : (
          <span className="text-red-500">X</span>
        )}
      </span>
    </button>
  )
}
