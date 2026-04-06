'use client'

import { useState, useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  useBlurStore,
  roleDotColor,
  roleLabel,
  getActiveButtons,
  canPerform,
  type PlayerRole,
} from '@/store/blur-store'

const ROLE_FILTERS: { label: string; value: PlayerRole | 'all' }[] = [
  { label: 'All', value: 'all' },
  { label: 'Staff', value: 'staff' },
  { label: 'Whitelisted', value: 'hardcoded_whitelist' },
  { label: 'Temp WL', value: 'temp_whitelist' },
  { label: 'Normal', value: 'normal' },
  { label: 'Blacklisted', value: 'blacklisted' },
]

export function PlayerPanel() {
  const currentUser = useBlurStore((s) => s.currentUser)
  const players = useBlurStore((s) => s.players)
  const playerSearch = useBlurStore((s) => s.playerSearch)
  const playerFilter = useBlurStore((s) => s.playerFilter)
  const whitelistPlayer = useBlurStore((s) => s.whitelistPlayer)
  const removePlayer = useBlurStore((s) => s.removePlayer)
  const kickPlayer = useBlurStore((s) => s.kickPlayer)
  const setPlayerSearch = useBlurStore((s) => s.setPlayerSearch)
  const setPlayerFilter = useBlurStore((s) => s.setPlayerFilter)

  const filteredPlayers = useMemo(() => {
    let list = players.filter((p) => p.id !== currentUser.id)
    if (playerFilter !== 'all') {
      list = list.filter((p) => p.role === playerFilter)
    }
    if (playerSearch.trim()) {
      const q = playerSearch.toLowerCase()
      list = list.filter((p) => p.name.toLowerCase().includes(q))
    }
    return list
  }, [players, playerFilter, playerSearch, currentUser.id])

  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* Search + Filter */}
      <div className="flex items-center gap-3 mb-4">
        <div className="relative flex-1 max-w-xs">
          <input
            type="text"
            placeholder="Search players..."
            value={playerSearch}
            onChange={(e) => setPlayerSearch(e.target.value)}
            className="w-full h-8 pl-3 pr-3 text-[12px] text-neutral-300 bg-neutral-900/60 border border-neutral-800 rounded-lg outline-none placeholder:text-neutral-700 focus:border-neutral-600 transition-colors"
          />
        </div>

        <div className="flex items-center gap-1">
          {ROLE_FILTERS.map((f) => (
            <button
              key={f.value}
              className={`px-2.5 py-1.5 text-[10px] font-medium rounded-md transition-colors duration-150 cursor-pointer ${
                playerFilter === f.value
                  ? 'bg-neutral-800 text-white border border-neutral-700'
                  : 'text-neutral-600 border border-transparent hover:text-neutral-400'
              }`}
              onClick={() => setPlayerFilter(f.value)}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      {/* Player Count */}
      <div className="mb-3 px-1">
        <span className="text-[10px] text-neutral-700 uppercase tracking-widest">
          {filteredPlayers.length} Player{filteredPlayers.length !== 1 ? 's' : ''} found
        </span>
      </div>

      {/* Player Grid */}
      <div className="flex-1 overflow-y-auto custom-scrollbar pr-1">
        <div className="grid grid-cols-2 gap-3">
          <AnimatePresence>
            {filteredPlayers.map((player, index) => (
              <PlayerCard
                key={player.id}
                player={player}
                viewerRole={currentUser.role}
                onWhitelist={() => whitelistPlayer(player.id)}
                onRemove={() => removePlayer(player.id)}
                onKick={() => kickPlayer(player.id)}
                index={index}
              />
            ))}
          </AnimatePresence>
        </div>

        {filteredPlayers.length === 0 && (
          <div className="flex items-center justify-center h-40">
            <span className="text-[12px] text-neutral-700">No players found</span>
          </div>
        )}
      </div>
    </motion.div>
  )
}

/* ─── Player Card ─────────────────────────────────── */

function PlayerCard({
  player,
  viewerRole,
  onWhitelist,
  onRemove,
  onKick,
  index,
}: {
  player: { id: string; name: string; role: PlayerRole }
  viewerRole: PlayerRole
  onWhitelist: () => void
  onRemove: () => void
  onKick: () => void
  index: number
}) {
  const activeButtons = getActiveButtons(player.role)

  const wlCheck = canPerform(viewerRole, player.role, 'whitelist')
  const rmCheck = canPerform(viewerRole, player.role, 'remove')
  const kickCheck = canPerform(viewerRole, player.role, 'kick')

  return (
    <motion.div
      className="relative rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 0.25, delay: index * 0.03 }}
    >
      {/* Role dot - top right */}
      <div className="absolute top-3 right-3 z-10">
        <div className={`w-2.5 h-2.5 rounded-full ${roleDotColor(player.role)}`} />
      </div>

      {/* Player info */}
      <div className="flex items-center gap-3 p-4 pb-3">
        {/* Headshot */}
        <div className="w-10 h-10 rounded-full bg-neutral-800 border border-neutral-700/50 flex items-center justify-center flex-shrink-0">
          <span className="text-sm font-bold text-neutral-400">
            {player.name.charAt(0).toUpperCase()}
          </span>
        </div>

        {/* Name + Role */}
        <div className="min-w-0">
          <p className="text-[13px] font-medium text-white truncate">{player.name}</p>
          <p className="text-[10px] font-medium text-neutral-600">
            {roleLabel(player.role)}
          </p>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex gap-1.5 px-4 pb-3">
        <ActionButton
          label="Whitelist"
          active={activeButtons.whitelist && wlCheck.allowed}
          onClick={onWhitelist}
        />
        <ActionButton
          label="Remove"
          active={activeButtons.remove && rmCheck.allowed}
          onClick={onRemove}
        />
        <ActionButton
          label="Kick"
          active={activeButtons.kick && kickCheck.allowed}
          onClick={onKick}
        />
      </div>
    </motion.div>
  )
}

function ActionButton({
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
      className={`flex-1 py-1.5 rounded-lg border text-[11px] font-medium transition-colors duration-150 cursor-pointer ${
        active
          ? 'bg-neutral-800/40 border-neutral-700 text-neutral-200 hover:bg-neutral-700/40'
          : 'bg-neutral-900/20 border-neutral-800/40 text-neutral-700'
      }`}
      onClick={onClick}
      disabled={!active}
    >
      {label}
    </button>
  )
}
