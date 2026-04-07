'use client'

import { useState, useCallback, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useBlurStore, type Keybind } from '@/store/blur-store'

const CATEGORY_LABELS: Record<string, string> = {
  toggle: 'Toggle',
  effect: 'Effect',
  position: 'Position',
  custom: 'Custom',
}

const CATEGORIES: Array<{ value: Keybind['category']; label: string }> = [
  { value: 'toggle', label: 'Toggle' },
  { value: 'effect', label: 'Effect' },
  { value: 'position', label: 'Position' },
  { value: 'custom', label: 'Custom' },
]

function formatKey(e: KeyboardEvent): { key: string; code: string } {
  const parts: string[] = []
  if (e.ctrlKey) parts.push('Ctrl')
  if (e.altKey) parts.push('Alt')
  if (e.shiftKey) parts.push('Shift')
  if (e.metaKey) parts.push('Cmd')

  let mainKey = e.key
  // Clean up key names
  if (mainKey === ' ') mainKey = 'Space'
  else if (mainKey === 'Escape') mainKey = 'Esc'
  else if (mainKey === 'ArrowUp') mainKey = '↑'
  else if (mainKey === 'ArrowDown') mainKey = '↓'
  else if (mainKey === 'ArrowLeft') mainKey = '←'
  else if (mainKey === 'ArrowRight') mainKey = '→'
  else if (mainKey.startsWith('Arrow')) mainKey = mainKey.replace('Arrow', '')
  else if (mainKey.length === 1) mainKey = mainKey.toUpperCase()

  // Don't duplicate if Shift is already shown
  if (e.shiftKey && mainKey.length === 1 && /^[A-Z]$/.test(mainKey)) {
    // Shift+letter is redundant, just show the letter
  } else {
    parts.push(mainKey)
  }

  if (parts.length === 0) parts.push(e.code)

  return {
    key: parts.join('+'),
    code: e.code,
  }
}

export function KeybindPanel() {
  const keybinds = useBlurStore((s) => s.keybinds)
  const keybindListeningId = useBlurStore((s) => s.keybindListeningId)
  const addKeybind = useBlurStore((s) => s.addKeybind)
  const removeKeybind = useBlurStore((s) => s.removeKeybind)
  const stopListening = useBlurStore((s) => s.stopListening)

  const [view, setView] = useState<'list' | 'add'>('list')
  const [label, setLabel] = useState('')
  const [action, setAction] = useState('')
  const [category, setCategory] = useState<Keybind['category']>('toggle')
  const [capturedKey, setCapturedKey] = useState<string | null>(null)
  const [capturedCode, setCapturedCode] = useState<string | null>(null)
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null)

  // Listen for keypresses when in add mode and listening
  useEffect(() => {
    if (!keybindListeningId) return

    const handler = (e: KeyboardEvent) => {
      e.preventDefault()
      e.stopPropagation()
      const { key, code } = formatKey(e)
      setCapturedKey(key)
      setCapturedCode(code)

      // Update the keybind in the store
      const store = useBlurStore.getState()
      const bind = store.keybinds.find((k) => k.id === keybindListeningId)
      if (bind) {
        useBlurStore.setState({
          keybinds: store.keybinds.map((k) =>
            k.id === keybindListeningId ? { ...k, key, code } : k
          ),
          keybindListeningId: null,
        })
      }
    }

    window.addEventListener('keydown', handler, true)
    return () => window.removeEventListener('keydown', handler, true)
  }, [keybindListeningId])

  const handleAdd = useCallback(() => {
    if (!label.trim() || !action.trim()) return
    addKeybind(label.trim(), action.trim(), category)
    setLabel('')
    setAction('')
    setCategory('toggle')
    setCapturedKey(null)
    setCapturedCode(null)
    // After adding, the store will set keybindListeningId to the new bind's ID
    // so the user can immediately press a key
  }, [label, action, category, addKeybind])

  const handleSave = useCallback(() => {
    // Stop listening if still listening
    if (keybindListeningId) {
      stopListening()
    }
    setView('list')
    setLabel('')
    setAction('')
    setCategory('toggle')
    setCapturedKey(null)
    setCapturedCode(null)
  }, [keybindListeningId, stopListening])

  const handleStartAdd = useCallback(() => {
    setView('add')
    setLabel('')
    setAction('')
    setCategory('toggle')
    setCapturedKey(null)
    setCapturedCode(null)
  }, [])

  // Group keybinds by category for display
  const grouped = keybinds.reduce<Record<string, Keybind[]>>((acc, kb) => {
    if (!acc[kb.category]) acc[kb.category] = []
    acc[kb.category].push(kb)
    return acc
  }, {})

  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-sm font-semibold text-white">Keybinds</h2>
          <p className="text-[11px] text-neutral-600 mt-0.5">
            {keybinds.length} keybind{keybinds.length !== 1 ? 's' : ''} configured
          </p>
        </div>
        {view === 'list' ? (
          <motion.button
            className="px-4 py-2 rounded-lg bg-white/5 border border-neutral-800 text-[12px] font-medium text-neutral-300 hover:bg-white/10 hover:text-white hover:border-neutral-600 transition-all duration-200 cursor-pointer"
            onClick={handleStartAdd}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            Add Keybind
          </motion.button>
        ) : (
          <button
            className="flex items-center gap-1.5 text-[12px] text-neutral-500 hover:text-white transition-colors cursor-pointer"
            onClick={handleSave}
          >
            ← Back
          </button>
        )}
      </div>

      <AnimatePresence mode="wait">
        {view === 'add' ? (
          <KeybindCreator
            key="creator"
            label={label}
            action={action}
            category={category}
            capturedKey={capturedKey}
            listeningId={keybindListeningId}
            onLabelChange={setLabel}
            onActionChange={setAction}
            onCategoryChange={setCategory}
            onAdd={handleAdd}
            onListen={(id) => { setCapturedKey(null); setCapturedCode(null); useBlurStore.getState().startListening(id) }}
          />
        ) : (
          <KeybindList
            key="list"
            grouped={grouped}
            confirmDeleteId={confirmDeleteId}
            onConfirmDelete={setConfirmDeleteId}
            onDelete={removeKeybind}
          />
        )}
      </AnimatePresence>
    </motion.div>
  )
}

/* ─── Keybind List ──────────────────────────────── */

function KeybindList({
  grouped,
  confirmDeleteId,
  onConfirmDelete,
  onDelete,
}: {
  grouped: Record<string, Keybind[]>
  confirmDeleteId: string | null
  onConfirmDelete: (id: string | null) => void
  onDelete: (id: string) => void
}) {
  const allKeybinds = Object.values(grouped).flat()

  if (allKeybinds.length === 0) {
    return (
      <motion.div
        className="flex-1 flex flex-col items-center justify-center gap-4"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
      >
        <div className="w-16 h-16 rounded-2xl bg-neutral-900/50 border border-neutral-800/50 flex items-center justify-center">
          <span className="text-2xl text-neutral-800 font-bold">K</span>
        </div>
        <div className="text-center">
          <p className="text-[13px] font-medium text-neutral-500">No keybinds set</p>
          <p className="text-[11px] text-neutral-700 mt-1">
            Bind keys to effects, toggles, and positions
          </p>
        </div>
      </motion.div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto custom-scrollbar space-y-4 pr-1">
      {Object.entries(grouped).map(([cat, binds]) => (
        <div key={cat}>
          <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 block mb-2 px-1">
            {CATEGORY_LABELS[cat] ?? cat}
          </span>
          <div className="space-y-1.5">
            {binds.map((kb, index) => {
              const isDeleting = confirmDeleteId === kb.id
              return (
                <motion.div
                  key={kb.id}
                  className={`relative rounded-xl border p-3 transition-colors ${
                    isDeleting
                      ? 'border-red-900/60 bg-red-950/20'
                      : 'border-neutral-800/70 bg-neutral-950/50 hover:border-neutral-700'
                  }`}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2, delay: index * 0.03 }}
                >
                  <div className="flex items-center gap-3">
                    {/* Key display */}
                    <div className={`flex-shrink-0 w-10 h-8 rounded-lg border flex items-center justify-center ${
                      kb.key === '...'
                        ? 'border-dashed border-neutral-700'
                        : 'bg-neutral-800/50 border-neutral-700'
                    }`}>
                      <span className={`text-[11px] font-mono font-bold ${
                        kb.key === '...' ? 'text-neutral-700' : 'text-white'
                      }`}>
                        {kb.key}
                      </span>
                    </div>

                    <div className="flex-1 min-w-0">
                      <p className="text-[12px] font-medium text-neutral-300 truncate">{kb.label}</p>
                      <p className="text-[10px] text-neutral-600 truncate">{kb.action}</p>
                    </div>

                    {/* Delete button */}
                    <button
                      className={`px-2 py-1 text-[10px] rounded transition-colors cursor-pointer flex-shrink-0 ${
                        isDeleting ? 'text-red-400 hover:text-red-300' : 'text-neutral-700 hover:text-red-400'
                      }`}
                      onClick={(e) => {
                        e.stopPropagation()
                        if (isDeleting) {
                          onDelete(kb.id)
                          onConfirmDelete(null)
                        } else {
                          onConfirmDelete(kb.id)
                          setTimeout(() => onConfirmDelete(null), 3000)
                        }
                      }}
                    >
                      {isDeleting ? 'Confirm?' : '×'}
                    </button>
                  </div>

                  {/* Delete confirm text */}
                  <AnimatePresence>
                    {isDeleting && (
                      <motion.p
                        className="text-[10px] text-red-400/60 mt-1.5 pl-[52px]"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                      >
                        Remove this keybind?
                      </motion.p>
                    )}
                  </AnimatePresence>
                </motion.div>
              )
            })}
          </div>
        </div>
      ))}
    </div>
  )
}

/* ─── Keybind Creator ──────────────────────────── */

function KeybindCreator({
  label,
  action,
  category,
  capturedKey,
  listeningId,
  onLabelChange,
  onActionChange,
  onCategoryChange,
  onAdd,
  onListen,
}: {
  label: string
  action: string
  category: Keybind['category']
  capturedKey: string | null
  listeningId: string | null
  onLabelChange: (v: string) => void
  onActionChange: (v: string) => void
  onCategoryChange: (v: Keybind['category']) => void
  onAdd: () => void
  onListen: (id: string) => void
}) {
  const keybinds = useBlurStore((s) => s.keybinds)
  const addToast = useBlurStore((s) => s.addToast)

  // Find the latest keybind that's still waiting for a key
  const listeningBind = listeningId ? keybinds.find((k) => k.id === listeningId) : null

  const handleAddClick = useCallback(() => {
    if (!label.trim()) { addToast('Label is required', 'warning'); return }
    if (!action.trim()) { addToast('Action is required', 'warning'); return }
    onAdd()
  }, [label, action, onAdd, addToast])

  return (
    <motion.div
      className="flex-1 flex flex-col overflow-y-auto custom-scrollbar"
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      transition={{ duration: 0.25 }}
    >
      {/* Label Input */}
      <div className="mb-4">
        <label className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 block mb-1.5">
          Label
        </label>
        <input
          type="text"
          value={label}
          onChange={(e) => onLabelChange(e.target.value)}
          placeholder="e.g. Toggle Master"
          maxLength={30}
          className="w-full h-9 px-3 text-[12px] text-white bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors"
        />
      </div>

      {/* Action Input */}
      <div className="mb-4">
        <label className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 block mb-1.5">
          Action
        </label>
        <input
          type="text"
          value={action}
          onChange={(e) => onActionChange(e.target.value)}
          placeholder="e.g. Master On/Off, Effect: Strobe"
          maxLength={50}
          className="w-full h-9 px-3 text-[12px] text-white bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors"
        />
      </div>

      {/* Category Selector */}
      <div className="flex items-center gap-2 mb-4">
        <span className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 mr-2">Category</span>
        {CATEGORIES.map((cat) => (
          <button
            key={cat.value}
            className={`px-3 py-1.5 rounded-lg text-[11px] font-medium border transition-colors cursor-pointer ${
              category === cat.value
                ? 'bg-neutral-800/50 border-neutral-600 text-white'
                : 'bg-neutral-900/20 border-neutral-800/40 text-neutral-500 hover:text-neutral-300'
            }`}
            onClick={() => onCategoryChange(cat.value)}
          >
            {cat.label}
          </button>
        ))}
      </div>

      {/* Added keybinds that are waiting for keys */}
      {keybinds.filter((k) => k.key === '...').length > 0 && (
        <div className="mb-4">
          <span className="text-[10px] font-semibold uppercase tracking-widest text-neutral-600 block mb-2">
            Waiting for Key
          </span>
          <div className="space-y-1.5">
            {keybinds.filter((k) => k.key === '...').map((kb) => (
              <div
                key={kb.id}
                className="flex items-center gap-3 p-3 rounded-xl border border-neutral-800/70 bg-neutral-950/50"
              >
                <div className={`flex-shrink-0 w-10 h-8 rounded-lg border border-dashed flex items-center justify-center ${
                  listeningId === kb.id
                    ? 'border-white bg-neutral-800/50 animate-pulse'
                    : 'border-neutral-700'
                }`}>
                  <span className="text-[11px] font-mono text-neutral-500">
                    {listeningId === kb.id ? '...' : '???'}
                  </span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-[12px] font-medium text-neutral-300 truncate">{kb.label}</p>
                  <p className="text-[10px] text-neutral-600 truncate">{kb.action}</p>
                </div>
                {listeningId !== kb.id && (
                  <motion.button
                    className="px-3 py-1.5 rounded-lg text-[10px] font-medium bg-neutral-800/50 border border-neutral-700 text-neutral-300 hover:bg-neutral-700/50 hover:text-white transition-colors cursor-pointer"
                    onClick={() => onListen(kb.id)}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    Listen
                  </motion.button>
                )}
                {listeningId === kb.id && (
                  <span className="text-[10px] text-neutral-400 animate-pulse">Press a key...</span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Save / Add button */}
      <button
        className="w-full py-2.5 rounded-lg bg-white text-black text-[12px] font-semibold hover:bg-neutral-200 transition-colors cursor-pointer mt-auto"
        onClick={handleAddClick}
      >
        Add Keybind
      </button>
    </motion.div>
  )
}
