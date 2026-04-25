'use client'

import { useEffect } from 'react'
import { motion } from 'framer-motion'
import { useAuth } from '@/contexts/AuthContext'
import { useBlurStore } from '@/store/blur-store'

export function WelcomeScreen() {
  const { user } = useAuth()
  const setPhase = useBlurStore((s) => s.setPhase)

  const displayName = user
    ? user.displayPreference === 'roblox'
      ? user.robloxUsername || user.displayName
      : user.displayPreference === 'discord'
        ? user.discordUsername || user.displayName
        : user.displayName
    : ''

  useEffect(() => {
    const timer = setTimeout(() => {
      setPhase('main')
    }, 2500)
    return () => clearTimeout(timer)
  }, [setPhase])

  return (
    <div className="fixed inset-0 bg-black flex items-center justify-center">
      <motion.div
        initial={{ opacity: 0, scale: 0.92 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6, ease: 'easeOut' }}
        className="flex flex-col items-center gap-3"
      >
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="text-neutral-500 text-sm tracking-wide"
        >
          Welcome,
        </motion.p>
        <motion.h1
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4, ease: 'easeOut' }}
          className="text-3xl font-bold text-white tracking-tight"
          style={{ textShadow: '0 0 24px rgba(255,255,255,0.12)' }}
        >
          {displayName}
        </motion.h1>
      </motion.div>
    </div>
  )
}
