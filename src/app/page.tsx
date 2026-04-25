'use client'

import { AuthProvider, useAuth } from '@/contexts/AuthContext'
import { useBlurStore } from '@/store/blur-store'
import { LoginPage } from '@/components/blur/LoginPage'
import { ShowfilePanel } from '@/components/blur/ShowfilePanel'
import { WelcomeScreen } from '@/components/blur/WelcomeScreen'
import { NavBar } from '@/components/blur/NavBar'
import { HomePanel } from '@/components/blur/HomePanel'
import { ControlPanel } from '@/components/blur/ControlPanel'
import { PlayerPanel } from '@/components/blur/PlayerPanel'
import { GroupPanel } from '@/components/blur/GroupPanel'
import { CustomisationPanel } from '@/components/blur/CustomisationPanel'
import { InfoPanel } from '@/components/blur/InfoPanel'
import { EffectPanel } from '@/components/blur/EffectPanel'
import { HubPanel } from '@/components/blur/HubPanel'
import { KeybindPanel } from '@/components/blur/KeybindPanel'
import { TimecodePanel } from '@/components/blur/TimecodePanel'
import { ProfileDropdown } from '@/components/blur/ProfileDropdown'
import { EasterEggPopup } from '@/components/blur/EasterEggPopup'
import { ToastContainer } from '@/components/blur/ToastContainer'
import { Loader2 } from 'lucide-react'
import { AnimatePresence, motion } from 'framer-motion'
import { useEffect } from 'react'

function ActivePanel() {
  const activePanel = useBlurStore((s) => s.activePanel)
  const ShowfilePanelComponent = ShowfilePanel

  switch (activePanel) {
    case 'home': return <HomePanel />
    case 'control': return <ControlPanel />
    case 'player': return <PlayerPanel />
    case 'group': return <GroupPanel />
    case 'customisation': return <CustomisationPanel />
    case 'info': return <InfoPanel />
    case 'effect': return <EffectPanel />
    case 'hub': return <HubPanel />
    case 'keybind': return <KeybindPanel />
    case 'timecode': return <TimecodePanel />
    case 'showfile': return <ShowfilePanelComponent asPanel />
    default: return <HomePanel />
  }
}

function MainPanel() {
  const showProfileDropdown = useBlurStore((s) => s.showProfileDropdown)
  const showEasterEgg = useBlurStore((s) => s.showEasterEgg)
  const closeProfileDropdown = useBlurStore((s) => s.closeProfileDropdown)
  const hasUnsavedChanges = useBlurStore((s) => s.hasUnsavedChanges)

  // Warn before closing tab with unsaved changes
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (hasUnsavedChanges) {
        e.preventDefault()
        e.returnValue = ''
      }
    }
    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [hasUnsavedChanges])

  return (
    <div className="h-screen w-screen overflow-hidden bg-black flex flex-col">
      <NavBar />
      <div
        className="flex-1 overflow-y-auto pt-14 relative"
        onClick={() => showProfileDropdown && closeProfileDropdown()}
      >
        <AnimatePresence mode="wait">
          <motion.div
            key={useBlurStore.getState().activePanel}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.15 }}
            className="h-full"
          >
            <ActivePanel />
          </motion.div>
        </AnimatePresence>
      </div>
      {showProfileDropdown && <ProfileDropdown />}
      {showEasterEgg && <EasterEggPopup />}
      <ToastContainer />
    </div>
  )
}

function AppRouter() {
  const { user, isLoading } = useAuth()
  const phase = useBlurStore((s) => s.phase)

  // Show loading while auth is being validated
  if (isLoading) {
    return (
      <div className="fixed inset-0 bg-black flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="text-white text-2xl font-bold tracking-widest" style={{ textShadow: '0 0 20px rgba(255,255,255,0.3)' }}>BLUR</div>
          <Loader2 className="size-4 text-neutral-500 animate-spin" />
        </div>
      </div>
    )
  }

  // If user is logged in but phase is still 'login', advance to showfile
  if (user && phase === 'login') {
    const store = useBlurStore.getState()
    store.setPhase('showfile')
    // Also set the current user in the store
    store.setCurrentUser({
      id: user.id,
      name: user.displayName || user.robloxUsername || user.discordUsername || 'User',
      role: (user.role as any) || 'normal',
    })
  }

  return (
    <AnimatePresence mode="wait">
      {phase === 'login' && (
        <motion.div
          key="login"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.3 }}
        >
          <LoginPage />
        </motion.div>
      )}
      {phase === 'showfile' && (
        <motion.div
          key="showfile"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.3 }}
        >
          <ShowfilePanel />
        </motion.div>
      )}
      {phase === 'welcome' && (
        <motion.div
          key="welcome"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.3 }}
        >
          <WelcomeScreen />
        </motion.div>
      )}
      {phase === 'main' && <MainPanel />}
    </AnimatePresence>
  )
}

export default function Home() {
  return (
    <AuthProvider>
      <AppRouter />
    </AuthProvider>
  )
}
