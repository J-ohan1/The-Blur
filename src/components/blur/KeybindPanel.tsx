'use client'

import { useState, useEffect, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useBlurStore, EFFECTS, type Keybind } from '@/store/blur-store'

/* ─── Category definitions ─────────────────────── */

type KeybindCategory = 'effects' | 'toggles' | 'positions'

interface KeybindItem {
  action: string
  label: string
  category: KeybindCategory
}

const TOGGLE_ITEMS: KeybindItem[] = [
  { action: 'toggle-master', label: 'On / Off', category: 'toggles' },
  { action: 'toggle-fade', label: 'Fade On / Off', category: 'toggles' },
  { action: 'toggle-hold', label: 'Hold On / Off', category: 'toggles' },
  { action: 'toggle-hold-fade', label: 'Hold Fade On / Off', category: 'toggles' },
]

const CATEGORY_META: { key: KeybindCategory; label: string }[] = [
  { key: 'effects', label: 'Effects' },
  { key: 'toggles', label: 'Toggles' },
  { key: 'positions', label: 'Positions' },
]

/* ─── Key formatting helpers ───────────────────── */

function formatKey(e: KeyboardEvent): string {
  const parts: string[] = []
  if (e.ctrlKey || e.metaKey) parts.push('Ctrl')
  if (e.altKey) parts.push('Alt')
  if (e.shiftKey) parts.push('Shift')

  // Ignore modifier-only presses
  if (['Control', 'Alt', 'Shift', 'Meta'].includes(e.key)) return ''

  const keyName = e.key.length === 1 ? e.key.toUpperCase() : e.key
  parts.push(keyName)
  return parts.join('+')
}

function formatKeyDisplay(code: string): string {
  if (!code) return ''
  // Handle compound keys
  const parts = code.split('+')
  return parts
    .map((part) => {
      const trimmed = part.trim()
      if (trimmed.length === 1) return trimmed.toUpperCase()
      return trimmed.charAt(0).toUpperCase() + trimmed.slice(1)
    })
    .join('+')
}

/* ─── Main Panel ───────────────────────────────── */

export function KeybindPanel() {
  const keybinds = useBlurStore((s) => s.keybinds)
  const keybindListeningId = useBlurStore((s) => s.keybindListeningId)
  const positions = useBlurStore((s) => s.positions)
  const addKeybind = useBlurStore((s) => s.addKeybind)
  const setKeybindKey = useBlurStore((s) => s.setKeybindKey)
  const removeKeybind = useBlurStore((s) => s.removeKeybind)
  const startListening = useBlurStore((s) => s.startListening)
  const stopListening = useBlurStore((s) => s.stopListening)
  const addToast = useBlurStore((s) => s.addToast)

  const [selectedCategory, setSelectedCategory] = useState<KeybindCategory | null>(null)
  const [selectedAction, setSelectedAction] = useState<string | null>(null)

  // Get all items for a category
  const getItemsForCategory = useCallback(
    (cat: KeybindCategory): KeybindItem[] => {
      switch (cat) {
        case 'toggles':
          return TOGGLE_ITEMS
        case 'effects':
          return EFFECTS.map((e) => ({
            action: `effect-${e.id}`,
            label: e.name,
            category: 'effects' as const,
          }))
        case 'positions':
          return positions.map((p) => ({
            action: `position-${p.id}`,
            label: p.name,
            category: 'positions' as const,
          }))
      }
    },
    [positions]
  )

  // Get keybind for an action
  const getKeybindForAction = useCallback(
    (action: string): Keybind | undefined => {
      return keybinds.find((k) => k.action === action)
    },
    [keybinds]
  )

  // Keyboard listener for recording
  useEffect(() => {
    if (!keybindListeningId) return

    const handleKeyDown = (e: KeyboardEvent) => {
      e.preventDefault()
      e.stopPropagation()

      const formatted = formatKey(e)
      if (!formatted) return // Ignore modifier-only presses

      // Check for duplicate keys
      const existingWithKey = keybinds.find(
        (k) => k.code === formatted && k.id !== keybindListeningId
      )
      if (existingWithKey) {
        addToast(
          `"${formatted}" is already used for "${existingWithKey.label}"`,
          'warning'
        )
      }

      setKeybindKey(keybindListeningId, formatted, formatted)
    }

    window.addEventListener('keydown', handleKeyDown, true)
    return () => window.removeEventListener('keydown', handleKeyDown, true)
  }, [keybindListeningId, keybinds, setKeybindKey, addToast])

  // Handle Record button click
  const handleRecord = useCallback(
    (item: KeybindItem) => {
      const existing = getKeybindForAction(item.action)
      if (existing) {
        // Re-record existing keybind
        startListening(existing.id)
      } else {
        // Create new keybind and start listening
        addKeybind(item.label, item.action, item.category as Keybind['category'])
      }
      setSelectedAction(item.action)
    },
    [getKeybindForAction, startListening, addKeybind]
  )

  // Handle cancel recording
  const handleCancelRecording = useCallback(() => {
    // If the keybind has no key set (was just created), remove it
    if (keybindListeningId) {
      const kb = keybinds.find((k) => k.id === keybindListeningId)
      if (kb && kb.key === '...') {
        removeKeybind(keybindListeningId)
      }
    }
    stopListening()
    setSelectedAction(null)
  }, [keybindListeningId, keybinds, removeKeybind, stopListening])

  // Remove keybind
  const handleRemoveKeybind = useCallback(
    (action: string) => {
      const kb = getKeybindForAction(action)
      if (kb) {
        removeKeybind(kb.id)
        if (selectedAction === action) setSelectedAction(null)
      }
    },
    [getKeybindForAction, removeKeybind, selectedAction]
  )

  // Category items
  const categoryItems = selectedCategory ? getItemsForCategory(selectedCategory) : []

  // Listening state
  const isListening = !!keybindListeningId
  const listeningItem = isListening
    ? keybinds.find((k) => k.id === keybindListeningId)
    : null

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
            {keybinds.filter((k) => k.key !== '...').length} keybind{keybinds.filter((k) => k.key !== '...').length !== 1 ? 's' : ''} assigned
          </p>
        </div>
      </div>

      {/* Content */}
      <AnimatePresence mode="wait">
        {!selectedCategory ? (
          /* ── Category Selection ── */
          <motion.div
            key="categories"
            className="flex-1 flex flex-col items-center justify-center gap-6"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="w-16 h-16 rounded-2xl bg-neutral-900/50 border border-neutral-800/50 flex items-center justify-center">
              <span className="text-2xl text-neutral-800 font-bold">K</span>
            </div>
            <div className="text-center">
              <p className="text-[13px] font-medium text-neutral-500">
                Select a category to manage keybinds
              </p>
              <p className="text-[11px] text-neutral-700 mt-1">
                Effects, Toggles, or Positions
              </p>
            </div>
            <div className="flex gap-3">
              {CATEGORY_META.map((cat) => {
                const count = keybinds.filter((k) => {
                  if (cat.key === 'effects') return k.action.startsWith('effect-') && k.key !== '...'
                  if (cat.key === 'toggles') return k.action.startsWith('toggle-') && k.key !== '...'
                  if (cat.key === 'positions') return k.action.startsWith('position-') && k.key !== '...'
                  return false
                }).length
                return (
                  <motion.button
                    key={cat.key}
                    className="px-5 py-2.5 rounded-lg border border-neutral-800 bg-neutral-900/20 hover:bg-neutral-800/30 hover:border-neutral-700 transition-all cursor-pointer flex flex-col items-center gap-1"
                    onClick={() => setSelectedCategory(cat.key)}
                    whileHover={{ scale: 1.03 }}
                    whileTap={{ scale: 0.97 }}
                  >
                    <span className="text-[12px] font-medium text-neutral-300">
                      {cat.label}
                    </span>
                    {count > 0 && (
                      <span className="text-[9px] text-neutral-600">
                        {count} bound
                      </span>
                    )}
                  </motion.button>
                )
              })}
            </div>
          </motion.div>
        ) : (
          /* ── Items List ── */
          <motion.div
            key="items"
            className="flex-1 flex flex-col overflow-hidden"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.25 }}
          >
            {/* Back + Category header */}
            <div className="flex items-center gap-3 mb-4 flex-shrink-0">
              <button
                className="flex items-center gap-1.5 text-[12px] text-neutral-500 hover:text-white transition-colors cursor-pointer"
                onClick={() => {
                  setSelectedCategory(null)
                  setSelectedAction(null)
                  if (isListening) handleCancelRecording()
                }}
              >
                &larr; Back
              </button>
              <span className="text-[13px] font-semibold text-white">
                {CATEGORY_META.find((c) => c.key === selectedCategory)?.label}
              </span>
              <span className="text-[10px] text-neutral-600 ml-1">
                {categoryItems.length} item{categoryItems.length !== 1 ? 's' : ''}
              </span>
            </div>

            {/* Listening banner */}
            <AnimatePresence>
              {isListening && (
                <motion.div
                  className="mb-3 px-4 py-2.5 rounded-lg border border-neutral-700 bg-neutral-800/30 flex items-center justify-between flex-shrink-0"
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                >
                  <div className="flex items-center gap-2">
                    <motion.div
                      className="w-2 h-2 rounded-full bg-white"
                      animate={{ opacity: [1, 0.3, 1] }}
                      transition={{ duration: 1, repeat: Infinity, ease: 'easeInOut' }}
                    />
                    <span className="text-[11px] text-neutral-300">
                      {listeningItem
                        ? `Press a key for "${listeningItem.label}"...`
                        : 'Press a key...'}
                    </span>
                  </div>
                  <button
                    className="text-[10px] text-neutral-500 hover:text-white transition-colors cursor-pointer px-2 py-1 rounded-md hover:bg-neutral-700/40"
                    onClick={handleCancelRecording}
                  >
                    Cancel
                  </button>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Items list */}
            <div className="flex-1 overflow-y-auto custom-scrollbar space-y-1.5 pr-1">
              {categoryItems.length === 0 ? (
                <motion.div
                  className="flex flex-col items-center justify-center h-full gap-2"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                >
                  <p className="text-[12px] text-neutral-600">No items available</p>
                  {selectedCategory === 'positions' && (
                    <p className="text-[10px] text-neutral-700">
                      Create positions in the Control panel first
                    </p>
                  )}
                </motion.div>
              ) : (
                categoryItems.map((item, idx) => {
                  const keybind = getKeybindForAction(item.action)
                  const hasKey = keybind && keybind.key !== '...'
                  const isSelected = selectedAction === item.action
                  const isRecordingThis = isListening && listeningItem?.action === item.action

                  return (
                    <motion.div
                      key={item.action}
                      className={`rounded-lg border px-4 py-3 flex items-center justify-between transition-colors ${
                        isRecordingThis
                          ? 'border-neutral-600 bg-neutral-800/30'
                          : isSelected
                          ? 'border-neutral-700 bg-neutral-900/40'
                          : 'border-neutral-800/50 hover:border-neutral-700/60 bg-neutral-950/30'
                      }`}
                      initial={{ opacity: 0, y: 4 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.15, delay: idx * 0.015 }}
                    >
                      {/* Left: Label */}
                      <div className="flex items-center gap-3 min-w-0">
                        <span className="text-[12px] font-medium text-neutral-300 truncate">
                          {item.label}
                        </span>
                        <span className="text-[9px] px-1.5 py-0.5 rounded bg-neutral-800/50 text-neutral-600 flex-shrink-0">
                          {item.category}
                        </span>
                      </div>

                      {/* Right: Key display + actions */}
                      <div className="flex items-center gap-2 flex-shrink-0 ml-3">
                        {hasKey ? (
                          <div className="flex items-center gap-2">
                            <span className="text-[11px] font-mono font-semibold text-white bg-neutral-800/60 border border-neutral-700 px-2.5 py-1 rounded-md min-w-[36px] text-center">
                              {keybind!.key}
                            </span>
                            <button
                              className="text-[10px] text-neutral-600 hover:text-red-400 transition-colors cursor-pointer px-1.5 py-1 rounded-md hover:bg-neutral-800/30"
                              onClick={() => handleRemoveKeybind(item.action)}
                            >
                              Remove
                            </button>
                            <button
                              className="text-[10px] text-neutral-500 hover:text-neutral-200 transition-colors cursor-pointer px-2 py-1 rounded-md border border-neutral-800/40 hover:border-neutral-700"
                              onClick={() => handleRecord(item)}
                            >
                              Re-record
                            </button>
                          </div>
                        ) : isRecordingThis ? (
                          <motion.span
                            className="text-[10px] text-neutral-400 px-2 py-1"
                            animate={{ opacity: [0.4, 1, 0.4] }}
                            transition={{ duration: 1.2, repeat: Infinity }}
                          >
                            Listening...
                          </motion.span>
                        ) : (
                          <motion.button
                            className="text-[10px] font-medium text-neutral-500 hover:text-white px-3 py-1.5 rounded-md border border-neutral-800/40 hover:border-neutral-600 hover:bg-neutral-800/20 transition-all cursor-pointer"
                            onClick={() => handleRecord(item)}
                            whileHover={{ scale: 1.02 }}
                            whileTap={{ scale: 0.98 }}
                          >
                            Record
                          </motion.button>
                        )}
                      </div>
                    </motion.div>
                  )
                })
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  )
}
