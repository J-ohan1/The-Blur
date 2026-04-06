'use client'

import { motion } from 'framer-motion'
import { BlurCarousel } from './BlurCarousel'

export function HomePanel() {
  return (
    <motion.div
      className="flex items-center justify-center h-full w-full pt-12"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.5, delay: 0.2 }}
    >
      <div className="flex flex-col items-center gap-6">
        <BlurCarousel />

        <motion.p
          className="text-[11px] text-neutral-700 tracking-widest uppercase"
          style={{ fontFamily: 'var(--font-inter)' }}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.6 }}
        >
          Blur Lasers &middot; Panel v1.0.0
        </motion.p>
      </div>
    </motion.div>
  )
}
