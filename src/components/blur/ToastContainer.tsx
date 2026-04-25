'use client'

import { AnimatePresence, motion } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'

export function ToastContainer() {
  const { toasts, dismissToast } = useBlurStore()

  return (
    <div className="fixed top-16 right-4 z-[80] flex flex-col gap-2 pointer-events-none">
      <AnimatePresence>
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            className="pointer-events-auto flex items-center gap-2.5 px-4 py-2.5 rounded-lg border backdrop-blur-md shadow-lg cursor-pointer min-w-[260px] bg-neutral-950/90 border-neutral-800"
            initial={{ opacity: 0, x: 40, scale: 0.95 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, x: 40, scale: 0.95 }}
            transition={{ duration: 0.25 }}
            onClick={() => dismissToast(toast.id)}
          >
            <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${
              toast.type === 'warning' ? 'bg-neutral-400' :
              toast.type === 'success' ? 'bg-white' :
              'bg-neutral-500'
            }`} />
            <span className="text-[12px] font-medium text-neutral-300">
              {toast.text}
            </span>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}
