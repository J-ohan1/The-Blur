'use client'

import { motion } from 'framer-motion'
import { useBlurStore, roleDotColor, roleLabel, type PlayerRole } from '@/store/blur-store'
import { useEffect, useState } from 'react'

export function ProfileDropdown() {
  const {
    currentUser,
    getTimeSpent,
    updateTimeSpent,
  } = useBlurStore()

  const [time, setTime] = useState(getTimeSpent())

  useEffect(() => {
    const interval = setInterval(() => {
      updateTimeSpent()
      setTime(getTimeSpent())
    }, 1000)
    return () => clearInterval(interval)
  }, [updateTimeSpent, getTimeSpent])

  return (
    <motion.div
      className="fixed top-[56px] right-5 z-50 w-64 border border-neutral-800 rounded-xl bg-neutral-950/95 backdrop-blur-md p-4 shadow-2xl shadow-black/50"
      initial={{ opacity: 0, y: -8, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -8, scale: 0.96 }}
      transition={{ duration: 0.2 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      {/* Username + Role Dot */}
      <div className="flex items-center gap-3 mb-3 pb-3 border-b border-neutral-800">
        <div className="relative">
          <div className="w-9 h-9 rounded-full bg-neutral-800 border border-neutral-700 flex items-center justify-center">
            <span className="text-sm font-bold text-neutral-300">
              {currentUser.name.charAt(0).toUpperCase()}
            </span>
          </div>
          {/* Role dot on avatar */}
          <div className={`absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-neutral-950 ${roleDotColor(currentUser.role)}`} />
        </div>
        <div>
          <span className="text-sm font-medium text-white block">{currentUser.name}</span>
          <span className="text-[10px] font-medium text-neutral-500">
            {roleLabel(currentUser.role)}
          </span>
        </div>
      </div>

      {/* Time Spent */}
      <div className="mb-3 flex items-center gap-2">
        <span className="text-xs text-neutral-500">Session</span>
        <span className="ml-auto text-xs font-mono text-neutral-300">{time}</span>
      </div>

      {/* User Defined */}
      <div className="pt-3 border-t border-neutral-800">
        <p className="text-[11px] text-neutral-600 mb-2 uppercase tracking-wider">User Defined</p>

        <div className="flex items-center gap-2 mb-2">
          <span className="text-xs text-neutral-500">Keybinds</span>
          <span className="ml-auto text-xs font-medium text-white bg-neutral-800 px-2 py-0.5 rounded-md">
            10
          </span>
        </div>

        <button className="w-full text-left text-xs text-neutral-600 hover:text-neutral-300 transition-colors duration-150 mt-1 cursor-pointer">
          See all the Keybinds
        </button>
      </div>
    </motion.div>
  )
}
