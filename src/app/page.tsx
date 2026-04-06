'use client'

import { AnimatePresence } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { LandingPage } from '@/components/blur/LandingPage'
import { WelcomeScreen } from '@/components/blur/WelcomeScreen'
import { NavBar } from '@/components/blur/NavBar'
import { HomePanel } from '@/components/blur/HomePanel'
import { ControlPanel } from '@/components/blur/ControlPanel'
import { PlayerPanel } from '@/components/blur/PlayerPanel'
import { ToastContainer } from '@/components/blur/ToastContainer'

export default function Page() {
  const { phase, activePanel } = useBlurStore()

  return (
    <main className="h-screen w-screen overflow-hidden bg-black">
      <AnimatePresence mode="wait">
        {phase === 'landing' && <LandingPage key="landing" />}
        {phase === 'welcome' && <WelcomeScreen key="welcome" />}

        {phase === 'main' && (
          <div key="main" className="h-full w-full">
            <NavBar />
            <ToastContainer />
            <AnimatePresence mode="wait">
              {activePanel === 'home' && <HomePanel key="home" />}
              {activePanel === 'control' && <ControlPanel key="control" />}
              {activePanel === 'player' && <PlayerPanel key="player" />}
            </AnimatePresence>
          </div>
        )}
      </AnimatePresence>
    </main>
  )
}
