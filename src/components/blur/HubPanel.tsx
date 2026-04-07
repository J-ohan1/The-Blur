'use client'

import { useState, useMemo, useCallback, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  useBlurStore,
  type HubEffect,
} from '@/store/blur-store'
import { useEffectEditorStore } from '@/store/effect-editor-store'
import type { EffectType } from '@/store/effect-editor-store'

/* ─── Constants ───────────────────────────────────── */

const TYPE_LABELS: Record<string, string> = {
  all: 'All',
  movement: 'Movement',
  pattern: 'Pattern',
  chase: 'Chase',
  strobe: 'Strobe',
  wave: 'Wave',
  custom: 'Custom',
}

const FILTER_OPTIONS: Array<{ value: 'all' | EffectType; label: string }> = [
  { value: 'all', label: 'All' },
  { value: 'movement', label: 'Movement' },
  { value: 'pattern', label: 'Pattern' },
  { value: 'chase', label: 'Chase' },
  { value: 'strobe', label: 'Strobe' },
  { value: 'wave', label: 'Wave' },
  { value: 'custom', label: 'Custom' },
]

/* ─── Main Panel ─────────────────────────────────── */

export function HubPanel() {
  const [activeTab, setActiveTab] = useState<'browse' | 'my'>('browse')

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
          <h2 className="text-sm font-semibold text-white">Hub</h2>
          <p className="text-[11px] text-neutral-600 mt-0.5">
            Community effects shared via Firebase
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 mb-4">
        <TabButton active={activeTab === 'browse'} onClick={() => setActiveTab('browse')}>
          Browse
        </TabButton>
        <TabButton active={activeTab === 'my'} onClick={() => setActiveTab('my')}>
          My Uploads
        </TabButton>
      </div>

      <AnimatePresence mode="wait">
        {activeTab === 'browse' ? (
          <BrowseTab key="browse" />
        ) : (
          <MyUploadsTab key="my" />
        )}
      </AnimatePresence>
    </motion.div>
  )
}

/* ─── Tab Button ─────────────────────────────────── */

function TabButton({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      className={`px-4 py-2 text-[12px] font-medium rounded-lg transition-colors duration-150 cursor-pointer ${
        active
          ? 'bg-neutral-800/50 text-white border border-neutral-700'
          : 'text-neutral-600 border border-transparent hover:text-neutral-400 hover:bg-neutral-800/20'
      }`}
      onClick={onClick}
    >
      {children}
    </button>
  )
}

/* ═══════════════════════════════════════════════════
   Browse Tab — All effects, search, filter
   ═══════════════════════════════════════════════════ */

function BrowseTab() {
  const hubEffects = useBlurStore((s) => s.hubEffects)
  const hubSearch = useBlurStore((s) => s.hubSearch)
  const hubFilter = useBlurStore((s) => s.hubFilter)
  const hubViewingUser = useBlurStore((s) => s.hubViewingUser)
  const setHubSearch = useBlurStore((s) => s.setHubSearch)
  const setHubFilter = useBlurStore((s) => s.setHubFilter)
  const viewHubUser = useBlurStore((s) => s.viewHubUser)
  const addHubEffectToCustom = useBlurStore((s) => s.addHubEffectToCustom)
  const addToast = useBlurStore((s) => s.addToast)

  const [filterOpen, setFilterOpen] = useState(false)
  const filterRef = useRef<HTMLDivElement>(null)
  const [addedIds, setAddedIds] = useState<Set<string>>(new Set())

  // Filtered effects
  const filteredEffects = useMemo(() => {
    let list = hubEffects
    if (hubViewingUser) {
      list = list.filter((e) => e.authorId === hubViewingUser)
    }
    if (hubFilter !== 'all') {
      list = list.filter((e) => e.type === hubFilter)
    }
    if (hubSearch.trim()) {
      const q = hubSearch.toLowerCase()
      list = list.filter(
        (e) => e.name.toLowerCase().includes(q) || e.authorName.toLowerCase().includes(q)
      )
    }
    return list
  }, [hubEffects, hubViewingUser, hubFilter, hubSearch])

  // Viewing user info
  const viewingUserData = useMemo(() => {
    if (!hubViewingUser) return null
    const first = hubEffects.find((e) => e.authorId === hubViewingUser)
    return first ? { name: first.authorName, id: first.authorId } : null
  }, [hubViewingUser, hubEffects])

  const userEffectCount = useMemo(() => {
    if (!hubViewingUser) return 0
    return hubEffects.filter((e) => e.authorId === hubViewingUser).length
  }, [hubViewingUser, hubEffects])

  // Unique authors with counts
  const topAuthors = useMemo(() => {
    const map = new Map<string, { name: string; count: number; totalDownloads: number }>()
    for (const e of hubEffects) {
      const existing = map.get(e.authorId)
      if (existing) {
        existing.count++
        existing.totalDownloads += e.downloads
      } else {
        map.set(e.authorId, { name: e.authorName, count: 1, totalDownloads: e.downloads })
      }
    }
    return Array.from(map.entries())
      .map(([id, data]) => ({ id, ...data }))
      .sort((a, b) => b.totalDownloads - a.totalDownloads)
  }, [hubEffects])

  const handleAdd = useCallback((effect: HubEffect) => {
    addHubEffectToCustom(effect)
    setAddedIds((prev) => new Set([...prev, effect.id]))
  }, [addHubEffectToCustom])

  // Easter egg: search for "blur" in hub
  const [blurSearchShown, setBlurSearchShown] = useState(false)
  const handleSearch = useCallback((v: string) => {
    setHubSearch(v)
    if (v.toLowerCase().trim() === 'blur' && !blurSearchShown) {
      setBlurSearchShown(true)
      addToast('Searching for greatness, are we?', 'success')
    }
    if (v.toLowerCase().trim() !== 'blur') setBlurSearchShown(false)
  }, [setHubSearch, blurSearchShown, addToast])

  // Close dropdown on outside click
  const handleContainerClick = useCallback(() => {
    if (filterOpen) setFilterOpen(false)
  }, [filterOpen])

  return (
    <motion.div
      className="flex flex-col h-full min-h-0"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={handleContainerClick}
    >
      {/* Viewing user banner */}
      <AnimatePresence>
        {hubViewingUser && viewingUserData && (
          <motion.div
            className="flex items-center gap-3 mb-3 px-3 py-2 rounded-lg bg-neutral-900/40 border border-neutral-800/50"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
          >
            <div className="w-7 h-7 rounded-full bg-neutral-800 border border-neutral-700 flex items-center justify-center flex-shrink-0">
              <span className="text-[10px] font-bold text-neutral-400">
                {viewingUserData.name.charAt(0).toUpperCase()}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[12px] font-semibold text-white">{viewingUserData.name}</p>
              <p className="text-[10px] text-neutral-600">{userEffectCount} effect{userEffectCount !== 1 ? 's' : ''} shared</p>
            </div>
            <button
              className="px-3 py-1.5 text-[10px] font-medium text-neutral-500 hover:text-white rounded-md border border-neutral-800/40 hover:border-neutral-700 transition-colors cursor-pointer"
              onClick={() => viewHubUser(null)}
            >
              Back
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Search + Filter */}
      <div className="flex items-center gap-3 mb-3">
        <div className="relative flex-1 max-w-xs">
          <input
            type="text"
            placeholder="Search effects or creators..."
            value={hubSearch}
            onChange={(e) => handleSearch(e.target.value)}
            className="w-full h-8 pl-3 pr-3 text-[12px] text-neutral-300 bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors"
          />
        </div>

        {/* Filter dropdown */}
        <div className="relative" ref={filterRef}>
          <button
            className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-[11px] font-medium transition-colors cursor-pointer ${
              hubFilter !== 'all'
                ? 'bg-neutral-800/50 border-neutral-700 text-white'
                : 'bg-neutral-900/20 border-neutral-800/40 text-neutral-500 hover:text-neutral-300 hover:border-neutral-700'
            }`}
            onClick={(e) => {
              e.stopPropagation()
              setFilterOpen(!filterOpen)
            }}
          >
            <span>Filter</span>
            <span className="text-[8px]">{hubFilter !== 'all' ? TYPE_LABELS[hubFilter] : ''}</span>
            <svg width="10" height="6" viewBox="0 0 10 6" fill="none" className="opacity-60">
              <path d="M1 1L5 5L9 1" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>

          <AnimatePresence>
            {filterOpen && (
              <motion.div
                className="absolute top-full mt-1 right-0 w-36 rounded-lg border border-neutral-800 bg-neutral-950/95 backdrop-blur-md p-1 z-50 shadow-xl"
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -4 }}
                onClick={(e) => e.stopPropagation()}
              >
                {FILTER_OPTIONS.map((opt) => (
                  <button
                    key={opt.value}
                    className={`w-full px-3 py-1.5 text-[11px] text-left rounded-md transition-colors cursor-pointer ${
                      hubFilter === opt.value
                        ? 'bg-neutral-800/50 text-white'
                        : 'text-neutral-500 hover:bg-neutral-800/30 hover:text-neutral-300'
                    }`}
                    onClick={() => {
                      setHubFilter(opt.value)
                      setFilterOpen(false)
                    }}
                  >
                    {opt.label}
                  </button>
                ))}
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Effect count */}
      <div className="mb-3 px-1">
        <span className="text-[10px] text-neutral-700 uppercase tracking-widest">
          {filteredEffects.length} effect{filteredEffects.length !== 1 ? 's' : ''} found
          {hubFilter !== 'all' && (
            <span className="text-neutral-600 ml-1">-- {TYPE_LABELS[hubFilter]}</span>
          )}
        </span>
      </div>

      {/* Effect Grid */}
      <div className="flex-1 overflow-y-auto custom-scrollbar pr-1">
        <div className="grid grid-cols-2 gap-3">
          <AnimatePresence>
            {filteredEffects.map((effect, index) => (
              <HubEffectCard
                key={effect.id}
                effect={effect}
                index={index}
                added={addedIds.has(effect.id)}
                onAdd={() => handleAdd(effect)}
                onAuthorClick={() => viewHubUser(effect.authorId)}
              />
            ))}
          </AnimatePresence>
        </div>

        {filteredEffects.length === 0 && (
          <div className="flex items-center justify-center h-40">
            <span className="text-[12px] text-neutral-700">No effects found</span>
          </div>
        )}
      </div>

      {/* Top Creators footer */}
      {!hubViewingUser && (
        <div className="mt-3 pt-3 border-t border-neutral-800/40 flex-shrink-0">
          <span className="text-[9px] font-semibold uppercase tracking-widest text-neutral-700 block mb-2">
            Top Creators
          </span>
          <div className="flex items-center gap-2 flex-wrap">
            {topAuthors.slice(0, 6).map((author) => (
              <button
                key={author.id}
                className="flex items-center gap-1.5 px-2 py-1 rounded-md border border-neutral-800/40 text-[10px] text-neutral-500 hover:text-neutral-300 hover:border-neutral-700 transition-colors cursor-pointer"
                onClick={() => viewHubUser(author.id)}
              >
                <div className="w-4 h-4 rounded-full bg-neutral-800 border border-neutral-700 flex items-center justify-center">
                  <span className="text-[7px] font-bold text-neutral-400">
                    {author.name.charAt(0).toUpperCase()}
                  </span>
                </div>
                {author.name}
                <span className="text-[8px] text-neutral-700">({author.count})</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </motion.div>
  )
}

/* ─── Hub Effect Card ────────────────────────────── */

function HubEffectCard({
  effect,
  index,
  added,
  onAdd,
  onAuthorClick,
}: {
  effect: HubEffect
  index: number
  added: boolean
  onAdd: () => void
  onAuthorClick: () => void
}) {
  return (
    <motion.div
      className="relative rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden group"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay: index * 0.03 }}
    >
      {/* Effect name — no icon */}
      <div className="p-3 pb-2">
        <p className="text-[13px] font-semibold text-neutral-200 mb-1 truncate">
          {effect.name}
        </p>
        {/* Author line */}
        <button
          className="text-[10px] text-neutral-600 hover:text-neutral-300 transition-colors cursor-pointer flex items-center gap-1"
          onClick={onAuthorClick}
        >
          <span>by</span>
          <span className="text-neutral-500 font-medium">{effect.authorName}</span>
        </button>
      </div>

      {/* Bottom row: type badge + downloads + add button */}
      <div className="flex items-center justify-between px-3 pb-3">
        <div className="flex items-center gap-2">
          <span className="text-[8px] px-1.5 py-0.5 rounded-md bg-neutral-800/60 text-neutral-500 font-medium">
            {TYPE_LABELS[effect.type] ?? effect.type}
          </span>
          <span className="text-[8px] text-neutral-700">
            {effect.downloads} dl
          </span>
        </div>

        {/* Add button — z-10 keeps it above the hover code preview overlay */}
        <motion.button
          className={`relative z-10 px-3 py-1 rounded-md text-[10px] font-medium border transition-all duration-200 cursor-pointer ${
            added
              ? 'bg-neutral-800/40 border-neutral-700/50 text-neutral-600'
              : 'bg-white text-black border-transparent hover:bg-neutral-200'
          }`}
          onClick={onAdd}
          whileHover={{ scale: added ? 1 : 1.02 }}
          whileTap={{ scale: added ? 1 : 0.98 }}
          disabled={added}
        >
          {added ? 'Added' : 'Add'}
        </motion.button>
      </div>

      {/* Code preview on hover */}
      <motion.div
        className="absolute bottom-0 left-0 right-0 bg-neutral-950/95 border-t border-neutral-800/50 px-3 py-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200"
        initial={false}
      >
        <span className="text-[8px] text-neutral-600 block mb-1">Code Preview</span>
        <code className="text-[9px] text-neutral-400 font-mono leading-relaxed block">
          {effect.codeLines.map((line, i) => (
            <span key={i} className="block">{line}</span>
          ))}
        </code>
      </motion.div>
    </motion.div>
  )
}

/* ═══════════════════════════════════════════════════
   My Uploads Tab — User's own published effects
   ═══════════════════════════════════════════════════ */

function MyUploadsTab() {
  const currentUser = useBlurStore((s) => s.currentUser)
  const hubEffects = useBlurStore((s) => s.hubEffects)
  const addToast = useBlurStore((s) => s.addToast)

  // User's own uploads (mock: filter by current user's id)
  const myEffects = hubEffects.filter((e) => e.authorId === currentUser.id)

  if (myEffects.length === 0) {
    return (
      <motion.div
        className="flex-1 flex flex-col items-center justify-center gap-4"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
      >
        <div className="w-16 h-16 rounded-2xl bg-neutral-900/50 border border-neutral-800/50 flex items-center justify-center">
          <span className="text-2xl text-neutral-800 font-bold">H</span>
        </div>
        <div className="text-center">
          <p className="text-[13px] font-medium text-neutral-500">No uploads yet</p>
          <p className="text-[11px] text-neutral-700 mt-1">
            Publish your custom effects to the Hub
          </p>
        </div>
        <motion.button
          className="px-4 py-2 rounded-lg bg-neutral-800/50 border border-neutral-700 text-[12px] font-medium text-neutral-300 hover:bg-neutral-700/50 hover:text-white transition-all duration-200 cursor-pointer"
          onClick={() => addToast('Publish from the Effect panel via Save to Hub', 'warning')}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          Go to Effect Panel
        </motion.button>
      </motion.div>
    )
  }

  return (
    <motion.div
      className="flex-1 overflow-y-auto custom-scrollbar pr-1"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <div className="space-y-2">
        {myEffects.map((effect, index) => (
          <motion.div
            key={effect.id}
            className="flex items-center gap-3 px-3 py-2.5 rounded-lg border border-neutral-800/60 bg-neutral-950/30"
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: index * 0.03 }}
          >
            <div className="flex-1 min-w-0">
              <p className="text-[12px] font-medium text-neutral-300 truncate">{effect.name}</p>
              <div className="flex items-center gap-2 mt-0.5">
                <span className="text-[8px] px-1.5 py-0.5 rounded bg-neutral-800/60 text-neutral-500">
                  {TYPE_LABELS[effect.type] ?? effect.type}
                </span>
                <span className="text-[9px] text-neutral-700">{effect.downloads} downloads</span>
              </div>
            </div>
            <span className="text-[9px] text-neutral-700">
              {Math.floor((Date.now() - effect.createdAt) / 86400000)}d ago
            </span>
          </motion.div>
        ))}
      </div>
    </motion.div>
  )
}
