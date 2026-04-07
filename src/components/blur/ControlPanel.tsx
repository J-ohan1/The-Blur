'use client'

import { useCallback, useState, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useBlurStore, type LaserGroup } from '@/store/blur-store'
import { EFFECTS_CATEGORIES } from './effects-categories'
import { useEffectEditorStore } from '@/store/effect-editor-store'

export function ControlPanel() {
  const groups = useBlurStore((s) => s.groups)
  const selectedGroupIds = useBlurStore((s) => s.selectedGroupIds)
  const masterOnOff = useBlurStore((s) => s.masterOnOff)
  const fadeOnOff = useBlurStore((s) => s.fadeOnOff)
  const holdOnOff = useBlurStore((s) => s.holdOnOff)
  const holdFadeOnOff = useBlurStore((s) => s.holdFadeOnOff)
  const selectedEffect = useBlurStore((s) => s.selectedEffect)
  const tiltDirection = useBlurStore((s) => s.tiltDirection)
  const panDirection = useBlurStore((s) => s.panDirection)
  const setMasterOnOff = useBlurStore((s) => s.setMasterOnOff)
  const setFadeOnOff = useBlurStore((s) => s.setFadeOnOff)
  const setHoldOnOff = useBlurStore((s) => s.setHoldOnOff)
  const setHoldFadeOnOff = useBlurStore((s) => s.setHoldFadeOnOff)
  const setSelectedEffect = useBlurStore((s) => s.setSelectedEffect)
  const setTiltDirection = useBlurStore((s) => s.setTiltDirection)
  const setPanDirection = useBlurStore((s) => s.setPanDirection)

  const handleHoldOnDown = useCallback(() => setHoldOnOff(true), [setHoldOnOff])
  const handleHoldOnUp = useCallback(() => setHoldOnOff(false), [setHoldOnOff])
  const handleHoldFadeDown = useCallback(() => setHoldFadeOnOff(true), [setHoldFadeOnOff])
  const handleHoldFadeUp = useCallback(() => setHoldFadeOnOff(false), [setHoldFadeOnOff])

  const selectedGroupNames = selectedGroupIds.length > 0
    ? selectedGroupIds
        .map((id) => groups.find((g) => g.id === id)?.name)
        .filter(Boolean)
        .join(', ')
    : null

  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14 gap-3"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* Top Row */}
      <div className="flex gap-3 h-[180px] flex-shrink-0">
        <CustomGroupPanel groups={groups} selectedGroupIds={selectedGroupIds} />
        <CustomEffectPanel />
      </div>

      {/* Position Section */}
      <PositionSection />

      {/* Bottom: Effects */}
      <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
        <PanelHeader>
          Effects
          {selectedGroupNames && (
            <span className="ml-2 text-[10px] font-normal text-neutral-600">
              -- {selectedGroupNames}
            </span>
          )}
        </PanelHeader>

        <div className="flex flex-1 min-h-0">
          {/* Left: Toggles + Hold + Tilt/Pan */}
          <div className="w-[200px] flex-shrink-0 border-r border-neutral-800/50 p-3 flex flex-col gap-0.5">
            <SectionLabel>Toggles</SectionLabel>
            <FlatButton label="On / Off" active={masterOnOff} onClick={() => setMasterOnOff(!masterOnOff)} />
            <FlatButton label="Fade On / Off" active={fadeOnOff} onClick={() => setFadeOnOff(!fadeOnOff)} />

            <div className="my-2 border-t border-neutral-800/40" />

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

            <div className="my-2 border-t border-neutral-800/40" />

            <SectionLabel>Direction</SectionLabel>
            <DirectionControl label="Tilt" value={tiltDirection} onChange={setTiltDirection} />
            <DirectionControl label="Pan" value={panDirection} onChange={setPanDirection} />
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

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 px-1 py-1.5">
      {children}
    </span>
  )
}

/* ─── Flat Button (replaces toggle switch) ──── */

function FlatButton({
  label,
  active,
  onClick,
}: {
  label: string
  active: boolean
  onClick: () => void
}) {
  return (
    <button
      className={`flex items-center w-full px-2 py-2 rounded-lg transition-colors duration-150 cursor-pointer border ${
        active
          ? 'bg-neutral-800/50 border-neutral-700 text-white'
          : 'border-neutral-800/40 text-neutral-600 hover:text-neutral-400 hover:border-neutral-700'
      }`}
      onClick={onClick}
    >
      <span className="text-[11px] font-medium">{label}</span>
      <span className="ml-auto text-[10px] font-bold tracking-wider">
        {active ? 'ON' : 'OFF'}
      </span>
    </button>
  )
}

/* ─── Hold Button ────────────────────────────── */

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
      className={`flex items-center w-full px-2 py-2.5 rounded-lg border transition-all duration-150 select-none cursor-pointer ${
        active
          ? 'bg-neutral-800/60 border-neutral-600 text-white'
          : 'border-neutral-800/40 text-neutral-600 hover:text-neutral-400 hover:border-neutral-700'
      }`}
      onMouseDown={onMouseDown}
      onMouseUp={onMouseUp}
      onMouseLeave={onMouseLeave}
    >
      <span className="text-[11px] font-medium">{label}</span>
      <span className="ml-auto text-[10px] font-bold tracking-wider">
        {active ? 'ON' : 'OFF'}
      </span>
    </button>
  )
}

/* ─── Direction Control (< center >) ─────────── */

function DirectionControl({
  label,
  value,
  onChange,
}: {
  label: string
  value: number // -1 left, 0 center, 1 right
  onChange: (v: number) => void
}) {
  return (
    <div className="flex items-center gap-1 px-1 py-1.5">
      <span className="text-[10px] text-neutral-600 w-8 flex-shrink-0">{label}</span>
      <button
        className={`flex-1 h-7 rounded border text-[11px] font-bold transition-colors cursor-pointer ${
          value === -1
            ? 'bg-neutral-800/60 border-neutral-600 text-white'
            : 'border-neutral-800/40 text-neutral-600 hover:text-neutral-400 hover:border-neutral-700'
        }`}
        onClick={() => onChange(value === -1 ? 0 : -1)}
      >
        &lt;
      </button>
      <button
        className={`flex-1 h-7 rounded border text-[9px] font-medium transition-colors cursor-pointer ${
          value === 0
            ? 'bg-neutral-800/40 border-neutral-700 text-neutral-300'
            : 'border-neutral-800/30 text-neutral-700'
        }`}
        onClick={() => onChange(0)}
      >
        --
      </button>
      <button
        className={`flex-1 h-7 rounded border text-[11px] font-bold transition-colors cursor-pointer ${
          value === 1
            ? 'bg-neutral-800/60 border-neutral-600 text-white'
            : 'border-neutral-800/40 text-neutral-600 hover:text-neutral-400 hover:border-neutral-700'
        }`}
        onClick={() => onChange(value === 1 ? 0 : 1)}
      >
        &gt;
      </button>
    </div>
  )
}

/* ─── Custom Effect Panel (Control view) ─────── */

const TYPE_LABEL: Record<string, string> = {
  movement: 'Mvm', pattern: 'Pat', chase: 'Chase',
  strobe: 'Str', wave: 'Wav', custom: 'Cus',
}

function CustomEffectPanel() {
  const savedEffects = useEffectEditorStore((s) => s.savedEffects)

  if (savedEffects.length === 0) {
    return (
      <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
        <PanelHeader>Custom Effects</PanelHeader>
        <div className="flex-1 flex flex-col items-center justify-center gap-2 px-4">
          <motion.span
            className="text-[11px] text-neutral-500"
            animate={{ opacity: [0.3, 1, 0.3] }}
            transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
          >
            No custom effects yet
          </motion.span>
          <span className="text-[10px] text-neutral-700">
            Create one in the Effect panel
          </span>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
      <PanelHeader>Custom Effects</PanelHeader>
      <div className="flex-1 overflow-y-auto custom-scrollbar p-2 space-y-1">
        {savedEffects.map((fx) => (
          <div
            key={fx.id}
            className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg border border-neutral-800/30 hover:bg-neutral-800/20 transition-colors cursor-default"
          >
            <span className="text-[11px] font-medium text-neutral-300 truncate flex-1">
              {fx.name}
            </span>
            <span className="text-[9px] px-1.5 py-0.5 rounded bg-neutral-800/60 text-neutral-500 flex-shrink-0">
              {TYPE_LABEL[fx.type] ?? fx.type}
            </span>
            <span className="text-[9px] px-1.5 py-0.5 rounded bg-neutral-800/40 text-neutral-600 flex-shrink-0">
              {fx.frames.length}F
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}

/* ─── Position Section ─────────────────────────── */

function PositionSection() {
  const positions = useBlurStore((s) => s.positions)
  const activePosition = useBlurStore((s) => s.activePosition)
  const activatePosition = useBlurStore((s) => s.activatePosition)
  const addPosition = useBlurStore((s) => s.addPosition)
  const removePosition = useBlurStore((s) => s.removePosition)

  const [showAddInput, setShowAddInput] = useState(false)
  const [newPosName, setNewPosName] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  const handleAdd = useCallback(() => {
    if (newPosName.trim()) {
      addPosition(newPosName)
      setNewPosName('')
      setShowAddInput(false)
    }
  }, [newPosName, addPosition])

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleAdd()
    if (e.key === 'Escape') { setShowAddInput(false); setNewPosName('') }
  }, [handleAdd])

  return (
    <div className="rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex-shrink-0">
      <div className="h-8 flex items-center justify-between px-4 border-b border-neutral-800/50">
        <span className="text-[12px] font-semibold tracking-wide text-neutral-300">Position</span>
        <button
          className="text-[10px] text-neutral-600 hover:text-neutral-300 transition-colors cursor-pointer"
          onClick={() => { setShowAddInput(true); setTimeout(() => inputRef.current?.focus(), 50) }}
        >
          + Add
        </button>
      </div>

      <div className="p-3">
        {/* Add position input */}
        <AnimatePresence>
          {showAddInput && (
            <motion.div
              className="flex items-center gap-2 mb-3"
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
            >
              <input
                ref={inputRef}
                type="text"
                value={newPosName}
                onChange={(e) => setNewPosName(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Position name..."
                maxLength={20}
                className="flex-1 h-8 px-3 text-[11px] text-white bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors"
                onBlur={() => { if (!newPosName.trim()) { setShowAddInput(false) } }}
              />
              <motion.button
                className={`px-3 py-1.5 rounded-lg text-[10px] font-medium border transition-colors cursor-pointer ${
                  newPosName.trim() ? 'bg-white text-black border-transparent hover:bg-neutral-200' : 'border-neutral-800/40 text-neutral-600'
                }`}
                onClick={handleAdd}
                disabled={!newPosName.trim()}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                Save
              </motion.button>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Square position buttons */}
        {positions.length > 0 ? (
          <div className="grid grid-cols-5 gap-2">
            {positions.map((pos) => {
              const isActive = activePosition === pos.id
              return (
                <div key={pos.id} className="relative group/pos">
                  <motion.button
                    className={`w-full aspect-square rounded-lg border text-[10px] font-medium transition-all duration-300 cursor-pointer flex items-center justify-center px-1 text-center leading-tight ${
                      isActive
                        ? 'bg-white text-black border-white shadow-[0_0_12px_rgba(255,255,255,0.3)]'
                        : 'bg-neutral-900/30 border-neutral-800/50 text-neutral-500 hover:text-neutral-300 hover:border-neutral-700'
                    }`}
                    onClick={() => activatePosition(pos.id)}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    animate={isActive ? { scale: [1, 1.05, 1] } : {}}
                    transition={isActive ? { duration: 0.3 } : {}}
                  >
                    {pos.name}
                  </motion.button>
                  {/* Delete on hover */}
                  <button
                    className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-neutral-900 border border-neutral-700 flex items-center justify-center opacity-0 group-hover/pos:opacity-100 transition-opacity cursor-pointer"
                    onClick={(e) => { e.stopPropagation(); removePosition(pos.id) }}
                  >
                    <span className="text-[8px] text-neutral-500 hover:text-red-400">x</span>
                  </button>
                </div>
              )
            })}
          </div>
        ) : (
          <motion.p
            className="text-[10px] text-neutral-700 text-center py-2"
            animate={{ opacity: [0.3, 0.7, 0.3] }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            No positions saved
          </motion.p>
        )}
      </div>
    </div>
  )
}

/* ─── Custom Group Panel ─────────────────────── */

function CustomGroupPanel({
  groups,
  selectedGroupIds,
}: {
  groups: LaserGroup[]
  selectedGroupIds: string[]
}) {
  const toggleGroupSelection = useBlurStore((s) => s.toggleGroupSelection)

  if (groups.length === 0) {
    return (
      <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
        <PanelHeader>Custom Group</PanelHeader>
        <div className="flex-1 flex flex-col items-center justify-center gap-2 px-4">
          <motion.span
            className="text-[11px] text-neutral-500"
            animate={{ opacity: [0.3, 1, 0.3] }}
            transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
          >
            No groups -- please create one
          </motion.span>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
      <PanelHeader>Custom Group</PanelHeader>
      <div className="flex-1 overflow-y-auto custom-scrollbar p-2 space-y-1">
        {groups.map((group) => {
          const isSelected = selectedGroupIds.includes(group.id)
          return (
            <div
              key={group.id}
              className={`flex items-center gap-2 px-2.5 py-1.5 rounded-lg transition-colors cursor-pointer ${
                isSelected
                  ? 'bg-neutral-800/40 border border-neutral-700'
                  : 'border border-transparent hover:bg-neutral-800/20'
              }`}
              onClick={() => toggleGroupSelection(group.id)}
            >
              <div className={`w-3.5 h-3.5 rounded flex items-center justify-center flex-shrink-0 border transition-colors ${
                isSelected
                  ? 'bg-white border-white'
                  : 'border-neutral-700'
              }`}>
                {isSelected && (
                  <svg width="8" height="6" viewBox="0 0 10 8" fill="none">
                    <path d="M1 4L3.5 6.5L9 1" stroke="black" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                )}
              </div>
              <span className={`text-[11px] font-medium truncate ${
                isSelected ? 'text-white' : 'text-neutral-400'
              }`}>
                {group.name}
              </span>
              <span className="text-[9px] px-1.5 py-0.5 rounded bg-neutral-800/60 text-neutral-500 flex-shrink-0 ml-auto">
                {group.mode === 'fixture'
                  ? `${group.selectedFixtures.length}F`
                  : `${group.selectedBeams.length}B`}
              </span>
            </div>
          )
        })}
      </div>
    </div>
  )
}
