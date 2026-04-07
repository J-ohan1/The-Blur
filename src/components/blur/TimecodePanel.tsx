'use client'

import { useState, useCallback, useRef, useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  useBlurStore,
  EFFECTS,
  type SavedTimecode,
  type TimecodeCell,
  type TimecodeTrack,
} from '@/store/blur-store'

/* ─── Constants ───────────────────────────────── */

const COL_WIDTH = 72
const ROW_HEIGHT = 34
const GROUP_LABEL_WIDTH = 96
const DEFAULT_COLS = 24

const TOGGLE_ITEMS = [
  { type: 'toggle' as const, action: 'toggle-master', label: 'On / Off' },
  { type: 'toggle' as const, action: 'toggle-fade', label: 'Fade On / Off' },
  { type: 'toggle' as const, action: 'toggle-hold', label: 'Hold On / Off' },
  { type: 'toggle' as const, action: 'toggle-hold-fade', label: 'Hold Fade' },
]

interface DragPayload {
  type: TimecodeCell['type']
  action: string
  label: string
}

/* ─── Main Panel ──────────────────────────────── */

export function TimecodePanel() {
  const timecodeProjects = useBlurStore((s) => s.timecodeProjects)
  const activeTimecodeId = useBlurStore((s) => s.activeTimecodeId)
  const groups = useBlurStore((s) => s.groups)
  const [showNewDialog, setShowNewDialog] = useState(false)
  const [newName, setNewName] = useState('')
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null)

  const activeProject = useMemo(
    () => timecodeProjects.find((p) => p.id === activeTimecodeId),
    [timecodeProjects, activeTimecodeId]
  )

  const handleCreate = useCallback(() => {
    const name = newName.trim()
    if (name.length < 2) return
    useBlurStore.getState().createTimecode(name)
    setNewName('')
    setShowNewDialog(false)
  }, [newName])

  const handleDelete = useCallback(
    (id: string) => {
      if (deleteConfirmId === id) {
        useBlurStore.getState().deleteTimecode(id)
        setDeleteConfirmId(null)
      } else {
        setDeleteConfirmId(id)
        setTimeout(() => setDeleteConfirmId(null), 3000)
      }
    },
    [deleteConfirmId]
  )

  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14 gap-2"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* ── Top row: 2 frames ── */}
      <div className="flex gap-2 h-[38%] flex-shrink-0 min-h-0">
        {/* Frame 1: Controls + Saved list */}
        <div className="flex-1 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col min-w-0">
          <ControlsFrame
            activeProject={activeProject}
            showNewDialog={showNewDialog}
            newName={newName}
            onShowNew={() => setShowNewDialog(true)}
            onHideNew={() => { setShowNewDialog(false); setNewName('') }}
            onNameChange={setNewName}
            onCreate={handleCreate}
          />
          <SavedList
            projects={timecodeProjects}
            activeId={activeTimecodeId}
            deleteConfirmId={deleteConfirmId}
            onSelect={(id) => useBlurStore.getState().loadTimecode(id)}
            onDelete={handleDelete}
          />
        </div>

        {/* Frame 2: Sidebar */}
        <Sidebar
          positions={useBlurStore((s) => s.positions)}
          disabled={!activeProject}
        />
      </div>

      {/* ── Bottom frame: Timeline grid ── */}
      <div className="flex-1 min-h-0 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden">
        <TimelineGrid
          project={activeProject}
          groups={groups}
        />
      </div>
    </motion.div>
  )
}

/* ═══════════════════════════════════════════════════
   Frame 1: Controls + Saved List
   ═══════════════════════════════════════════════════ */

function ControlsFrame({
  activeProject,
  showNewDialog,
  newName,
  onShowNew,
  onHideNew,
  onNameChange,
  onCreate,
}: {
  activeProject: SavedTimecode | undefined
  showNewDialog: boolean
  newName: string
  onShowNew: () => void
  onHideNew: () => void
  onNameChange: (v: string) => void
  onCreate: () => void
}) {
  const timecodePlaying = useBlurStore((s) => s.timecodePlaying)
  const playTimecode = useBlurStore((s) => s.playTimecode)
  const stopTimecode = useBlurStore((s) => s.stopTimecode)
  const setTimecodeBpm = useBlurStore((s) => s.setTimecodeBpm)
  const setTimecodeName = useBlurStore((s) => s.setTimecodeName)

  const bpm = activeProject?.bpm ?? 120

  return (
    <>
      <div className="h-8 flex items-center justify-between px-3 border-b border-neutral-800/50 flex-shrink-0">
        <span className="text-[12px] font-semibold tracking-wide text-neutral-300">
          {activeProject ? 'Timecode' : 'Timecodes'}
        </span>
        {!showNewDialog && (
          <motion.button
            className="text-[9px] text-neutral-600 hover:text-neutral-300 transition-colors cursor-pointer"
            onClick={onShowNew}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            + New
          </motion.button>
        )}
      </div>

      {/* New timecode input */}
      <AnimatePresence>
        {showNewDialog && (
          <motion.div
            className="flex items-center gap-2 px-3 py-2 border-b border-neutral-800/40"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
          >
            <input
              type="text"
              value={newName}
              onChange={(e) => onNameChange(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') onCreate(); if (e.key === 'Escape') onHideNew() }}
              placeholder="Timecode name..."
              maxLength={30}
              autoFocus
              className="flex-1 h-7 px-2 text-[11px] text-white bg-neutral-900/60 border border-neutral-800 rounded-md outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors"
            />
            <button
              className={`px-2.5 py-1 rounded-md text-[10px] font-medium border transition-colors cursor-pointer ${
                newName.trim().length >= 2
                  ? 'bg-white text-black border-transparent hover:bg-neutral-200'
                  : 'border-neutral-800/40 text-neutral-600'
              }`}
              onClick={onCreate}
              disabled={newName.trim().length < 2}
            >
              Save
            </button>
            <button
              className="px-2 py-1 text-[10px] text-neutral-500 hover:text-white transition-colors cursor-pointer"
              onClick={onHideNew}
            >
              x
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Transport bar */}
      {activeProject && (
        <div className="flex items-center gap-3 px-3 py-2 border-b border-neutral-800/40 flex-shrink-0">
          {/* Play / Stop */}
          <div className="flex items-center gap-1">
            <motion.button
              className={`w-7 h-7 rounded-md flex items-center justify-center transition-colors cursor-pointer ${
                timecodePlaying
                  ? 'bg-white text-black'
                  : 'bg-neutral-800/50 border border-neutral-700 text-neutral-400 hover:text-white hover:border-neutral-500'
              }`}
              onClick={playTimecode}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {timecodePlaying ? (
                <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor">
                  <rect x="1" y="0" width="3" height="10" rx="0.5" />
                  <rect x="6" y="0" width="3" height="10" rx="0.5" />
                </svg>
              ) : (
                <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor">
                  <path d="M2 1L8 5L2 9V1Z" />
                </svg>
              )}
            </motion.button>
            <motion.button
              className="w-7 h-7 rounded-md flex items-center justify-center bg-neutral-800/30 border border-neutral-800/50 text-neutral-500 hover:text-white hover:border-neutral-600 transition-colors cursor-pointer"
              onClick={stopTimecode}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor">
                <rect x="1" y="1" width="8" height="8" rx="1" />
              </svg>
            </motion.button>
          </div>

          {/* BPM */}
          <div className="flex items-center gap-1.5">
            <span className="text-[9px] text-neutral-600 font-medium">BPM</span>
            <input
              type="number"
              value={bpm}
              onChange={(e) => setTimecodeBpm(parseInt(e.target.value) || 120)}
              min={20}
              max={999}
              className="w-14 h-7 px-2 text-[11px] text-white bg-neutral-900/60 border border-neutral-800 rounded-md outline-none text-center focus:border-neutral-600 transition-colors [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
            />
          </div>

          {/* Name edit */}
          <input
            type="text"
            value={activeProject.name}
            onChange={(e) => setTimecodeName(e.target.value)}
            maxLength={30}
            className="flex-1 h-7 px-2 text-[11px] text-neutral-300 bg-neutral-900/40 border border-transparent hover:border-neutral-800 focus:border-neutral-600 rounded-md outline-none transition-colors min-w-0 truncate"
          />

          {/* Beat info */}
          <span className="text-[9px] text-neutral-700 flex-shrink-0 font-mono">
            {(60000 / bpm).toFixed(0)}ms/beat
          </span>
        </div>
      )}

      {/* Spacer */}
      <div className="flex-1 min-h-0" />
    </>
  )
}

/* ─── Saved List ──────────────────────────────── */

function SavedList({
  projects,
  activeId,
  deleteConfirmId,
  onSelect,
  onDelete,
}: {
  projects: SavedTimecode[]
  activeId: string | null
  deleteConfirmId: string | null
  onSelect: (id: string) => void
  onDelete: (id: string) => void
}) {
  if (projects.length === 0) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center gap-2 px-4">
        <span className="text-[11px] text-neutral-600">
          No timecodes created
        </span>
        <span className="text-[10px] text-neutral-700">
          Click + New to create one
        </span>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto custom-scrollbar p-2 space-y-1">
      {projects.map((p) => {
        const isActive = p.id === activeId
        const isDeleting = deleteConfirmId === p.id
        // Count entries
        let entryCount = 0
        for (const track of p.tracks) {
          entryCount += Object.keys(track.cells).length
        }

        return (
          <div
            key={p.id}
            className={`rounded-lg px-3 py-2 cursor-pointer transition-colors ${
              isActive
                ? 'bg-neutral-800/40 border border-neutral-700'
                : 'border border-transparent hover:bg-neutral-800/20'
            } ${isDeleting ? 'border-red-900/50' : ''}`}
            onClick={() => onSelect(p.id)}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 min-w-0">
                {isActive && (
                  <div className="w-1.5 h-1.5 rounded-full bg-white flex-shrink-0" />
                )}
                <span className={`text-[11px] font-medium truncate ${isActive ? 'text-white' : 'text-neutral-400'}`}>
                  {p.name}
                </span>
              </div>
              <div className="flex items-center gap-1.5 flex-shrink-0 ml-2">
                <span className="text-[9px] text-neutral-600">{p.bpm} BPM</span>
                <span className="text-[9px] text-neutral-700">{entryCount}e</span>
                <button
                  className={`text-[9px] px-1.5 py-0.5 rounded transition-colors cursor-pointer ${
                    isDeleting
                      ? 'text-red-400 bg-red-900/20'
                      : 'text-neutral-700 hover:text-red-400'
                  }`}
                  onClick={(e) => { e.stopPropagation(); onDelete(p.id) }}
                >
                  {isDeleting ? '?' : 'x'}
                </button>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}

/* ═══════════════════════════════════════════════════
   Frame 2: Sidebar (Drag sources)
   ═══════════════════════════════════════════════════ */

function Sidebar({
  positions,
  disabled,
}: {
  positions: { id: string; name: string }[]
  disabled: boolean
}) {
  const [expanded, setExpanded] = useState<Set<string>>(
    new Set(['effects', 'toggles', 'positions', 'special'])
  )

  const toggleSection = useCallback((key: string) => {
    setExpanded((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }, [])

  return (
    <div className="w-[220px] flex-shrink-0 rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden flex flex-col">
      <div className="h-8 flex items-center px-3 border-b border-neutral-800/50 flex-shrink-0">
        <span className="text-[12px] font-semibold tracking-wide text-neutral-300">Items</span>
      </div>
      <div className="flex-1 overflow-y-auto custom-scrollbar p-2 space-y-1">
        {disabled && (
          <p className="text-[10px] text-neutral-700 text-center py-4">
            Select a timecode first
          </p>
        )}

        {/* Effects */}
        <SidebarSection
          title="Effects"
          count={EFFECTS.length}
          expanded={expanded.has('effects')}
          disabled={disabled}
          onToggle={() => toggleSection('effects')}
        >
          {EFFECTS.map((fx) => (
            <DragItem
              key={fx.id}
              type="effect"
              action={`effect-${fx.id}`}
              label={fx.name}
              colorClass="text-neutral-400 hover:text-neutral-200"
              disabled={disabled}
            />
          ))}
        </SidebarSection>

        {/* Toggles */}
        <SidebarSection
          title="Toggles"
          count={TOGGLE_ITEMS.length}
          expanded={expanded.has('toggles')}
          disabled={disabled}
          onToggle={() => toggleSection('toggles')}
        >
          {TOGGLE_ITEMS.map((item) => (
            <DragItem
              key={item.action}
              type="toggle"
              action={item.action}
              label={item.label}
              colorClass="text-neutral-500 hover:text-neutral-200"
              disabled={disabled}
            />
          ))}
        </SidebarSection>

        {/* Positions */}
        <SidebarSection
          title="Positions"
          count={positions.length}
          expanded={expanded.has('positions')}
          disabled={disabled}
          onToggle={() => toggleSection('positions')}
        >
          {positions.length === 0 ? (
            <span className="text-[10px] text-neutral-700 px-1 py-1 block">
              No positions saved
            </span>
          ) : (
            positions.map((pos) => (
              <DragItem
                key={pos.id}
                type="position"
                action={`position-${pos.id}`}
                label={pos.name}
                colorClass="text-neutral-300 hover:text-neutral-100"
                disabled={disabled}
              />
            ))
          )}
        </SidebarSection>

        {/* Special: Wait */}
        <SidebarSection
          title="Special"
          count={1}
          expanded={expanded.has('special')}
          disabled={disabled}
          onToggle={() => toggleSection('special')}
        >
          <DragItem
            type="wait"
            action="wait"
            label="Wait (1 beat)"
            colorClass="text-neutral-600 hover:text-neutral-300"
            disabled={disabled}
          />
        </SidebarSection>
      </div>
    </div>
  )
}

function SidebarSection({
  title,
  count,
  expanded,
  disabled,
  onToggle,
  children,
}: {
  title: string
  count: number
  expanded: boolean
  disabled: boolean
  onToggle: () => void
  children: React.ReactNode
}) {
  return (
    <div>
      <button
        className="w-full flex items-center justify-between px-2 py-1.5 rounded-md hover:bg-neutral-800/20 transition-colors cursor-pointer"
        onClick={onToggle}
      >
        <div className="flex items-center gap-1.5">
          <span className="text-[8px] text-neutral-600">{expanded ? '▾' : '▸'}</span>
          <span className="text-[10px] font-semibold uppercase tracking-wider text-neutral-500">
            {title}
          </span>
        </div>
        <span className="text-[9px] text-neutral-700">{count}</span>
      </button>
      <AnimatePresence>
        {expanded && (
          <motion.div
            className="ml-3 mt-0.5 space-y-0.5 max-h-[180px] overflow-y-auto custom-scrollbar"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.15 }}
          >
            {children}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

function DragItem({
  type,
  action,
  label,
  colorClass,
  disabled,
}: {
  type: TimecodeCell['type']
  action: string
  label: string
  colorClass: string
  disabled: boolean
}) {
  const handleDragStart = useCallback(
    (e: React.DragEvent) => {
      if (disabled) { e.preventDefault(); return }
      const payload: DragPayload = { type, action, label }
      e.dataTransfer.setData('application/json', JSON.stringify(payload))
      e.dataTransfer.effectAllowed = 'copy'
    },
    [disabled, type, action, label]
  )

  return (
    <div
      draggable
      onDragStart={handleDragStart}
      className={`px-2 py-1 rounded text-[10px] font-medium transition-colors cursor-grab active:cursor-grabbing select-none ${colorClass} ${
        disabled ? 'opacity-30 cursor-not-allowed' : 'hover:bg-neutral-800/30'
      }`}
    >
      {label}
    </div>
  )
}

/* ═══════════════════════════════════════════════════
   Frame 3: Timeline Grid
   ═══════════════════════════════════════════════════ */

function TimelineGrid({
  project,
  groups,
}: {
  project: SavedTimecode | undefined
  groups: { id: string; name: string }[]
}) {
  const timecodePlaying = useBlurStore((s) => s.timecodePlaying)
  const timecodeCurrentStep = useBlurStore((s) => s.timecodeCurrentStep)
  const addTimecodeEntry = useBlurStore((s) => s.addTimecodeEntry)
  const removeTimecodeEntry = useBlurStore((s) => s.removeTimecodeEntry)
  const cycleWaitMultiplier = useBlurStore((s) => s.cycleWaitMultiplier)

  const scrollRef = useRef<HTMLDivElement>(null)

  // Calculate columns
  const displayCols = useMemo(() => {
    if (!project) return DEFAULT_COLS
    let maxCol = 0
    for (const track of project.tracks) {
      const cols = Object.keys(track.cells).map(Number)
      if (cols.length > 0) maxCol = Math.max(maxCol, ...cols)
    }
    return Math.max(DEFAULT_COLS, maxCol + 4)
  }, [project])

  if (!project) {
    return (
      <div className="h-full flex flex-col items-center justify-center gap-3">
        <div className="w-16 h-16 rounded-2xl bg-neutral-900/50 border border-neutral-800/50 flex items-center justify-center">
          <span className="text-2xl text-neutral-800 font-bold">TC</span>
        </div>
        <div className="text-center">
          <p className="text-[13px] font-medium text-neutral-500">No timecode selected</p>
          <p className="text-[11px] text-neutral-700 mt-1">
            Create or select a timecode to start editing
          </p>
        </div>
      </div>
    )
  }

  if (project.tracks.length === 0) {
    return (
      <div className="h-full flex flex-col items-center justify-center gap-2">
        <p className="text-[12px] text-neutral-600">No groups for this timecode</p>
        <p className="text-[10px] text-neutral-700">Groups are captured when creating a timecode</p>
      </div>
    )
  }

  const handleDrop = (e: React.DragEvent, groupId: string, col: number) => {
    e.preventDefault()
    try {
      const raw = e.dataTransfer.getData('application/json')
      if (!raw) return
      const payload: DragPayload = JSON.parse(raw)
      addTimecodeEntry(groupId, col, {
        type: payload.type,
        action: payload.action,
        label: payload.label,
      })
    } catch {
      // Ignore invalid drag data
    }
  }

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    e.dataTransfer.dropEffect = 'copy'
  }

  return (
    <div className="h-full flex flex-col">
      {/* Grid header bar */}
      <div className="h-7 flex items-center px-3 border-b border-neutral-800/50 flex-shrink-0 justify-between">
        <span className="text-[12px] font-semibold tracking-wide text-neutral-300">
          Timeline
        </span>
        <div className="flex items-center gap-3">
          <span className="text-[9px] text-neutral-600">
            {project.tracks.length} tracks &middot; {displayCols} steps
          </span>
          {timecodePlaying && (
            <motion.div
              className="flex items-center gap-1"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
            >
              <motion.div
                className="w-1.5 h-1.5 rounded-full bg-white"
                animate={{ opacity: [1, 0.3, 1] }}
                transition={{ duration: 0.8, repeat: Infinity }}
              />
              <span className="text-[9px] text-neutral-300 font-mono">
                Step {timecodeCurrentStep + 1}
              </span>
            </motion.div>
          )}
        </div>
      </div>

      {/* Scrollable grid area */}
      <div ref={scrollRef} className="flex-1 overflow-auto custom-scrollbar relative">
        {/* Column headers */}
        <div className="flex sticky top-0 z-10 bg-neutral-950">
          <div
            className="flex-shrink-0 border-b border-r border-neutral-800/40 flex items-center justify-center"
            style={{ width: GROUP_LABEL_WIDTH }}
          >
            <span className="text-[8px] text-neutral-600 uppercase tracking-widest">Group</span>
          </div>
          {Array.from({ length: displayCols }, (_, i) => (
            <div
              key={i}
              className={`flex-shrink-0 border-b border-r border-neutral-800/20 flex items-center justify-center ${
                timecodePlaying && timecodeCurrentStep === i
                  ? 'bg-neutral-800/40'
                  : 'bg-neutral-950/90'
              }`}
              style={{ width: COL_WIDTH }}
            >
              <span className={`text-[9px] font-mono ${
                timecodePlaying && timecodeCurrentStep === i
                  ? 'text-white font-bold'
                  : 'text-neutral-700'
              }`}>
                {i + 1}
              </span>
            </div>
          ))}
        </div>

        {/* Tracks */}
        {project.tracks.map((track) => (
          <div key={track.groupId} className="flex">
            {/* Group label */}
            <div
              className={`flex-shrink-0 border-b border-r border-neutral-800/40 flex items-center px-2 ${
                timecodePlaying ? 'bg-neutral-950/80' : ''
              }`}
              style={{ width: GROUP_LABEL_WIDTH, height: ROW_HEIGHT }}
            >
              <span className="text-[10px] font-medium text-neutral-400 truncate">
                {track.groupName}
              </span>
            </div>

            {/* Cells */}
            {Array.from({ length: displayCols }, (_, i) => {
              const cell = track.cells[i]
              const isPlayhead = timecodePlaying && timecodeCurrentStep === i

              return (
                <div
                  key={i}
                  className={`flex-shrink-0 border-b border-r border-neutral-800/15 relative transition-colors ${
                    isPlayhead ? 'bg-neutral-800/20' : 'hover:bg-neutral-900/40'
                  }`}
                  style={{ width: COL_WIDTH, height: ROW_HEIGHT }}
                  onDragOver={handleDragOver}
                  onDrop={(e) => handleDrop(e, track.groupId, i)}
                >
                  {/* Playhead indicator */}
                  {isPlayhead && (
                    <motion.div
                      className="absolute left-0 right-0 top-0 h-[2px] bg-white z-20"
                      layoutId="step-indicator"
                      transition={{ duration: 0 }}
                    />
                  )}

                  {/* Cell content */}
                  {cell && (
                    <CellBadge
                      cell={cell}
                      onRemove={() => removeTimecodeEntry(track.groupId, i)}
                      onCycleWait={
                        cell.type === 'wait'
                          ? () => cycleWaitMultiplier(track.groupId, i)
                          : undefined
                      }
                      isPlayhead={isPlayhead}
                    />
                  )}
                </div>
              )
            })}
          </div>
        ))}
      </div>
    </div>
  )
}

/* ─── Cell Badge ──────────────────────────────── */

function CellBadge({
  cell,
  onRemove,
  onCycleWait,
  isPlayhead,
}: {
  cell: TimecodeCell
  onRemove: () => void
  onCycleWait?: () => void
  isPlayhead: boolean
}) {
  const [hovered, setHovered] = useState(false)

  const typeColors: Record<string, string> = {
    effect: 'bg-neutral-800/50 text-neutral-300 border-neutral-700/60',
    toggle: 'bg-neutral-800/40 text-neutral-400 border-neutral-800/50',
    position: 'bg-neutral-800/60 text-neutral-200 border-neutral-700/70',
    wait: 'bg-neutral-900/40 text-neutral-600 border-dashed border-neutral-700/40',
  }

  const activeColors: Record<string, string> = {
    effect: 'bg-white/20 text-white border-white/40 shadow-[0_0_8px_rgba(255,255,255,0.15)]',
    toggle: 'bg-white/15 text-white border-white/30 shadow-[0_0_6px_rgba(255,255,255,0.1)]',
    position: 'bg-white/25 text-white border-white/50 shadow-[0_0_10px_rgba(255,255,255,0.2)]',
    wait: 'bg-white/10 text-neutral-400 border-dashed border-white/20',
  }

  const baseColor = isPlayhead
    ? activeColors[cell.type] ?? activeColors.effect
    : typeColors[cell.type] ?? typeColors.effect

  return (
    <div
      className={`absolute inset-[2px] rounded flex items-center gap-0.5 px-1.5 border overflow-hidden transition-colors cursor-pointer ${baseColor}`}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onClick={onCycleWait}
    >
      <span className="text-[9px] font-medium truncate flex-1 leading-tight">
        {cell.type === 'wait'
          ? `Wait ${cell.waitMultiplier}x`
          : cell.label}
      </span>

      {/* Remove button */}
      <AnimatePresence>
        {hovered && (
          <motion.button
            className="w-3.5 h-3.5 rounded-full flex items-center justify-center bg-neutral-900/80 hover:bg-red-900/60 text-neutral-500 hover:text-red-300 flex-shrink-0 transition-colors cursor-pointer"
            initial={{ opacity: 0, scale: 0.5 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.5 }}
            onClick={(e) => { e.stopPropagation(); onRemove() }}
          >
            <span className="text-[7px] leading-none">&times;</span>
          </motion.button>
        )}
      </AnimatePresence>
    </div>
  )
}
