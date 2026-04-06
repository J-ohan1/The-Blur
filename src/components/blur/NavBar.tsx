'use client'

import { useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { User } from 'lucide-react'
import { ProfileDropdown } from './ProfileDropdown'
import { EasterEggPopup } from './EasterEggPopup'

export function NavBar() {
  const {
    activePanel,
    showProfileDropdown,
    showEasterEgg,
    setActivePanel,
    toggleProfileDropdown,
    checkEasterEgg,
    closeEasterEgg,
    closeProfileDropdown,
  } = useBlurStore()

  const navRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (navRef.current && !navRef.current.contains(e.target as Node)) {
        closeProfileDropdown()
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [closeProfileDropdown])

  return (
    <>
      <motion.nav
        ref={navRef}
        className="fixed top-0 left-0 right-0 z-40 flex items-center justify-between px-6 h-12 bg-black/90 backdrop-blur-md border-b border-neutral-800/60"
        initial={{ y: '-100%' }}
        animate={{ y: 0 }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1], delay: 0.1 }}
        style={{ fontFamily: 'var(--font-inter)' }}
      >
        {/* Left: Brand */}
        <div className="flex items-center gap-3">
          <span className="text-white text-sm font-semibold tracking-tight cursor-default">
            Blur
          </span>
          <motion.button
            className="text-[11px] text-neutral-600 hover:text-neutral-400 transition-colors duration-150 cursor-pointer"
            onClick={checkEasterEgg}
          >
            Laser-version 1.0.0
          </motion.button>
        </div>

        {/* Center: Home + Control buttons */}
        <div className="absolute left-1/2 -translate-x-1/2 flex items-center gap-1">
          {(['Home', 'Control'] as const).map((item) => {
            const isActive = activePanel === item.toLowerCase()
            return (
              <button
                key={item}
                className="relative px-4 py-2 text-[13px] font-medium text-neutral-500 hover:text-white transition-colors duration-200 cursor-pointer"
                onClick={() => setActivePanel(item.toLowerCase() as 'home' | 'control')}
              >
                {item}
                {isActive && (
                  <motion.div
                    className="absolute bottom-0 left-2 right-2 h-[2px] bg-white rounded-full"
                    layoutId="nav-underline"
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}
              </button>
            )
          })}
        </div>

        {/* Right: Headshot */}
        <div className="relative">
          <motion.button
            className="w-7 h-7 rounded-full bg-gradient-to-br from-red-500/30 to-neutral-800 border border-neutral-700 flex items-center justify-center hover:border-neutral-500 transition-colors duration-200 cursor-pointer"
            onClick={toggleProfileDropdown}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <User className="w-3.5 h-3.5 text-neutral-400" />
          </motion.button>

          {showProfileDropdown && (
            <motion.div
              className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-0 h-0 border-l-[5px] border-r-[5px] border-t-[5px] border-transparent border-t-neutral-800 z-10"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
            />
          )}
        </div>
      </motion.nav>

      <AnimatePresence>
        {showProfileDropdown && <ProfileDropdown />}
      </AnimatePresence>
      <AnimatePresence>
        {showEasterEgg && <EasterEggPopup onClose={closeEasterEgg} />}
      </AnimatePresence>
    </>
  )
}
