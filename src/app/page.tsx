'use client'

import { AnimatePresence } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { LandingPage } from '@/components/blur/LandingPage'
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
              {activePanel === 'group' && <GroupPanel key="group" />}
              {activePanel === 'customisation' && <CustomisationPanel key="customisation" />}
              {activePanel === 'info' && <InfoPanel key="info" />}
              {activePanel === 'effect' && <EffectPanel key="effect" />}
              {activePanel === 'hub' && <HubPanel key="hub" />}
              {activePanel === 'keybind' && <KeybindPanel key="keybind" />}
              {activePanel === 'timecode' && <TimecodePanel key="timecode" />}
            </AnimatePresence>
          </div>
        )}
      </AnimatePresence>
    </main>
  )
}
