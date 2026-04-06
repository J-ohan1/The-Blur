'use client'

import { motion } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { useEffect, useState } from 'react'
import { ShieldCheck, ShieldAlert, Clock, Keyboard } from 'lucide-react'

export function ProfileDropdown() {
  const {
    username,
    isWhitelisted,
    isTemporaryWhitelisted,
    getTimeSpent,
    timeSpent,
    updateTimeSpent,
  } = useBlurStore()

  const [time, setTime] = useState(getTimeSpent())

  // Update time every second
  useEffect(() => {
    const interval = setInterval(() => {
      updateTimeSpent()
      setTime(getTimeSpent())
    }, 1000)
    return () => clearInterval(interval)
  }, [updateTimeSpent, getTimeSpent])

  return (
    <motion.div
      className="fixed top-[60px] right-5 z-50 w-64 border border-neutral-800 rounded-xl bg-neutral-950/95 backdrop-blur-md p-4 shadow-2xl shadow-black/50"
      initial={{ opacity: 0, y: -8, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -8, scale: 0.96 }}
      transition={{ duration: 0.2 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* Username */}
      <div className="flex items-center gap-3 mb-3 pb-3 border-b border-neutral-800">
        <div className="w-9 h-9 rounded-full bg-gradient-to-br from-red-500/30 to-neutral-800 border border-neutral-700 flex items-center justify-center">
          <span className="text-xs font-semibold text-white">{username.charAt(0)}</span>
        </div>
        <span className="text-sm font-medium text-white">{username}</span>
      </div>

      {/* Whitelist Status */}
      <div className="mb-3">
        <div className="flex items-center gap-2 mb-2">
          {isWhitelisted ? (
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
          ) : isTemporaryWhitelisted ? (
            <ShieldAlert className="w-4 h-4 text-yellow-400" />
          ) : (
            <ShieldAlert className="w-4 h-4 text-neutral-500" />
          )}
          <span
            className={`text-xs font-medium ${
              isWhitelisted
                ? 'text-emerald-400'
                : isTemporaryWhitelisted
                  ? 'text-yellow-400'
                  : 'text-neutral-500'
            }`}
          >
            {isWhitelisted
              ? 'Whitelisted'
              : isTemporaryWhitelisted
                ? 'Temporary Whitelisted'
                : 'Not Whitelisted'}
          </span>
        </div>
      </div>

      {/* Time Spent */}
      <div className="mb-3 flex items-center gap-2">
        <Clock className="w-4 h-4 text-neutral-500" />
        <span className="text-xs text-neutral-400">Session Time</span>
        <span className="ml-auto text-xs font-mono text-neutral-300">{time}</span>
      </div>

      {/* User Defined */}
      <div className="pt-3 border-t border-neutral-800">
        <p className="text-[11px] text-neutral-500 mb-2 uppercase tracking-wider">User Defined</p>

        <div className="flex items-center gap-2 mb-2">
          <Keyboard className="w-4 h-4 text-neutral-500" />
          <span className="text-xs text-neutral-400">Keybinds</span>
          <span className="ml-auto text-xs font-medium text-white bg-neutral-800 px-2 py-0.5 rounded-md">
            10
          </span>
        </div>

        <button className="w-full text-left text-xs text-neutral-500 hover:text-neutral-300 transition-colors duration-150 mt-1 cursor-pointer">
          See all the Keybinds
        </button>
      </div>
    </motion.div>
  )
}
