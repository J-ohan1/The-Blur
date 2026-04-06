'use client'

import { useState, useCallback, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  useBlurStore,
  BEAMS_PER_FIXTURE,
  type LaserGroup,
} from '@/store/blur-store'
import { Plus, Zap, Target, Trash2, Pencil, X } from 'lucide-react'

const FIXTURE_COUNT = 24 // How many lasers to show in the selector

export function GroupPanel() {
  const {
    groups,
    groupModalOpen,
    groupMode,
    selectedFixtures,
    selectedBeams,
    groupNameInput,
    deleteConfirmId,
    openGroupModal,
    closeGroupModal,
    setGroupMode,
    toggleFixture,
    toggleBeam,
    setGroupNameInput,
    saveGroup,
    deleteGroup,
    confirmDeleteGroup,
    cancelDeleteGroup,
  } = useBlurStore()

  const [contextMenu, setContextMenu] = useState<{ x: number; y: number; groupId: string } | null>(null)
  const panelRef = useRef<HTMLDivElement>(null)

  const handleContextMenu = useCallback((e: React.MouseEvent, groupId: string) => {
    e.preventDefault()
    setContextMenu({ x: e.clientX, y: e.clientY, groupId })
  }, [])

  const closeContextMenu = useCallback(() => setContextMenu(null), [])

  const handleEdit = useCallback((groupId: string) => {
    closeContextMenu()
    openGroupModal(groupId)
  }, [closeContextMenu, openGroupModal])

  const handleDelete = useCallback((groupId: string) => {
    closeContextMenu()
    confirmDeleteGroup(groupId)
  }, [closeContextMenu, confirmDeleteGroup])

  // Close context menu on click outside
  const handleClick = useCallback(() => {
    if (contextMenu) closeContextMenu()
  }, [contextMenu, closeContextMenu])

  return (
    <motion.div
      ref={panelRef}
      className="h-full w-full flex flex-col p-4 pt-14"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
      onClick={handleClick}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-sm font-semibold text-white">Groups</h2>
          <p className="text-[11px] text-neutral-600 mt-0.5">
            {groups.length} group{groups.length !== 1 ? 's' : ''} created
          </p>
        </div>
        <motion.button
          className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 border border-neutral-800 text-[12px] font-medium text-neutral-300 hover:bg-white/10 hover:text-white hover:border-neutral-600 transition-all duration-200 cursor-pointer"
          onClick={() => openGroupModal()}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          <Plus className="w-3.5 h-3.5" />
          Add Group
        </motion.button>
      </div>

      {/* Content: List or Modal */}
      <AnimatePresence mode="wait">
        {groupModalOpen ? (
          <GroupCreator key="creator" />
        ) : (
          <GroupList
            key="list"
            groups={groups}
            deleteConfirmId={deleteConfirmId}
            onContextMenu={handleContextMenu}
            onDelete={deleteGroup}
            onCancelDelete={cancelDeleteGroup}
          />
        )}
      </AnimatePresence>

      {/* Context Menu */}
      <AnimatePresence>
        {contextMenu && (
          <ContextMenu
            x={contextMenu.x}
            y={contextMenu.y}
            onEdit={() => handleEdit(contextMenu.groupId)}
            onDelete={() => handleDelete(contextMenu.groupId)}
            onClose={closeContextMenu}
          />
        )}
      </AnimatePresence>
    </motion.div>
  )
}

/* ─── Group List ─────────────────────────────────── */

function GroupList({
  groups,
  deleteConfirmId,
  onContextMenu,
  onDelete,
  onCancelDelete,
}: {
  groups: LaserGroup[]
  deleteConfirmId: string | null
  onContextMenu: (e: React.MouseEvent, id: string) => void
  onDelete: (id: string) => void
  onCancelDelete: () => void
}) {
  if (groups.length === 0) {
    return (
      <motion.div
        className="flex-1 flex flex-col items-center justify-center gap-4"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
      >
        <div className="w-16 h-16 rounded-2xl bg-neutral-900/50 border border-neutral-800/50 flex items-center justify-center">
          <Zap className="w-7 h-7 text-neutral-700" />
        </div>
        <div className="text-center">
          <p className="text-[13px] font-medium text-neutral-400">No groups created</p>
          <p className="text-[11px] text-neutral-700 mt-1">
            Create your first laser group to get started
          </p>
        </div>
      </motion.div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto custom-scrollbar space-y-2 pr-1">
      {groups.map((group, index) => {
        const isDeleting = deleteConfirmId === group.id
        const count = group.mode === 'fixture'
          ? group.selectedFixtures.length
          : group.selectedBeams.length

        return (
          <motion.div
            key={group.id}
            className="relative rounded-xl border border-neutral-800/70 bg-neutral-950/50 p-4"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ duration: 0.2, delay: index * 0.03 }}
            onContextMenu={(e) => onContextMenu(e, group.id)}
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[13px] font-semibold text-white">{group.name}</p>
                <div className="flex items-center gap-2 mt-1">
                  <span className={`text-[10px] font-medium px-2 py-0.5 rounded-md ${
                    group.mode === 'fixture'
                      ? 'bg-blue-500/10 text-blue-400 border border-blue-500/20'
                      : 'bg-purple-500/10 text-purple-400 border border-purple-500/20'
                  }`}>
                    {group.mode === 'fixture' ? 'Fixture' : 'Individual'}
                  </span>
                  <span className="text-[10px] text-neutral-600">
                    {count} {group.mode === 'fixture' ? 'fixture' : 'beam'}{count !== 1 ? 's' : ''}
                  </span>
                </div>
              </div>

              {/* Selection preview pills */}
              <div className="flex items-center gap-1 max-w-[200px] flex-wrap justify-end">
                {(group.mode === 'fixture' ? group.selectedFixtures.map(String) : group.selectedBeams.slice(0, 8)).map((item) => (
                  <span key={item} className="text-[9px] px-1.5 py-0.5 rounded bg-neutral-800/60 text-neutral-400">
                    {item}
                  </span>
                ))}
                {count > 8 && <span className="text-[9px] text-neutral-600">+{count - 8}</span>}
              </div>
            </div>

            {/* Delete confirmation */}
            <AnimatePresence>
              {isDeleting && (
                <motion.div
                  className="mt-3 pt-3 border-t border-neutral-800/50 flex items-center justify-between"
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                >
                  <span className="text-[11px] text-red-400">Delete this group?</span>
                  <div className="flex items-center gap-2">
                    <button
                      className="px-3 py-1 text-[11px] font-medium text-neutral-400 hover:text-white rounded-md hover:bg-neutral-800/40 transition-colors cursor-pointer"
                      onClick={(e) => { e.stopPropagation(); onCancelDelete() }}
                    >
                      Cancel
                    </button>
                    <button
                      className="px-3 py-1 text-[11px] font-medium text-red-400 bg-red-500/10 border border-red-500/20 rounded-md hover:bg-red-500/20 transition-colors cursor-pointer"
                      onClick={(e) => { e.stopPropagation(); onDelete(group.id) }}
                    >
                      Delete
                    </button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        )
      })}
    </div>
  )
}

/* ─── Context Menu ───────────────────────────────── */

function ContextMenu({
  x, y, onEdit, onDelete, onClose,
}: {
  x: number; y: number
  onEdit: () => void
  onDelete: () => void
  onClose: () => void
}) {
  return (
    <>
      {/* Backdrop */}
      <motion.div
        className="fixed inset-0 z-[90]"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      />
      {/* Menu */}
      <motion.div
        className="fixed z-[100] w-40 rounded-lg border border-neutral-800 bg-neutral-950/95 backdrop-blur-md p-1 shadow-xl"
        style={{ left: x, top: y }}
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        transition={{ duration: 0.12 }}
      >
        <button
          className="flex items-center gap-2 w-full px-3 py-2 text-[12px] text-neutral-300 hover:bg-neutral-800/50 hover:text-white rounded-md transition-colors cursor-pointer"
          onClick={(e) => { e.stopPropagation(); onEdit() }}
        >
          <Pencil className="w-3.5 h-3.5 text-neutral-500" />
          Edit
        </button>
        <button
          className="flex items-center gap-2 w-full px-3 py-2 text-[12px] text-red-400 hover:bg-red-500/10 rounded-md transition-colors cursor-pointer"
          onClick={(e) => { e.stopPropagation(); onDelete() }}
        >
          <Trash2 className="w-3.5 h-3.5" />
          Delete
        </button>
      </motion.div>
    </>
  )
}

/* ─── Group Creator / Editor ─────────────────────── */

function GroupCreator() {
  const {
    editingGroupId,
    groupMode,
    selectedFixtures,
    selectedBeams,
    groupNameInput,
    openGroupModal,
    closeGroupModal,
    setGroupMode,
    toggleFixture,
    toggleBeam,
    setGroupNameInput,
    saveGroup,
  } = useBlurStore()

  const isEditing = !!editingGroupId
  const totalSelected = groupMode === 'fixture' ? selectedFixtures.length : selectedBeams.length

  return (
    <motion.div
      className="flex-1 flex flex-col overflow-hidden"
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      transition={{ duration: 0.25 }}
    >
      {/* Back button */}
      <div className="flex items-center gap-3 mb-4">
        <button
          className="flex items-center gap-1.5 text-[12px] text-neutral-500 hover:text-white transition-colors cursor-pointer"
          onClick={closeGroupModal}
        >
          <X className="w-3.5 h-3.5" />
          Back
        </button>
        <span className="text-[13px] font-semibold text-white">
          {isEditing ? 'Edit Group' : 'Create Group'}
        </span>
      </div>

      {/* Name Input */}
      <div className="mb-4">
        <label className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 block mb-1.5">
          Group Name <span className="text-red-500">*</span>
        </label>
        <input
          type="text"
          value={groupNameInput}
          onChange={(e) => setGroupNameInput(e.target.value)}
          placeholder="Enter group name..."
          maxLength={30}
          className="w-full h-9 px-3 text-[12px] text-white bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors"
        />
        <p className="text-[10px] text-neutral-700 mt-1">
          No abusive or explicit content
        </p>
      </div>

      {/* Mode Selector: Fixture / Individual */}
      <div className="flex items-center gap-2 mb-4">
        <span className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 mr-2">Mode</span>
        <button
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[11px] font-medium border transition-colors cursor-pointer ${
            groupMode === 'fixture'
              ? 'bg-blue-500/15 border-blue-500/30 text-blue-400'
              : 'bg-neutral-900/30 border-neutral-800 text-neutral-500 hover:text-neutral-300'
          }`}
          onClick={() => setGroupMode('fixture')}
        >
          <Zap className="w-3 h-3" />
          Fixture
        </button>
        <button
          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[11px] font-medium border transition-colors cursor-pointer ${
            groupMode === 'individual'
              ? 'bg-purple-500/15 border-purple-500/30 text-purple-400'
              : 'bg-neutral-900/30 border-neutral-800 text-neutral-500 hover:text-neutral-300'
          }`}
          onClick={() => setGroupMode('individual')}
        >
          <Target className="w-3 h-3" />
          Individual
        </button>
      </div>

      {/* Laser Selector */}
      <div className="flex-1 overflow-y-auto custom-scrollbar mb-4">
        <div className="flex items-center justify-between mb-2">
          <span className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600">
            Select Lasers
          </span>
          <span className="text-[10px] text-neutral-500">
            {totalSelected} selected
          </span>
        </div>

        {groupMode === 'fixture' ? (
          <FixtureSelector selected={selectedFixtures} onToggle={toggleFixture} />
        ) : (
          <IndividualSelector selected={selectedBeams} onToggle={toggleBeam} />
        )}
      </div>

      {/* Save Button */}
      <button
        className="w-full py-2.5 rounded-lg bg-white text-black text-[12px] font-semibold hover:bg-neutral-200 transition-colors cursor-pointer"
        onClick={saveGroup}
      >
        {isEditing ? 'Save Changes' : 'Create Group'}
      </button>
    </motion.div>
  )
}

/* ─── Fixture Selector ───────────────────────────── */

function FixtureSelector({
  selected,
  onToggle,
}: {
  selected: number[]
  onToggle: (num: number) => void
}) {
  return (
    <div className="grid grid-cols-8 gap-1.5">
      {Array.from({ length: FIXTURE_COUNT }, (_, i) => i + 1).map((num) => {
        const isSelected = selected.includes(num)
        return (
          <button
            key={num}
            className={`h-10 rounded-lg border text-[12px] font-semibold transition-colors cursor-pointer ${
              isSelected
                ? 'bg-blue-500/20 border-blue-500/40 text-blue-300'
                : 'bg-neutral-900/30 border-neutral-800/50 text-neutral-600 hover:border-neutral-700 hover:text-neutral-400'
            }`}
            onClick={() => onToggle(num)}
          >
            {num}
          </button>
        )
      })}
    </div>
  )
}

/* ─── Individual Selector (expandable fixtures) ──── */

function IndividualSelector({
  selected,
  onToggle,
}: {
  selected: string[]
  onToggle: (key: string) => void
}) {
  const [expandedFixture, setExpandedFixture] = useState<number | null>(null)

  return (
    <div className="space-y-2">
      {/* Fixture rows */}
      {Array.from({ length: FIXTURE_COUNT }, (_, i) => i + 1).map((fixtureNum) => {
        const beamKeys = Array.from(
          { length: BEAMS_PER_FIXTURE },
          (_, b) => `${fixtureNum}-${b + 1}`
        )
        const selectedCount = beamKeys.filter((k) => selected.includes(k)).length
        const isExpanded = expandedFixture === fixtureNum
        const allSelected = selectedCount === BEAMS_PER_FIXTURE

        return (
          <div key={fixtureNum} className="rounded-lg border border-neutral-800/50 overflow-hidden">
            {/* Fixture header */}
            <button
              className={`flex items-center gap-2 w-full px-3 py-2 text-left transition-colors cursor-pointer ${
                isExpanded ? 'bg-neutral-800/30' : 'hover:bg-neutral-900/30'
              }`}
              onClick={() => setExpandedFixture(isExpanded ? null : fixtureNum)}
            >
              <span className="text-[12px] font-semibold text-neutral-300 w-6">F{fixtureNum}</span>
              <span className="text-[10px] text-neutral-600">
                {selectedCount > 0 ? `${selectedCount}/${BEAMS_PER_FIXTURE} beams` : `${BEAMS_PER_FIXTURE} beams`}
              </span>

              {/* Select all */}
              <button
                className="ml-auto text-[10px] font-medium px-2 py-0.5 rounded-md transition-colors cursor-pointer"
                onClick={(e) => {
                  e.stopPropagation()
                  if (allSelected) {
                    beamKeys.forEach((k) => { if (selected.includes(k)) onToggle(k) })
                  } else {
                    beamKeys.forEach((k) => { if (!selected.includes(k)) onToggle(k) })
                  }
                }}
                style={{
                  color: allSelected ? '#f87171' : '#4ade80',
                  background: allSelected ? 'rgba(239,68,68,0.1)' : 'rgba(34,197,94,0.1)',
                }}
              >
                {allSelected ? 'Deselect All' : 'Select All'}
              </button>
            </button>

            {/* Expanded beams */}
            <AnimatePresence>
              {isExpanded && (
                <motion.div
                  className="px-3 pb-2 pt-1 border-t border-neutral-800/30"
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.15 }}
                >
                  <div className="grid grid-cols-8 gap-1">
                    {beamKeys.map((key) => {
                      const beamNum = parseInt(key.split('-')[1])
                      const isSelected = selected.includes(key)
                      return (
                        <button
                          key={key}
                          className={`h-8 rounded border text-[10px] font-medium transition-colors cursor-pointer ${
                            isSelected
                              ? 'bg-purple-500/20 border-purple-500/40 text-purple-300'
                              : 'bg-neutral-900/30 border-neutral-800/30 text-neutral-600 hover:border-neutral-700 hover:text-neutral-400'
                          }`}
                          onClick={() => onToggle(key)}
                        >
                          B{beamNum}
                        </button>
                      )
                    })}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )
      })}
    </div>
  )
}
