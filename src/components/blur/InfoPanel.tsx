'use client'

import { motion } from 'framer-motion'

export function InfoPanel() {
  return (
    <motion.div
      className="h-full w-full flex flex-col p-4 pt-14"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4, delay: 0.15 }}
      style={{ fontFamily: 'var(--font-inter)' }}
    >
      <div className="flex-1 flex items-center justify-center">
        <div className="w-full max-w-md">
          {/* Header */}
          <div className="mb-8">
            <h2 className="text-lg font-semibold text-white">Blur Lasers</h2>
            <p className="text-[11px] text-neutral-600 mt-0.5">Panel Information</p>
          </div>

          {/* Credits */}
          <div className="rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden mb-6">
            <div className="h-8 flex items-center px-4 border-b border-neutral-800/50">
              <span className="text-[12px] font-semibold tracking-wide text-neutral-300">Credits</span>
            </div>
            <div className="p-4 space-y-4">
              <CreditRow label="Code written by" value="Johan" />
              <CreditRow label="UI made by" value="Johan" />
              <CreditRow label="Models made by" value="Johan" />
            </div>
          </div>

          {/* Version */}
          <div className="rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden mb-6">
            <div className="h-8 flex items-center px-4 border-b border-neutral-800/50">
              <span className="text-[12px] font-semibold tracking-wide text-neutral-300">Version</span>
            </div>
            <div className="p-4">
              <div className="flex items-center gap-3">
                <span className="text-[12px] font-medium text-neutral-300">v1.0.0</span>
                <span className="text-[10px] px-2 py-0.5 rounded-md bg-neutral-800/60 text-neutral-500">
                  Current
                </span>
              </div>
            </div>
          </div>

          {/* Bug Fixes */}
          <div className="rounded-xl border border-neutral-800/70 bg-neutral-950/50 overflow-hidden">
            <div className="h-8 flex items-center px-4 border-b border-neutral-800/50">
              <span className="text-[12px] font-semibold tracking-wide text-neutral-300">Bug Fixes</span>
            </div>
            <div className="p-6 flex flex-col items-center justify-center">
              <span className="text-[12px] text-neutral-600">No bugs found yet</span>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  )
}

function CreditRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-[11px] text-neutral-600">{label}</span>
      <span className="text-[12px] font-medium text-neutral-300">{value}</span>
    </div>
  )
}
