'use client'

import { useEffect, useRef } from 'react'

export function BlurCarousel() {
  const containerRef = useRef<HTMLDivElement>(null)
  const rotationRef = useRef(0)
  const animRef = useRef<number>(0)
  const lastTimeRef = useRef(performance.now())
  const itemsRef = useRef<HTMLDivElement[]>([])

  const ITEM_COUNT = 5
  const RADIUS = 200
  const SPEED = 12

  useEffect(() => {
    lastTimeRef.current = performance.now()

    const animate = () => {
      const now = performance.now()
      const delta = (now - lastTimeRef.current) / 1000
      lastTimeRef.current = now

      rotationRef.current = (rotationRef.current + SPEED * delta) % 360

      itemsRef.current.forEach((el, i) => {
        if (!el) return

        const angleDeg = rotationRef.current + i * (360 / ITEM_COUNT)
        const angleRad = (angleDeg * Math.PI) / 180

        const x = Math.sin(angleRad) * RADIUS
        const z = Math.cos(angleRad) * RADIUS

        const facing = z / RADIUS
        const normalized = (facing + 1) / 2

        const opacity = 0.04 + normalized * 0.96
        const blurAmount = Math.max(0, (1 - facing) * 2.5)
        const textShadow = facing > 0.6
          ? `0 0 ${(facing - 0.6) * 80}px rgba(255,255,255,${(facing - 0.6) * 0.4})`
          : 'none'

        el.style.transform = `translateX(${x}px) translateZ(${z}px)`
        el.style.opacity = `${opacity}`
        el.style.filter = `blur(${blurAmount}px)`
        el.style.zIndex = `${Math.round(facing * 100) + 100}`
        el.style.textShadow = textShadow
      })

      animRef.current = requestAnimationFrame(animate)
    }

    animRef.current = requestAnimationFrame(animate)
    return () => cancelAnimationFrame(animRef.current)
  }, [ITEM_COUNT, RADIUS])

  return (
    <div
      ref={containerRef}
      className="relative flex items-center justify-center w-full h-[400px]"
      style={{ perspective: '800px' }}
    >
      <div
        className="relative w-full h-full flex items-center justify-center"
        style={{ transformStyle: 'preserve-3d' }}
      >
        {Array.from({ length: ITEM_COUNT }).map((_, i) => (
          <div
            key={i}
            ref={(el) => {
              if (el) itemsRef.current[i] = el
            }}
            className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 select-none"
            style={{ fontFamily: 'var(--font-inter)' }}
          >
            <span className="text-6xl font-bold text-white whitespace-nowrap tracking-tight">
              Blur
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
