'use client'

import { AnimatePresence, motion } from 'framer-motion'
import { useBlurStore } from '@/store/blur-store'
import { AlertTriangle, CheckCircle, XCircle } from 'lucide-react'

export function ToastContainer() {
  const { toasts, dismissToast } = useBlurStore()

  return (
    <div className="fixed top-16 right-4 z-[80] flex flex-col gap-2 pointer-events-none">
      <AnimatePresence>
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            className="pointer-events-auto flex items-center gap-2.5 px-4 py-2.5 rounded-lg border backdrop-blur-md shadow-lg cursor-pointer min-w-[260px]"
            initial={{ opacity: 0, x: 40, scale: 0.95 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, x: 40, scale: 0.95 }}
            transition={{ duration: 0.25 }}
            onClick={() => dismissToast(toast.id)}
            style={{
              fontFamily: 'var(--font-inter)',
              ...(toast.type === 'warning'
                ? { background: 'rgba(120,53,15,0.15)', borderColor: 'rgba(245,158,11,0.25)' }
                : toast.type === 'success'
                  ? { background: 'rgba(20,83,45,0.15)', borderColor: 'rgba(34,197,94,0.25)' }
                  : { background: 'rgba(127,29,29,0.15)', borderColor: 'rgba(239,68,68,0.25)' }),
            }}
          >
            {toast.type === 'warning' && <AlertTriangle className="w-4 h-4 text-amber-400 flex-shrink-0" />}
            {toast.type === 'success' && <CheckCircle className="w-4 h-4 text-emerald-400 flex-shrink-0" />}
            {toast.type === 'error' && <XCircle className="w-4 h-4 text-red-400 flex-shrink-0" />}

            <span className={`text-[12px] font-medium ${
              toast.type === 'warning' ? 'text-amber-300' :
              toast.type === 'success' ? 'text-emerald-300' :
              'text-red-300'
            }`}>
              {toast.text}
            </span>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}
