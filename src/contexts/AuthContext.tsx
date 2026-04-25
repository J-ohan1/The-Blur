'use client'

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'

interface User {
  id: string
  discordId: string | null
  robloxId: string | null
  robloxUsername: string | null
  discordUsername: string | null
  discordAvatar: string | null
  displayPreference: string
  role: string
  displayName: string
}

interface AuthContextType {
  user: User | null
  token: string | null
  isLoading: boolean
  loginWithCode: (code: string) => Promise<{ success: boolean; error?: string; requiresVerification?: boolean }>
  verifyWithCode: (code: string) => Promise<{ success: boolean; error?: string }>
  logout: () => void
  updateDisplayPreference: (pref: string) => Promise<void>
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [token, setToken] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(() => {
    if (typeof window === 'undefined') return true
    return !!localStorage.getItem('blur_token')
  })

  // On mount, check for existing session
  useEffect(() => {
    const savedToken = localStorage.getItem('blur_token')
    if (!savedToken) return
    let cancelled = false
    fetch('/api/auth/session', {
      headers: { Authorization: `Bearer ${savedToken}` }
    })
      .then(async (res) => {
        if (cancelled) return
        if (res.ok) {
          const data = await res.json()
          setUser(data.user)
          setToken(savedToken)
        } else {
          localStorage.removeItem('blur_token')
          setToken(null)
          setUser(null)
        }
      })
      .catch(() => {
        if (cancelled) return
        localStorage.removeItem('blur_token')
        setToken(null)
        setUser(null)
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false)
      })
    return () => { cancelled = true }
  }, [])

  const loginWithCode = useCallback(async (code: string) => {
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code })
      })
      const data = await res.json()
      if (res.ok) {
        setUser(data.user)
        setToken(data.token)
        localStorage.setItem('blur_token', data.token)
        return { success: true }
      }
      return { success: false, error: data.error || 'Invalid code' }
    } catch {
      return { success: false, error: 'Network error' }
    }
  }, [])

  const verifyWithCode = useCallback(async (code: string) => {
    try {
      const res = await fetch('/api/auth/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code })
      })
      const data = await res.json()
      if (res.ok) {
        setUser(data.user)
        setToken(data.token)
        localStorage.setItem('blur_token', data.token)
        return { success: true }
      }
      return { success: false, error: data.error || 'Invalid code' }
    } catch {
      return { success: false, error: 'Network error' }
    }
  }, [])

  const logout = useCallback(() => {
    if (token) {
      fetch('/api/auth/session', {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` }
      }).catch(() => {})
    }
    setUser(null)
    setToken(null)
    localStorage.removeItem('blur_token')
  }, [token])

  const updateDisplayPreference = useCallback(async (pref: string) => {
    if (!token) return
    try {
      const res = await fetch('/api/auth/me', {
        method: 'PUT',
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ displayPreference: pref })
      })
      if (res.ok) {
        const data = await res.json()
        setUser(data.user)
      }
    } catch {}
  }, [token])

  const refreshUser = useCallback(async () => {
    if (!token) return
    try {
      const res = await fetch('/api/auth/session', {
        headers: { Authorization: `Bearer ${token}` }
      })
      if (res.ok) {
        const data = await res.json()
        setUser(data.user)
      }
    } catch {}
  }, [token])

  return (
    <AuthContext.Provider value={{ user, token, isLoading, loginWithCode, verifyWithCode, logout, updateDisplayPreference, refreshUser }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
