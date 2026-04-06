'use client'

import { motion } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { User } from 'lucide-react'

export function WelcomeScreen() {
  const username = useBlurStore((s) => s.username)

  return (
    <motion.div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.6 }}
    >
      <motion.div
        className="flex items-center gap-4 px-8 py-5 border border-neutral-700 rounded-xl bg-black/80 backdrop-blur-sm"
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5, delay: 0.2 }}
      >
        {/* Headshot */}
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-red-500/30 to-neutral-800 border border-neutral-600 flex items-center justify-center flex-shrink-0">
          <User className="w-6 h-6 text-neutral-400" />
        </div>

        {/* Welcome Text */}
        <motion.span
          className="text-xl font-medium text-white tracking-tight"
          style={{ fontFamily: 'var(--font-inter)' }}
          initial={{ opacity: 0, x: -10 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.4, delay: 0.5 }}
        >
          Welcome, {username}
        </motion.span>
      </motion.div>
    </motion.div>
  )
}
