'use client'

import { motion } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'

export function LandingPage() {
  const enterPanel = useBlurStore((s) => s.enterPanel)

  return (
    <motion.div
      className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-black"
      exit={{ opacity: 0 }}
      transition={{ duration: 0.5 }}
    >
      {/* Blur Title */}
      <motion.h1
        className="text-[120px] font-bold tracking-tight text-white select-none"
        style={{ fontFamily: 'var(--font-inter)' }}
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.8, ease: 'easeOut' }}
      >
        Blur
      </motion.h1>

      {/* Enter Button */}
      <motion.button
        className="mt-8 px-8 py-3 text-sm font-medium tracking-wide border border-neutral-600 rounded-lg text-neutral-400 transition-all duration-200 cursor-pointer"
        style={{ fontFamily: 'var(--font-inter)' }}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.4 }}
        onClick={enterPanel}
        onMouseEnter={(e) => {
          e.currentTarget.style.color = '#ffffff'
          e.currentTarget.style.borderColor = '#ffffff'
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.color = '#a3a3a3'
          e.currentTarget.style.borderColor = '#525252'
        }}
      >
        Enter the Panel
      </motion.button>
    </motion.div>
  )
}
