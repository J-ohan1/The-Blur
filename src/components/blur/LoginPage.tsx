'use client'

import { useState, useCallback } from 'react'
import { motion } from 'framer-motion'
import { useAuth } from '@/contexts/AuthContext'
import { useBlurStore } from '@/store/blur-store'
import { InputOTP, InputOTPGroup, InputOTPSlot, InputOTPSeparator } from '@/components/ui/input-otp'
import { Button } from '@/components/ui/button'
import { Loader2, ArrowRight, Gamepad2 } from 'lucide-react'

export function LoginPage() {
  const { loginWithCode, verifyWithCode } = useAuth()
  const setPhase = useBlurStore((s) => s.setPhase)
  const [code, setCode] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [mode, setMode] = useState<'login' | 'verify'>('login')

  const handleSubmit = useCallback(async () => {
    if (code.length !== 6) {
      setError('Code must be 6 characters')
      return
    }
    setLoading(true)
    setError(null)

    const result = mode === 'login'
      ? await loginWithCode(code)
      : await verifyWithCode(code)

    if (result.success) {
      setPhase('showfile')
    } else {
      setError(result.error || 'Invalid code')
    }
    setLoading(false)
  }, [code, mode, loginWithCode, verifyWithCode, setPhase])

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && code.length === 6 && !loading) {
      handleSubmit()
    }
  }, [code, loading, handleSubmit])

  const toggleMode = useCallback(() => {
    setMode((m) => (m === 'login' ? 'verify' : 'login'))
    setCode('')
    setError(null)
  }, [])

  return (
    <div className="fixed inset-0 bg-black flex items-center justify-center">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: 'easeOut' }}
        className="w-full max-w-sm px-6"
      >
        <div className="flex flex-col items-center gap-8">
          {/* Title */}
          <div className="flex flex-col items-center gap-2">
            <h1
              className="text-4xl font-bold text-white tracking-widest select-none"
              style={{ textShadow: '0 0 20px rgba(255,255,255,0.15)' }}
            >
              BLUR
            </h1>
            <p className="text-neutral-500 text-xs tracking-wider uppercase">
              {mode === 'login' ? 'Laser Control Panel' : 'Verify with Roblox'}
            </p>
          </div>

          {/* OTP Input */}
          <div className="w-full flex flex-col items-center gap-4" onKeyDown={handleKeyDown}>
            <InputOTP
              maxLength={6}
              value={code}
              onChange={setCode}
              containerClassName="gap-2"
            >
              <InputOTPGroup>
                <InputOTPSlot
                  index={0}
                  className="h-12 w-12 border-neutral-800 bg-neutral-950 text-white text-lg font-mono data-[active=true]:border-neutral-500 data-[active=true]:ring-neutral-500/30"
                />
                <InputOTPSlot
                  index={1}
                  className="h-12 w-12 border-neutral-800 bg-neutral-950 text-white text-lg font-mono data-[active=true]:border-neutral-500 data-[active=true]:ring-neutral-500/30"
                />
                <InputOTPSlot
                  index={2}
                  className="h-12 w-12 border-neutral-800 bg-neutral-950 text-white text-lg font-mono data-[active=true]:border-neutral-500 data-[active=true]:ring-neutral-500/30"
                />
              </InputOTPGroup>
              <InputOTPSeparator className="text-neutral-700" />
              <InputOTPGroup>
                <InputOTPSlot
                  index={3}
                  className="h-12 w-12 border-neutral-800 bg-neutral-950 text-white text-lg font-mono data-[active=true]:border-neutral-500 data-[active=true]:ring-neutral-500/30"
                />
                <InputOTPSlot
                  index={4}
                  className="h-12 w-12 border-neutral-800 bg-neutral-950 text-white text-lg font-mono data-[active=true]:border-neutral-500 data-[active=true]:ring-neutral-500/30"
                />
                <InputOTPSlot
                  index={5}
                  className="h-12 w-12 border-neutral-800 bg-neutral-950 text-white text-lg font-mono data-[active=true]:border-neutral-500 data-[active=true]:ring-neutral-500/30"
                />
              </InputOTPGroup>
            </InputOTP>

            {/* Error message */}
            {error && (
              <motion.p
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-red-400 text-xs"
              >
                {error}
              </motion.p>
            )}

            {/* Submit button */}
            <Button
              onClick={handleSubmit}
              disabled={loading || code.length !== 6}
              className="w-full h-10 bg-white text-black hover:bg-neutral-200 disabled:opacity-40 disabled:cursor-not-allowed rounded-lg font-medium text-sm"
            >
              {loading ? (
                <Loader2 className="size-4 animate-spin" />
              ) : (
                <>
                  Enter
                  <ArrowRight className="size-3.5" />
                </>
              )}
            </Button>
          </div>

          {/* Mode toggle and helper */}
          <div className="flex flex-col items-center gap-3">
            <p className="text-neutral-600 text-xs text-center leading-relaxed">
              {mode === 'login'
                ? 'Get your code from the Discord bot using /login'
                : 'Enter the code shown in-game'}
            </p>
            <button
              type="button"
              onClick={toggleMode}
              className="flex items-center gap-1.5 text-neutral-500 hover:text-neutral-300 transition-colors text-xs cursor-pointer"
            >
              <Gamepad2 className="size-3" />
              {mode === 'login'
                ? 'Or verify with Roblox code'
                : 'Or login with Discord code'}
            </button>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
