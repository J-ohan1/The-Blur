'use client'

import { useState, useCallback, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useAuth } from '@/contexts/AuthContext'
import { useBlurStore, type PlayerRole } from '@/store/blur-store'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { ScrollArea } from '@/components/ui/scroll-area'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import {
  FileText,
  Plus,
  X,
  Check,
  Pencil,
  Trash2,
  Download,
  Upload,
  Save,
  Loader2,
  FolderOpen,
} from 'lucide-react'

interface ShowFileItem {
  id: string
  name: string
  description: string | null
  lastSavedAt: string | null
  createdAt: string
  robloxPlaceId: string | null
}

/* ── Full-screen selection view (no active showfile) ──────────────── */

function ShowfileSelection({ onSelect, onCreateNew }: { onSelect: (id: string) => void; onCreateNew: () => void }) {
  const showFiles = useBlurStore((s) => s.showFiles)

  return (
    <div className="fixed inset-0 bg-black flex items-center justify-center">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: 'easeOut' }}
        className="w-full max-w-lg px-6"
      >
        <div className="flex flex-col items-center gap-6">
          <div className="flex items-center gap-2">
            <FolderOpen className="size-5 text-neutral-500" />
            <h2 className="text-lg font-semibold text-white">Select a Show File</h2>
          </div>

          {showFiles.length === 0 ? (
            <div className="text-neutral-600 text-sm text-center py-8">
              No show files found. Create one to get started.
            </div>
          ) : (
            <ScrollArea className="w-full max-h-[60vh]">
              <div className="flex flex-col gap-2 pr-3">
                {showFiles.map((file) => (
                  <button
                    key={file.id}
                    type="button"
                    onClick={() => onSelect(file.id)}
                    className="w-full text-left rounded-xl border border-neutral-800 bg-neutral-950 hover:border-neutral-600 hover:bg-neutral-900/50 transition-colors p-4 cursor-pointer group"
                  >
                    <div className="flex items-start gap-3">
                      <FileText className="size-4 text-neutral-500 mt-0.5 shrink-0" />
                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-medium text-white truncate">{file.name}</p>
                        {file.description && (
                          <p className="text-xs text-neutral-500 mt-1 line-clamp-2">{file.description}</p>
                        )}
                        <p className="text-[10px] text-neutral-600 mt-2">
                          {file.lastSavedAt
                            ? `Saved ${new Date(file.lastSavedAt).toLocaleDateString()}`
                            : `Created ${new Date(file.createdAt).toLocaleDateString()}`}
                        </p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </ScrollArea>
          )}

          <Button
            variant="outline"
            onClick={onCreateNew}
            className="w-full border-neutral-800 bg-neutral-950 hover:bg-neutral-900 hover:border-neutral-600 text-neutral-300 hover:text-white rounded-xl h-10"
          >
            <Plus className="size-4" />
            Create New Show File
          </Button>
        </div>
      </motion.div>
    </div>
  )
}

/* ── Create showfile form ──────────────────────────────────────────── */

function CreateShowfileForm({
  onCancel,
  onCreated,
}: {
  onCancel: () => void
  onCreated: (file: ShowFileItem) => void
}) {
  const token = useAuth().token
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const wordCount = description.trim() ? description.trim().split(/\s+/).length : 0

  const handleCreate = useCallback(async () => {
    const trimmed = name.trim()
    if (!trimmed) {
      setError('Name is required')
      return
    }
    if (trimmed.length > 70) {
      setError('Name must be 70 characters or less')
      return
    }
    if (wordCount > 500) {
      setError('Description must be 500 words or less')
      return
    }
    setLoading(true)
    setError(null)
    try {
      const res = await fetch('/api/showfile', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ name: trimmed, description: description.trim() || undefined }),
      })
      const data = await res.json()
      if (!res.ok) {
        setError(data.error || 'Failed to create show file')
        return
      }
      onCreated(data.showfile)
    } catch {
      setError('Network error')
    } finally {
      setLoading(false)
    }
  }, [name, description, wordCount, token, onCreated])

  return (
    <div className="fixed inset-0 bg-black flex items-center justify-center">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: 'easeOut' }}
        className="w-full max-w-md px-6"
      >
        <div className="rounded-xl border border-neutral-800 bg-neutral-950 p-6 flex flex-col gap-5">
          <h2 className="text-sm font-semibold text-white">Create New Show File</h2>

          {/* Name */}
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center justify-between">
              <label className="text-xs text-neutral-400">Name</label>
              <span className="text-[10px] text-neutral-600">{name.length}/70</span>
            </div>
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              maxLength={70}
              placeholder="My laser show"
              className="h-9 border-neutral-800 bg-neutral-950 text-white text-sm placeholder:text-neutral-700 focus-visible:border-neutral-500 focus-visible:ring-neutral-500/30"
            />
          </div>

          {/* Description */}
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center justify-between">
              <label className="text-xs text-neutral-400">Description (optional)</label>
              <span className="text-[10px] text-neutral-600">{wordCount}/500 words</span>
            </div>
            <Textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Describe your show file..."
              className="min-h-20 border-neutral-800 bg-neutral-950 text-white text-sm placeholder:text-neutral-700 focus-visible:border-neutral-500 focus-visible:ring-neutral-500/30 resize-none"
            />
          </div>

          {error && <p className="text-red-400 text-xs">{error}</p>}

          <div className="flex items-center gap-2 justify-end">
            <Button
              variant="ghost"
              onClick={onCancel}
              className="text-neutral-400 hover:text-white text-xs h-8"
            >
              Cancel
            </Button>
            <Button
              onClick={handleCreate}
              disabled={loading || !name.trim()}
              className="bg-white text-black hover:bg-neutral-200 text-xs h-8 disabled:opacity-40"
            >
              {loading ? <Loader2 className="size-3.5 animate-spin" /> : 'Create'}
            </Button>
          </div>
        </div>
      </motion.div>
    </div>
  )
}

/* ── Inline rename input ──────────────────────────────────────────── */

function InlineRename({
  initial,
  onSave,
  onCancel,
}: {
  initial: string
  onSave: (name: string) => void
  onCancel: () => void
}) {
  const [value, setValue] = useState(initial)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
    inputRef.current?.select()
  }, [])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      onSave(value.trim())
    }
    if (e.key === 'Escape') {
      onCancel()
    }
  }

  return (
    <div className="flex items-center gap-1">
      <Input
        ref={inputRef}
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onKeyDown={handleKeyDown}
        maxLength={70}
        className="h-7 text-xs border-neutral-700 bg-neutral-900 text-white focus-visible:border-neutral-500 focus-visible:ring-neutral-500/30"
      />
      <button
        type="button"
        onClick={() => onSave(value.trim())}
        className="p-1 text-emerald-400 hover:text-emerald-300 transition-colors cursor-pointer"
      >
        <Check className="size-3.5" />
      </button>
      <button
        type="button"
        onClick={onCancel}
        className="p-1 text-neutral-500 hover:text-neutral-300 transition-colors cursor-pointer"
      >
        <X className="size-3.5" />
      </button>
    </div>
  )
}

/* ── Panel view (from navbar in main app) ─────────────────────────── */

function ShowfilePanelView({ onClose }: { onClose?: () => void }) {
  const { token } = useAuth()
  const store = useBlurStore()
  const { showFiles, activeShowFileId, setShowFiles, setActiveShowFile, setPhase, addToast } = store

  const [renamingId, setRenamingId] = useState<string | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [switchingId, setSwitchingId] = useState<string | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Fetch showfiles
  useEffect(() => {
    if (!token) return
    fetch('/api/showfile', {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data.showfiles)) {
          setShowFiles(data.showfiles)
        }
      })
      .catch(() => {})
  }, [token, setShowFiles])

  const handleSelect = useCallback(async (id: string) => {
    if (id === activeShowFileId) return
    setSwitchingId(id)
    try {
      const res = await fetch(`/api/showfile/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      })
      if (res.ok) {
        const data = await res.json()
        setActiveShowFile(id)
        if (onClose) onClose()
        addToast(`Switched to "${data.showfile?.name || 'Show File'}"`, 'success')
      }
    } catch {
      addToast('Failed to load show file', 'error')
    } finally {
      setSwitchingId(null)
    }
  }, [activeShowFileId, token, setActiveShowFile, onClose, addToast])

  const handleRename = useCallback(async (id: string, newName: string) => {
    if (!newName) {
      setRenamingId(null)
      return
    }
    try {
      const res = await fetch(`/api/showfile/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ name: newName }),
      })
      if (res.ok) {
        const data = await res.json()
        setShowFiles(showFiles.map((f) => (f.id === id ? { ...f, name: data.showfile?.name || newName } : f)))
        addToast('Renamed successfully', 'success')
      }
    } catch {
      addToast('Failed to rename', 'error')
    }
    setRenamingId(null)
  }, [token, showFiles, setShowFiles, addToast])

  const handleDelete = useCallback(async (id: string) => {
    try {
      const res = await fetch(`/api/showfile/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      })
      if (res.ok) {
        setShowFiles(showFiles.filter((f) => f.id !== id))
        if (id === activeShowFileId) {
          setActiveShowFile(null)
        }
        addToast('Show file deleted', 'success')
      }
    } catch {
      addToast('Failed to delete', 'error')
    }
    setDeleteId(null)
  }, [token, showFiles, activeShowFileId, setShowFiles, setActiveShowFile, addToast])

  const handleExport = useCallback(async (id: string) => {
    try {
      const res = await fetch(`/api/showfile/export/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      })
      if (res.ok) {
        const blob = await res.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        const disposition = res.headers.get('Content-Disposition')
        const match = disposition?.match(/filename="?(.+?)"?$/)
        a.download = match ? match[1] : 'showfile.blur'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
        addToast('Exported successfully', 'success')
      }
    } catch {
      addToast('Export failed', 'error')
    }
  }, [token, addToast])

  const handleImport = useCallback(async (file: File) => {
    if (!file.name.endsWith('.blur')) {
      addToast('Only .blur files are supported', 'error')
      return
    }
    const formData = new FormData()
    formData.append('file', file)
    try {
      const res = await fetch('/api/showfile/import', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: formData,
      })
      const data = await res.json()
      if (res.ok) {
        setShowFiles([...showFiles, data.showfile])
        addToast(`Imported "${data.showfile?.name || 'Show File'}"`, 'success')
      } else {
        addToast(data.error || 'Import failed', 'error')
      }
    } catch {
      addToast('Import failed', 'error')
    }
  }, [token, showFiles, setShowFiles, addToast])

  const handleSave = useCallback(async () => {
    if (!activeShowFileId || !token) return
    setSaving(true)
    try {
      const res = await fetch(`/api/showfile/${activeShowFileId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ data: {} }),
      })
      if (res.ok) {
        addToast('Show file saved', 'success')
        store.setHasUnsavedChanges(false)
      } else {
        addToast('Failed to save', 'error')
      }
    } catch {
      addToast('Failed to save', 'error')
    } finally {
      setSaving(false)
    }
  }, [activeShowFileId, token, store, addToast])

  const handleCreated = useCallback((file: ShowFileItem) => {
    setShowFiles([...showFiles, file])
    setShowCreate(false)
    addToast(`"${file.name}" created`, 'success')
  }, [showFiles, setShowFiles, addToast])

  return (
    <div className="flex flex-col gap-4 p-4 h-full">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-sm font-semibold text-white">Show Files</h2>
        <div className="flex items-center gap-1">
          {activeShowFileId && (
            <Button
              variant="ghost"
              size="sm"
              onClick={handleSave}
              disabled={saving}
              className="text-xs h-7 text-neutral-400 hover:text-white"
            >
              {saving ? <Loader2 className="size-3 animate-spin" /> : <Save className="size-3" />}
              Save
            </Button>
          )}
          <Button
            variant="ghost"
            size="sm"
            onClick={() => fileInputRef.current?.click()}
            className="text-xs h-7 text-neutral-400 hover:text-white"
          >
            <Upload className="size-3" />
            Import
          </Button>
          <input
            ref={fileInputRef}
            type="file"
            accept=".blur"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0]
              if (file) handleImport(file)
              e.target.value = ''
            }}
          />
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setShowCreate(true)}
            className="text-xs h-7 text-neutral-400 hover:text-white"
          >
            <Plus className="size-3" />
            New
          </Button>
        </div>
      </div>

      {/* File list */}
      <ScrollArea className="flex-1">
        <div className="flex flex-col gap-1.5 pr-2">
          {showFiles.length === 0 && (
            <p className="text-neutral-600 text-xs text-center py-8">No show files yet</p>
          )}
          {showFiles.map((file) => {
            const isActive = file.id === activeShowFileId
            const isRenaming = renamingId === file.id
            const isSwitching = switchingId === file.id

            return (
              <div
                key={file.id}
                className={`rounded-lg border p-3 transition-colors ${
                  isActive
                    ? 'border-neutral-600 bg-neutral-900/60'
                    : 'border-neutral-800 bg-neutral-950 hover:border-neutral-700'
                }`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 flex-1">
                    {isRenaming ? (
                      <InlineRename
                        initial={file.name}
                        onSave={(name) => handleRename(file.id, name)}
                        onCancel={() => setRenamingId(null)}
                      />
                    ) : (
                      <div className="flex items-center gap-2">
                        <p className="text-xs font-medium text-white truncate">{file.name}</p>
                        {isActive && (
                          <span className="text-[10px] text-emerald-400 shrink-0">active</span>
                        )}
                      </div>
                    )}
                    {!isRenaming && file.description && (
                      <p className="text-[10px] text-neutral-500 mt-0.5 line-clamp-1">{file.description}</p>
                    )}
                    {!isRenaming && (
                      <p className="text-[10px] text-neutral-600 mt-1">
                        {file.lastSavedAt
                          ? `Saved ${new Date(file.lastSavedAt).toLocaleDateString()}`
                          : `Created ${new Date(file.createdAt).toLocaleDateString()}`}
                      </p>
                    )}
                  </div>

                  {/* Actions */}
                  {!isRenaming && (
                    <div className="flex items-center gap-0.5 shrink-0">
                      {!isActive && (
                        <button
                          type="button"
                          onClick={() => handleSelect(file.id)}
                          disabled={isSwitching}
                          className="p-1 text-neutral-500 hover:text-white transition-colors cursor-pointer disabled:opacity-40"
                          title="Switch to this file"
                        >
                          {isSwitching ? (
                            <Loader2 className="size-3 animate-spin" />
                          ) : (
                            <FolderOpen className="size-3" />
                          )}
                        </button>
                      )}
                      <button
                        type="button"
                        onClick={() => setRenamingId(file.id)}
                        className="p-1 text-neutral-500 hover:text-white transition-colors cursor-pointer"
                        title="Rename"
                      >
                        <Pencil className="size-3" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleExport(file.id)}
                        className="p-1 text-neutral-500 hover:text-white transition-colors cursor-pointer"
                        title="Export"
                      >
                        <Download className="size-3" />
                      </button>
                      <button
                        type="button"
                        onClick={() => setDeleteId(file.id)}
                        className="p-1 text-neutral-500 hover:text-red-400 transition-colors cursor-pointer"
                        title="Delete"
                      >
                        <Trash2 className="size-3" />
                      </button>
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      </ScrollArea>

      {/* Create form dialog */}
      {showCreate && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="w-full max-w-md px-6"
          >
            <CreateShowfileForm
              onCancel={() => setShowCreate(false)}
              onCreated={handleCreated}
            />
          </motion.div>
        </div>
      )}

      {/* Delete confirmation */}
      <AlertDialog open={!!deleteId} onOpenChange={(open) => !open && setDeleteId(null)}>
        <AlertDialogContent className="bg-neutral-950 border-neutral-800">
          <AlertDialogHeader>
            <AlertDialogTitle className="text-white text-sm">Delete Show File</AlertDialogTitle>
            <AlertDialogDescription className="text-neutral-400 text-xs">
              This action cannot be undone. This will permanently delete this show file and all its data.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel className="border-neutral-800 bg-neutral-950 text-neutral-300 hover:bg-neutral-900 text-xs h-8">
              Cancel
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={() => deleteId && handleDelete(deleteId)}
              className="bg-red-600 text-white hover:bg-red-700 text-xs h-8"
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}

/* ── Full-screen showfile selection (internal) ────────────────────── */

function ShowfileFullscreen() {
  const { token, user } = useAuth()
  const { showFiles, setShowFiles, setActiveShowFile, setPhase, addToast, setCurrentUser } = useBlurStore()

  const [view, setView] = useState<'select' | 'create'>('select')

  // Fetch showfiles on mount
  useEffect(() => {
    if (!token) return
    fetch('/api/showfile', {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data.showfiles)) {
          setShowFiles(data.showfiles)
        }
      })
      .catch(() => {})
  }, [token, setShowFiles])

  const handleSelect = async (id: string) => {
    try {
      const res = await fetch(`/api/showfile/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      })
      if (res.ok) {
        setActiveShowFile(id)
        if (user) {
          setCurrentUser({
            id: user.id,
            name: user.displayName,
            role: (user.role === 'staff' ? 'staff'
              : user.role === 'hardcoded_whitelist' ? 'hardcoded_whitelist'
              : user.role === 'temp_whitelisted' ? 'temp_whitelist'
              : user.role === 'blacklisted' ? 'blacklisted'
              : 'normal') as PlayerRole,
          })
        }
        setPhase('welcome')
      } else {
        addToast('Failed to load show file', 'error')
      }
    } catch {
      addToast('Network error', 'error')
    }
  }

  const handleCreated = async (file: ShowFileItem) => {
    setShowFiles([...showFiles, file])
    setActiveShowFile(file.id)
    if (user) {
      setCurrentUser({
        id: user.id,
        name: user.displayName,
        role: (user.role === 'staff' ? 'staff'
          : user.role === 'hardcoded_whitelist' ? 'hardcoded_whitelist'
          : user.role === 'temp_whitelisted' ? 'temp_whitelist'
          : user.role === 'blacklisted' ? 'blacklisted'
          : 'normal') as PlayerRole,
      })
    }
    setPhase('welcome')
  }

  return (
    <AnimatePresence mode="wait">
      {view === 'select' ? (
        <motion.div key="select" exit={{ opacity: 0 }} transition={{ duration: 0.2 }}>
          <ShowfileSelection onSelect={handleSelect} onCreateNew={() => setView('create')} />
        </motion.div>
      ) : (
        <motion.div key="create" exit={{ opacity: 0 }} transition={{ duration: 0.2 }}>
          <CreateShowfileForm
            onCancel={() => setView('select')}
            onCreated={handleCreated}
          />
        </motion.div>
      )}
    </AnimatePresence>
  )
}

/* ── Main exported component ──────────────────────────────────────── */

export function ShowfilePanel({ asPanel, onClose }: { asPanel?: boolean; onClose?: () => void }) {
  if (asPanel) {
    return <ShowfilePanelView onClose={onClose} />
  }
  return <ShowfileFullscreen />
}
