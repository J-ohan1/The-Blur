'use client'

import { AnimatePresence } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { LandingPage } from '@/components/blur/LandingPage'
import { WelcomeScreen } from '@/components/blur/WelcomeScreen'
import { NavBar } from '@/components/blur/NavBar'
import { HomePanel } from '@/components/blur/HomePanel'

export default function Page() {
  const phase = useBlurStore((s) => s.phase)

  return (
    <main className="h-screen w-screen overflow-hidden bg-black">
      <AnimatePresence mode="wait">
        {/* Phase 1: Landing */}
        {phase === 'landing' && <LandingPage key="landing" />}

        {/* Phase 2: Welcome transition */}
        {phase === 'welcome' && <WelcomeScreen key="welcome" />}

        {/* Phase 3: Main app */}
        {phase === 'main' && (
          <div key="main" className="h-full w-full">
            <NavBar />
            <HomePanel />
          </div>
        )}
      </AnimatePresence>
    </main>
  )
}
