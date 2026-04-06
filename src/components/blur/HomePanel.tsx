'use client'

import { motion } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { BlurCarousel } from './BlurCarousel'
import { Home, Zap, Sparkles, Settings } from 'lucide-react'

const navIcons: Record<string, React.ReactNode> = {
  Home: <Home className="w-5 h-5" />,
  Lasers: <Zap className="w-5 h-5" />,
  Effects: <Sparkles className="w-5 h-5" />,
  Settings: <Settings className="w-5 h-5" />,
}

export function HomePanel() {
  const { activeNav, navItems, setActiveNav } = useBlurStore()

  return (
    <motion.div
      className="flex h-full"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.6, delay: 0.3 }}
    >
      {/* Left: Navigation Buttons */}
      <div
        className="w-56 flex-shrink-0 border-r border-neutral-800/60 pt-20 pb-6 px-3 flex flex-col gap-1"
        style={{ fontFamily: 'var(--font-inter)' }}
      >
        {navItems.map((item, index) => {
          const isActive = activeNav === item
          return (
            <motion.button
              key={item}
              className={`relative flex items-center gap-3 w-full px-4 py-3 rounded-lg text-left transition-colors duration-200 cursor-pointer ${
                isActive
                  ? 'bg-neutral-800/50 text-white'
                  : 'text-neutral-500 hover:text-neutral-300 hover:bg-neutral-800/20'
              }`}
              onClick={() => setActiveNav(item)}
              initial={{ opacity: 0, x: -16 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.3, delay: 0.4 + index * 0.08 }}
            >
              <span className={isActive ? 'text-white' : 'text-neutral-600'}>
                {navIcons[item]}
              </span>
              <span className="text-sm font-medium">{item}</span>
              {/* Active indicator bar */}
              {isActive && (
                <motion.div
                  className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-6 bg-white rounded-r-full"
                  layoutId="sidebar-indicator"
                  transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                />
              )}
            </motion.button>
          )
        })}

        {/* Bottom info */}
        <div className="mt-auto px-4">
          <div className="text-[11px] text-neutral-700">
            <p>Blur Lasers</p>
            <p className="mt-0.5">Panel v1.0.0</p>
          </div>
        </div>
      </div>

      {/* Right: Content Area */}
      <div className="flex-1 flex items-center justify-center pt-14 pb-6">
        <BlurCarousel />
      </div>
    </motion.div>
  )
}
