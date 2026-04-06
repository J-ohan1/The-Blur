'use client'

import { useState, useCallback, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useEffectEditorStore, type SavedCustomEffect } from '@/store/effect-editor-store'
import { useBlurStore } from '@/store/blur-store'
import { EFFECT_PRESETS } from '@/lib/effect-presets'
import { EFFECTS_CATEGORIES } from './effects-categories'

/* ─── Type labels ───────────────────────────────── */

const TYPE_BADGE: Record<string, string> = {
  movement: 'Movement',
  pattern: 'Pattern',
  chase: 'Chase',
  strobe: 'Strobe',
  wave: 'Wave',
  custom: 'Custom',
}

/* ─── Main Panel ────────────────────────────────── */

export function EffectPanel() {
  const effectPanelView = useEffectEditorStore((s) => s.effectPanelView)

  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      <AnimatePresence mode="wait">
        {effectPanelView === 'list' ? <EffectList key="list" /> : <EffectEditor key="editor" />}
      </AnimatePresence>

      {/* Modals */}
      <SaveDialog />
      <PresetBrowser />
    </motion.div>
  )
}

/* ─── Effect List (front page) ──────────────────── */

function EffectList() {
  const savedEffects = useEffectEditorStore((s) => s.savedEffects)
  const openEditor = useEffectEditorStore((s) => s.openEditor)
  const openPresetBrowser = useEffectEditorStore((s) => s.openPresetBrowser)
  const deleteSavedEffect = useEffectEditorStore((s) => s.deleteSavedEffect)
  const addToast = useBlurStore((s) => s.addToast)

  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null)

  const handleDelete = useCallback((id: string, name: string) => {
    if (confirmDeleteId === id) {
      deleteSavedEffect(id)
      setConfirmDeleteId(null)
      addToast(`Effect "${name}" deleted`, 'success')
    } else {
      setConfirmDeleteId(id)
      setTimeout(() => setConfirmDeleteId(null), 3000)
    }
  }, [confirmDeleteId, deleteSavedEffect, addToast])

  return (
    <motion.div
      className="flex flex-col h-full"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-sm font-semibold text-white">Custom Effects</h2>
          <p className="text-[11px] text-neutral-600 mt-0.5">
            {savedEffects.length} effect{savedEffects.length !== 1 ? 's' : ''} saved
          </p>
        </div>
        <div className="flex items-center gap-2">
          <motion.button
            className="px-3 py-2 rounded-lg bg-white/5 border border-neutral-800 text-[12px] font-medium text-neutral-300 hover:bg-white/10 hover:text-white hover:border-neutral-600 transition-all duration-200 cursor-pointer"
            onClick={() => openPresetBrowser()}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            Presets
          </motion.button>
          <motion.button
            className="px-4 py-2 rounded-lg bg-white text-black text-[12px] font-semibold hover:bg-neutral-200 transition-colors cursor-pointer"
            onClick={() => openEditor()}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            Create Effect
          </motion.button>
        </div>
      </div>

      {/* Content */}
      <AnimatePresence mode="wait">
        {savedEffects.length === 0 ? (
          <motion.div
            className="flex-1 flex flex-col items-center justify-center gap-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="w-16 h-16 rounded-2xl bg-neutral-900/50 border border-neutral-800/50 flex items-center justify-center">
              <span className="text-2xl text-neutral-800 font-bold">FX</span>
            </div>
            <div className="text-center">
              <p className="text-[13px] font-medium text-neutral-500">No custom effects</p>
              <p className="text-[11px] text-neutral-700 mt-1">
                Create your first laser effect or browse presets
              </p>
            </div>
            <div className="flex gap-2">
              <motion.button
                className="px-4 py-2 rounded-lg bg-white text-black text-[12px] font-semibold hover:bg-neutral-200 transition-colors cursor-pointer"
                onClick={() => openEditor()}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                Create Effect
              </motion.button>
              <motion.button
                className="px-4 py-2 rounded-lg bg-white/5 border border-neutral-800 text-[12px] font-medium text-neutral-300 hover:bg-white/10 hover:text-white hover:border-neutral-600 transition-all duration-200 cursor-pointer"
                onClick={() => openPresetBrowser()}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                Browse Presets
              </motion.button>
            </div>
          </motion.div>
        ) : (
          <motion.div
            key="effect-grid"
            className="flex-1 overflow-y-auto custom-scrollbar grid grid-cols-2 gap-2 pr-1 pb-2"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            {savedEffects.map((effect, idx) => (
              <EffectCard
                key={effect.id}
                effect={effect}
                index={idx}
                confirmDeleteId={confirmDeleteId}
                onEdit={() => openEditor(effect)}
                onDelete={handleDelete}
                onLoadPreset={() => openEditor(effect)}
              />
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  )
}

/* ─── Effect Card ───────────────────────────────── */

function EffectCard({
  effect,
  index,
  confirmDeleteId,
  onEdit,
  onDelete,
  onLoadPreset,
}: {
  effect: SavedCustomEffect
  index: number
  confirmDeleteId: string | null
  onEdit: () => void
  onDelete: () => void
  onLoadPreset: () => void
}) {
  const isDeleting = confirmDeleteId === effect.id

  return (
    <motion.div
      className={`relative rounded-xl border p-4 cursor-pointer transition-colors group ${
        isDeleting
          ? 'border-red-900/60 bg-red-950/20'
          : 'border-neutral-800/70 bg-neutral-950/50 hover:border-neutral-700'
      }`}
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2, delay: index * 0.03 }}
      onClick={onEdit}
    >
      <div className="flex items-start justify-between mb-2">
        <div>
          <p className="text-[13px] font-semibold text-neutral-200">{effect.name}</p>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-[9px] px-1.5 py-0.5 rounded-md bg-neutral-800/60 text-neutral-500 font-medium">
              {TYPE_BADGE[effect.type] ?? effect.type}
            </span>
            <span className="text-[9px] px-1.5 py-0.5 rounded-md bg-neutral-800/40 text-neutral-600">
              {effect.frames.length}F
            </span>
            <span className="text-[9px] text-neutral-700">
              {effect.source === 'local' ? 'Local' : 'Hub'}
            </span>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            className="px-2 py-1 text-[10px] text-neutral-400 hover:text-white rounded transition-colors cursor-pointer"
            onClick={(e) => { e.stopPropagation(); onLoadPreset() }}
          >
            Edit
          </button>
          <button
            className={`px-2 py-1 text-[10px] rounded transition-colors cursor-pointer ${
              isDeleting ? 'text-red-400 hover:text-red-300' : 'text-neutral-600 hover:text-red-400'
            }`}
            onClick={(e) => { e.stopPropagation(); onDelete() }}
          >
            {isDeleting ? 'Confirm?' : 'Delete'}
          </button>
        </div>
      </div>

      {/* Tags */}
      {effect.tags.length > 0 && (
        <div className="flex flex-wrap gap-1 mt-2">
          {effect.tags.map((tag) => (
            <span key={tag} className="text-[8px] px-1.5 py-0.5 rounded bg-neutral-800/40 text-neutral-600">
              {tag}
            </span>
          ))}
        </div>
      )}
    </motion.div>
  )
}

/* ─── Import the editor ─────────────────────────── */

import { EffectEditor } from './EffectEditor'

/* ─── Save Dialog Modal ─────────────────────────── */

function SaveDialog() {
  const saveDialogOpen = useEffectEditorStore((s) => s.saveDialogOpen)
  const saveName = useEffectEditorStore((s) => s.saveName)
  const saveType = useEffectEditorStore((s) => s.saveType)
  const saveTags = useEffectEditorStore((s) => s.saveTags)
  const saveTagInput = useEffectEditorStore((s) => s.saveTagInput)
  const saveGlow = useEffectEditorStore((s) => s.saveGlow)
  const closeSaveDialog = useEffectEditorStore((s) => s.closeSaveDialog)
  const setSaveName = useEffectEditorStore((s) => s.setSaveName)
  const setSaveType = useEffectEditorStore((s) => s.setSaveType)
  const addSaveTag = useEffectEditorStore((s) => s.addSaveTag)
  const removeSaveTag = useEffectEditorStore((s) => s.removeSaveTag)
  const setSaveTagInput = useEffectEditorStore((s) => s.setSaveTagInput)
  const saveLocal = useEffectEditorStore((s) => s.saveLocal)
  const addToast = useBlurStore((s) => s.addToast)

  // Easter egg: type "42" as effect name
  const name42Ref = useRef(false)
  const handleNameChange = (val: string) => {
    setSaveName(val)
    if (val.trim() === '42' && !name42Ref.current) {
      name42Ref.current = true
      addToast('The answer to everything, apparently', 'success')
    }
    if (val.trim() !== '42') name42Ref.current = false
  }

  if (!saveDialogOpen) return null

  const handleSaveLocal = () => {
    const name = saveName.trim()
    if (name.length < 2) {
      addToast('Effect name must be at least 2 characters', 'warning')
      return
    }
    if (name.length > 30) {
      addToast('Effect name must be 30 characters or less', 'warning')
      return
    }
    saveLocal()
    addToast('Effect saved locally', 'success')
  }

  const handleSaveHub = () => {
    closeSaveDialog()
    addToast('Hub feature coming soon', 'warning')
  }

  const handleTagKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && saveTagInput.trim()) {
      e.preventDefault()
      addSaveTag(saveTagInput)
    }
  }

  const types: Array<{ value: typeof saveType; label: string }> = [
    { value: 'movement', label: 'Movement' },
    { value: 'pattern', label: 'Pattern' },
    { value: 'chase', label: 'Chase' },
    { value: 'strobe', label: 'Strobe' },
    { value: 'wave', label: 'Wave' },
    { value: 'custom', label: 'Custom' },
  ]

  return (
    <>
      <motion.div
        className="fixed inset-0 z-[80] bg-black/60"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={closeSaveDialog}
      />
      <motion.div
        className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[90] w-[380px] rounded-xl border border-neutral-800 bg-neutral-950 p-5"
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        onClick={(e) => e.stopPropagation()}
        style={{ fontFamily: 'var(--font-inter)' }}
      >
        <div className="flex items-center justify-between mb-4">
          <span className="text-[13px] font-semibold text-white">Save Effect</span>
          <button
            className="text-neutral-500 hover:text-white transition-colors cursor-pointer text-sm"
            onClick={closeSaveDialog}
          >
            x
          </button>
        </div>

        {/* Name */}
        <div className="mb-3">
          <label className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 block mb-1">
            Name
          </label>
          <input
            type="text"
            value={saveName}
            onChange={(e) => handleNameChange(e.target.value)}
            placeholder="Effect name..."
            maxLength={30}
            className="w-full h-8 px-3 text-[12px] text-white bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors"
          />
        </div>

        {/* Type */}
        <div className="mb-3">
          <label className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 block mb-1.5">
            Type
          </label>
          <div className="flex flex-wrap gap-1.5">
            {types.map((t) => (
              <button
                key={t.value}
                className={`px-2.5 py-1 rounded-md text-[10px] font-medium border transition-colors cursor-pointer ${
                  saveType === t.value
                    ? 'bg-neutral-800/60 border-neutral-600 text-white'
                    : 'border-neutral-800/40 text-neutral-600 hover:text-neutral-300'
                }`}
                onClick={() => setSaveType(t.value)}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>

        {/* Tags */}
        <div className="mb-4">
          <label className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 block mb-1">
            Tags
          </label>
          <input
            type="text"
            value={saveTagInput}
            onChange={(e) => setSaveTagInput(e.target.value)}
            onKeyDown={handleTagKeyDown}
            placeholder="Type and press Enter..."
            className="w-full h-8 px-3 text-[12px] text-white bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors mb-1.5"
          />
          {saveTags.length > 0 && (
            <div className="flex flex-wrap gap-1">
              {saveTags.map((tag) => (
                <span
                  key={tag}
                  className="flex items-center gap-1 text-[9px] px-2 py-0.5 rounded-md bg-neutral-800/60 text-neutral-400 cursor-default"
                >
                  {tag}
                  <button
                    className="text-neutral-600 hover:text-white transition-colors cursor-pointer"
                    onClick={() => removeSaveTag(tag)}
                  >
                    x
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>

        {/* Save buttons */}
        <div className="flex gap-2">
          <motion.button
            className={`flex-1 py-2 rounded-lg text-[12px] font-semibold transition-all duration-300 cursor-pointer ${
              saveGlow
                ? 'bg-white text-black shadow-[0_0_20px_rgba(255,255,255,0.4)]'
                : 'bg-white text-black hover:bg-neutral-200'
            }`}
            onClick={handleSaveLocal}
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
          >
            Save Local
          </motion.button>
          <motion.button
            className="flex-1 py-2 rounded-lg text-[12px] font-medium bg-neutral-800/50 border border-neutral-700 text-neutral-400 hover:text-neutral-200 transition-colors cursor-pointer"
            onClick={handleSaveHub}
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.99 }}
          >
            Save to Hub
          </motion.button>
        </div>
      </motion.div>
    </>
  )
}

/* ═══════════════════════════════════════════════════
   Preset Browser Modal
   Shows ALL premade effects (same as Control Panel)
   + custom presets with frame data
   ═══════════════════════════════════════════════════ */

function PresetBrowser() {
  const presetBrowserOpen = useEffectEditorStore((s) => s.presetBrowserOpen)
  const closePresetBrowser = useEffectEditorStore((s) => s.closePresetBrowser)
  const loadPreset = useEffectEditorStore((s) => s.loadPreset)
  const addToast = useBlurStore((s) => s.addToast)

  const [search, setSearch] = useState('')
  const [activeCategory, setActiveCategory] = useState<string>('all')

  // Easter egg: click chase 3 times fast
  const [chaseClicks, setChaseClicks] = useState<{ count: number; last: number }>({ count: 0, last: 0 })

  if (!presetBrowserOpen) return null

  const handleLoadPreset = (preset: SavedCustomEffect) => {
    // Easter egg check for chase
    if (preset.id === 'preset-chase') {
      const now = Date.now()
      const newCount = (now - chaseClicks.last < 2000) ? chaseClicks.count + 1 : 1
      setChaseClicks({ count: newCount, last: now })
      if (newCount >= 3) {
        addToast('You really like chasing, don\'t you?', 'success')
        setChaseClicks({ count: 0, last: 0 })
      }
    }
    loadPreset(preset)
  }

  // Filter presets by search and category
  const filteredPresets = EFFECT_PRESETS.filter((p) => {
    if (activeCategory !== 'all') {
      if (!p.tags.includes(activeCategory)) return false
    }
    if (search && !p.name.toLowerCase().includes(search.toLowerCase())) return false
    return true
  })

  const categories = [
    { value: 'all', label: 'All' },
    { value: 'wave', label: 'Waves' },
    { value: 'chase', label: 'Chase' },
    { value: 'pattern', label: 'Pattern' },
    { value: 'color', label: 'Color' },
    { value: 'advanced', label: 'Advanced' },
  ]

  return (
    <>
      <motion.div
        className="fixed inset-0 z-[80] bg-black/60"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={closePresetBrowser}
      />
      <motion.div
        className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[90] w-[580px] max-h-[75vh] rounded-xl border border-neutral-800 bg-neutral-950 flex flex-col overflow-hidden"
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        onClick={(e) => e.stopPropagation()}
        style={{ fontFamily: 'var(--font-inter)' }}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-neutral-800/60 flex-shrink-0">
          <div>
            <span className="text-[13px] font-semibold text-white">Presets</span>
            <span className="text-[10px] text-neutral-600 ml-2">All premade effects</span>
          </div>
          <button
            className="text-neutral-500 hover:text-white transition-colors cursor-pointer text-sm"
            onClick={closePresetBrowser}
          >
            x
          </button>
        </div>

        {/* Search + Filters */}
        <div className="px-4 pt-3 pb-2 border-b border-neutral-800/30 flex-shrink-0">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search presets..."
            className="w-full h-8 px-3 text-[12px] text-white bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors mb-2"
          />
          <div className="flex gap-1.5">
            {categories.map((cat) => (
              <button
                key={cat.value}
                className={`px-2.5 py-1 rounded-md text-[10px] font-medium border transition-colors cursor-pointer ${
                  activeCategory === cat.value
                    ? 'bg-neutral-800/60 border-neutral-600 text-white'
                    : 'border-neutral-800/40 text-neutral-600 hover:text-neutral-300'
                }`}
                onClick={() => setActiveCategory(cat.value)}
              >
                {cat.label}
                {cat.value !== 'all' && (
                  <span className="ml-1 text-[8px] opacity-60">
                    ({EFFECT_PRESETS.filter(p => p.tags.includes(cat.value)).length})
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Preset Grid - grouped by category */}
        <div className="flex-1 overflow-y-auto custom-scrollbar p-4">
          {filteredPresets.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-[12px] text-neutral-600">No presets found</p>
            </div>
          ) : activeCategory === 'all' ? (
            /* Grouped view */
            EFFECTS_CATEGORIES.map((cat) => {
              const catPresets = filteredPresets.filter((p) => p.tags.includes(cat.category))
              if (catPresets.length === 0) return null
              return (
                <div key={cat.category} className="mb-4 last:mb-0">
                  <div className="px-1 py-1.5 mb-2">
                    <span className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600">
                      {cat.label}
                    </span>
                    <span className="text-[9px] text-neutral-800 ml-2">({catPresets.length})</span>
                  </div>
                  <div className="grid grid-cols-3 gap-1.5">
                    {catPresets.map((preset) => (
                      <PresetCard key={preset.id} preset={preset} onClick={() => handleLoadPreset(preset)} />
                    ))}
                  </div>
                </div>
              )
            })
          ) : (
            /* Single category view */
            <div className="grid grid-cols-3 gap-1.5">
              {filteredPresets.map((preset) => (
                <PresetCard key={preset.id} preset={preset} onClick={() => handleLoadPreset(preset)} />
              ))}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-4 py-3 border-t border-neutral-800/60 flex-shrink-0">
          <div className="flex items-center justify-between">
            <span className="text-[11px] text-neutral-600">
              {EFFECT_PRESETS.length} premade effects
            </span>
            <span className="text-[10px] text-neutral-700 px-2 py-0.5 rounded bg-neutral-800/30">
              Hub coming soon
            </span>
          </div>
        </div>
      </motion.div>
    </>
  )
}

/* ─── Preset Card ───────────────────────────────── */

function PresetCard({
  preset,
  onClick,
}: {
  preset: SavedCustomEffect
  onClick: () => void
}) {
  return (
    <motion.div
      className="rounded-lg border border-neutral-800/60 bg-neutral-900/30 p-2.5 hover:border-neutral-700 transition-colors cursor-pointer"
      onClick={onClick}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.97 }}
    >
      <p className="text-[11px] font-semibold text-neutral-200 mb-1 truncate">{preset.name}</p>
      <div className="flex items-center gap-1.5">
        <span className="text-[8px] px-1.5 py-0.5 rounded bg-neutral-800/60 text-neutral-500">
          {TYPE_BADGE[preset.type] ?? preset.type}
        </span>
        <span className="text-[8px] text-neutral-700">{preset.frames.length}F</span>
      </div>
    </motion.div>
  )
}
