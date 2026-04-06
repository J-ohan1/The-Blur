'use client'

import { useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { ProfileDropdown } from './ProfileDropdown'
import { EasterEggPopup } from './EasterEggPopup'

export function NavBar() {
  const currentUser = useBlurStore((s) => s.currentUser)
  const activePanel = useBlurStore((s) => s.activePanel)
  const showProfileDropdown = useBlurStore((s) => s.showProfileDropdown)
  const showEasterEgg = useBlurStore((s) => s.showEasterEgg)
  const groups = useBlurStore((s) => s.groups)
  const setActivePanel = useBlurStore((s) => s.setActivePanel)
  const toggleProfileDropdown = useBlurStore((s) => s.toggleProfileDropdown)
  const checkEasterEgg = useBlurStore((s) => s.checkEasterEgg)
  const closeEasterEgg = useBlurStore((s) => s.closeEasterEgg)
  const closeProfileDropdown = useBlurStore((s) => s.closeProfileDropdown)

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

  const navButtons: { label: string; key: 'home' | 'control' | 'player' | 'group' | 'customisation' }[] = [
    { label: 'Home', key: 'home' },
    { label: 'Control', key: 'control' },
    { label: 'Player', key: 'player' },
    { label: 'Group', key: 'group' },
    { label: 'Customisation', key: 'customisation' },
  ]

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

        {/* Center: Nav buttons */}
        <div className="absolute left-1/2 -translate-x-1/2 flex items-center gap-1">
          {navButtons.map((item) => {
            const isActive = activePanel === item.key
            const needsBlink = item.key === 'group' && groups.length === 0
            return (
              <button
                key={item.key}
                className="relative px-4 py-2 text-[13px] font-medium text-neutral-500 hover:text-white transition-colors duration-200 cursor-pointer"
                onClick={() => setActivePanel(item.key)}
              >
                {item.label}
                {isActive && (
                  <motion.div
                    className="absolute bottom-0 left-2 right-2 h-[2px] bg-white rounded-full"
                    layoutId="nav-underline"
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}
                {/* Blink dot when no groups exist */}
                {needsBlink && !isActive && (
                  <motion.span
                    className="absolute top-1 right-1 w-1.5 h-1.5 rounded-full bg-white"
                    animate={{ opacity: [1, 0, 1] }}
                    transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
                  />
                )}
              </button>
            )
          })}
        </div>

        {/* Right: Headshot */}
        <div className="relative">
          <motion.button
            className="w-7 h-7 rounded-full bg-neutral-800 border border-neutral-700 flex items-center justify-center hover:border-neutral-500 transition-colors duration-200 cursor-pointer"
            onClick={toggleProfileDropdown}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <span className="text-[10px] font-bold text-neutral-400">
              {currentUser.name.charAt(0).toUpperCase()}
            </span>
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
