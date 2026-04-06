'use client'

import { useCallback } from 'react'
import { motion } from 'framer-motion'
import { useBlurStore, type LaserGroup } from '@/store/blur-store'
import { EFFECTS_CATEGORIES } from './effects-categories'
import { Zap } from 'lucide-react'

export function ControlPanel() {
  const {
    groups,
    masterOnOff,
    fadeOnOff,
    holdOnOff,
    holdFadeOnOff,
    selectedEffect,
    setMasterOnOff,
    setFadeOnOff,
    setHoldOnOff,
    setHoldFadeOnOff,
    setSelectedEffect,
  } = useBlurStore()

  const handleHoldOnDown = useCallback(() => setHoldOnOff(true), [setHoldOnOff])
  const handleHoldOnUp = useCallback(() => setHoldOnOff(false), [setHoldOnOff])
  const handleHoldFadeDown = useCallback(() => setHoldFadeOnOff(true), [setHoldFadeOnOff])
  const handleHoldFadeUp = useCallback(() => setHoldFadeOnOff(false), [setHoldFadeOnOff])

  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14 gap-3"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* ── Top Row ── */}
      <div className="flex gap-3 h-[180px] flex-shrink-0">
        <CustomGroupPanel groups={groups} />
        <PanelFrame title="Custom Effects">
          <EmptyState />
        </PanelFrame>
      </div>

      {/* ── Bottom: Effects ── */}
      <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
        <PanelHeader>Effects</PanelHeader>

        <div className="flex flex-1 min-h-0">
          {/* Left: Toggles + Hold Buttons */}
          <div className="w-[210px] flex-shrink-0 border-r border-neutral-800/50 p-3 flex flex-col gap-0.5">
            {/* Section: Normal Toggles */}
            <SectionLabel>Toggles</SectionLabel>
            <ToggleSwitch label="On / Off" active={masterOnOff} onChange={setMasterOnOff} />
            <ToggleSwitch label="Fade On / Off" active={fadeOnOff} onChange={setFadeOnOff} />

            <div className="my-2 border-t border-neutral-800/40" />

            {/* Section: Hold Buttons */}
            <SectionLabel>Hold</SectionLabel>
            <HoldButton
              label="Hold On / Off"
              active={holdOnOff}
              onMouseDown={handleHoldOnDown}
              onMouseUp={handleHoldOnUp}
              onMouseLeave={handleHoldOnUp}
            />
            <HoldButton
              label="Hold Fade On / Off"
              active={holdFadeOnOff}
              onMouseDown={handleHoldFadeDown}
              onMouseUp={handleHoldFadeUp}
              onMouseLeave={handleHoldFadeUp}
            />
          </div>

          {/* Right: Scrollable Effects */}
          <div className="flex-1 overflow-y-auto p-3 custom-scrollbar">
            {EFFECTS_CATEGORIES.map((cat) => (
              <div key={cat.category} className="mb-4 last:mb-0">
                <div className="px-2 py-1.5 mb-1.5">
                  <span className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600">
                    {cat.label}
                  </span>
                </div>
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
                        onClick={() => setSelectedEffect(isSelected ? null : effect.id)}
                        whileHover={{ scale: 1.01 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        {effect.name}
                        {isSelected && (
                          <motion.div
                            className="absolute inset-0 rounded-lg border border-white/10 pointer-events-none"
                            layoutId="effect-selected"
                            transition={{ type: 'spring', stiffness: 400, damping: 30 }}
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

/* ─── Sub-components ──────────────────────────────── */

function PanelFrame({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
      <PanelHeader>{title}</PanelHeader>
      <div className="flex-1 flex items-center justify-center">{children}</div>
    </div>
  )
}

function PanelHeader({ children }: { children: React.ReactNode }) {
  return (
    <div className="h-8 flex items-center px-4 border-b border-neutral-800/50 flex-shrink-0">
      <span className="text-[12px] font-semibold tracking-wide text-neutral-300">{children}</span>
    </div>
  )
}

function EmptyState() {
  return <span className="text-[11px] text-neutral-700">Coming soon</span>
}

/* ─── Custom Group Panel (synced from Group panel) ─ */

function CustomGroupPanel({ groups }: { groups: LaserGroup[] }) {
  if (groups.length === 0) {
    return (
      <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
        <PanelHeader>Custom Group</PanelHeader>
        <div className="flex-1 flex flex-col items-center justify-center gap-2">
          <Zap className="w-5 h-5 text-neutral-800" />
          <span className="text-[11px] text-neutral-700">No groups yet</span>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
      <PanelHeader>Custom Group</PanelHeader>
      <div className="flex-1 overflow-y-auto custom-scrollbar p-2 space-y-1">
        {groups.map((group) => (
          <div
            key={group.id}
            className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg hover:bg-neutral-800/20 transition-colors cursor-pointer group"
          >
            <span className="text-[11px] font-medium text-neutral-300 group-hover:text-white truncate">
              {group.name}
            </span>
            <span className="text-[9px] px-1.5 py-0.5 rounded bg-neutral-800/60 text-neutral-500 flex-shrink-0">
              {group.mode === 'fixture'
                ? `${group.selectedFixtures.length}F`
                : `${group.selectedBeams.length}B`}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 px-1 py-1.5">
      {children}
    </span>
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
      className="flex items-center gap-3 w-full px-1 py-2 rounded-lg hover:bg-neutral-800/20 transition-colors duration-150 cursor-pointer"
      onClick={() => onChange(!active)}
    >
      <div
        className={`relative w-9 h-5 rounded-full transition-colors duration-200 flex-shrink-0 ${
          active ? 'bg-red-500/80' : 'bg-neutral-800'
        }`}
      >
        <motion.div
          className="absolute top-0.5 w-4 h-4 rounded-full bg-white shadow-sm"
          animate={{ left: active ? '18px' : '2px' }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
        />
      </div>
      <span className={`text-[11px] font-medium transition-colors duration-150 ${active ? 'text-neutral-200' : 'text-neutral-600'}`}>
        {label}
      </span>
      <span className="ml-auto text-[11px] font-bold">
        {active ? <span className="text-emerald-400">O</span> : <span className="text-red-500">X</span>}
      </span>
    </button>
  )
}

function HoldButton({
  label,
  active,
  onMouseDown,
  onMouseUp,
  onMouseLeave,
}: {
  label: string
  active: boolean
  onMouseDown: () => void
  onMouseUp: () => void
  onMouseLeave: () => void
}) {
  return (
    <button
      className={`relative flex items-center justify-center w-full px-3 py-2.5 rounded-lg border transition-all duration-150 select-none cursor-pointer ${
        active
          ? 'bg-red-500/15 border-red-500/40 text-white'
          : 'bg-neutral-900/30 border-neutral-800 text-neutral-500 hover:border-neutral-700 hover:text-neutral-300'
      }`}
      onMouseDown={onMouseDown}
      onMouseUp={onMouseUp}
      onMouseLeave={onMouseLeave}
    >
      {active && (
        <motion.div
          className="absolute inset-0 rounded-lg bg-red-500/5 pointer-events-none"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
        />
      )}
      <span className="text-[11px] font-medium">{label}</span>
      <span className="ml-2 text-[11px] font-bold">
        {active ? <span className="text-emerald-400">O</span> : <span className="text-red-500/60">X</span>}
      </span>
    </button>
  )
}
