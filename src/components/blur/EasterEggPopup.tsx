'use client'

import { motion } from 'framer-motion'
import { Heart } from 'lucide-react'

interface EasterEggPopupProps {
  onClose: () => void
}

export function EasterEggPopup({ onClose }: EasterEggPopupProps) {
  return (
    <>
      {/* Backdrop */}
      <motion.div
        className="fixed inset-0 z-[60] bg-black/60 backdrop-blur-sm"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      />

      {/* Popup */}
      <motion.div
        className="fixed top-1/2 left-1/2 z-[70] -translate-x-1/2 -translate-y-1/2 w-80 border border-neutral-700 rounded-xl bg-neutral-950 p-6 text-center shadow-2xl"
        initial={{ opacity: 0, scale: 0.85 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.85 }}
        transition={{ type: 'spring', stiffness: 300, damping: 25 }}
        style={{ fontFamily: 'var(--font-inter)' }}
      >
        {/* Glow dot */}
        <div className="mx-auto mb-4 w-10 h-10 rounded-full bg-gradient-to-br from-red-500/40 to-red-900/20 flex items-center justify-center">
          <div className="w-3 h-3 rounded-full bg-red-500 shadow-[0_0_12px_rgba(239,68,68,0.6)]" />
        </div>

        <h3 className="text-sm font-semibold text-white mb-2">
          Easter Egg Found!
        </h3>

        <p className="text-xs text-neutral-400 leading-relaxed mb-1">
          You found one of many easter eggs
        </p>

        <p className="text-xs text-neutral-400 flex items-center justify-center gap-1">
          Made with <Heart className="w-3 h-3 text-red-500 fill-red-500" /> by Johan
        </p>

        <motion.button
          className="mt-5 px-6 py-2 text-xs font-medium text-neutral-400 border border-neutral-700 rounded-lg hover:text-white hover:border-neutral-500 transition-all duration-200 cursor-pointer"
          onClick={onClose}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          Close
        </motion.button>
      </motion.div>
    </>
  )
}
