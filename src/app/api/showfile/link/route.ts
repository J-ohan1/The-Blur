import { db } from '@/lib/db'
import { validateSession, extractBearerToken, isNotBlacklisted } from '@/lib/auth'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const authHeader = request.headers.get('authorization')
  const token = extractBearerToken(authHeader)
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const user = await validateSession(token)
  if (!user) {
    return NextResponse.json({ error: 'Invalid or expired session' }, { status: 401 })
  }

  if (!isNotBlacklisted(user)) {
    return NextResponse.json({ error: 'Forbidden: Blacklisted users cannot link showfiles' }, { status: 403 })
  }

  let body: Record<string, unknown>
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 422 })
  }

  const { showFileId, robloxPlaceId, robloxGameId } = body

  if (!showFileId || typeof showFileId !== 'string') {
    return NextResponse.json({ error: 'showFileId is required' }, { status: 422 })
  }

  if (!robloxPlaceId || typeof robloxPlaceId !== 'string') {
    return NextResponse.json({ error: 'robloxPlaceId is required' }, { status: 422 })
  }

  // Find the showfile
  const showfile = await db.showFile.findUnique({
    where: { id: showFileId },
  })

  if (!showfile) {
    return NextResponse.json({ error: 'Showfile not found' }, { status: 404 })
  }

  if (showfile.userId !== user.id) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  // Check if already linked and if the 3-day cooldown has not expired
  if (showfile.robloxPlaceId) {
    if (showfile.relinkableAt && new Date() < showfile.relinkableAt) {
      return NextResponse.json(
        {
          error: 'Showfile is already linked. Relink cooldown has not expired.',
          relinkableAt: showfile.relinkableAt,
        },
        { status: 409 }
      )
    }
    // If linked but no relinkableAt (legacy edge case), or cooldown has expired, allow relinking
  }

  // 3-day cooldown from now
  const now = new Date()
  const relinkableAt = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000)

  const updated = await db.showFile.update({
    where: { id: showFileId },
    data: {
      robloxPlaceId,
      robloxGameId: (robloxGameId as string) || null,
      linkedAt: now,
      relinkableAt,
    },
  })

  return NextResponse.json(updated)
}
