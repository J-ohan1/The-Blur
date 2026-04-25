import { db } from '@/lib/db'
import { validateSession, extractBearerToken, isStaffOrWhitelisted, isNotBlacklisted } from '@/lib/auth'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const authHeader = request.headers.get('authorization')
  const token = extractBearerToken(authHeader)
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const user = await validateSession(token)
  if (!user) {
    return NextResponse.json({ error: 'Invalid or expired session' }, { status: 401 })
  }

  // Only staff/whitelisted can view blacklist
  if (!isStaffOrWhitelisted(user)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const entries = await db.blacklistEntry.findMany({
    orderBy: { createdAt: 'desc' },
  })

  return NextResponse.json(entries)
}

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

  if (!isStaffOrWhitelisted(user)) {
    return NextResponse.json({ error: 'Forbidden: Only whitelisted or staff users can add to blacklist' }, { status: 403 })
  }

  let body: Record<string, unknown>
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 422 })
  }

  const { robloxUsername, robloxId, reason } = body

  if (!robloxUsername || typeof robloxUsername !== 'string') {
    return NextResponse.json({ error: 'robloxUsername is required' }, { status: 422 })
  }

  // Check for duplicate
  const existing = await db.blacklistEntry.findUnique({
    where: { robloxUsername },
  })

  if (existing) {
    return NextResponse.json({ error: 'User is already blacklisted' }, { status: 409 })
  }

  const entry = await db.blacklistEntry.create({
    data: {
      robloxUsername,
      robloxId: (robloxId as string) || null,
      reason: (reason as string) || null,
      addedBy: user.id,
    },
  })

  // Also update the user's role to blacklisted if they exist
  const targetUser = await db.user.findUnique({ where: { robloxUsername } })
  if (targetUser) {
    await db.user.update({
      where: { id: targetUser.id },
      data: { role: 'blacklisted' },
    })
  }

  return NextResponse.json(entry, { status: 201 })
}

export async function DELETE(request: Request) {
  const authHeader = request.headers.get('authorization')
  const token = extractBearerToken(authHeader)
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const user = await validateSession(token)
  if (!user) {
    return NextResponse.json({ error: 'Invalid or expired session' }, { status: 401 })
  }

  // Only staff can remove from blacklist
  if (user.role !== 'staff') {
    return NextResponse.json({ error: 'Forbidden: Only staff can remove from blacklist' }, { status: 403 })
  }

  let body: Record<string, unknown>
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 422 })
  }

  const { id, robloxUsername } = body

  if (!id && !robloxUsername) {
    return NextResponse.json({ error: 'id or robloxUsername is required' }, { status: 422 })
  }

  let entry

  if (id && typeof id === 'string') {
    entry = await db.blacklistEntry.findUnique({
      where: { id },
    })
  } else if (robloxUsername && typeof robloxUsername === 'string') {
    entry = await db.blacklistEntry.findUnique({
      where: { robloxUsername },
    })
  }

  if (!entry) {
    return NextResponse.json({ error: 'Blacklist entry not found' }, { status: 404 })
  }

  await db.blacklistEntry.delete({
    where: { id: entry.id },
  })

  // Restore the user's role to normal if they exist
  const targetUser = await db.user.findUnique({ where: { robloxUsername: entry.robloxUsername } })
  if (targetUser && targetUser.role === 'blacklisted') {
    await db.user.update({
      where: { id: targetUser.id },
      data: { role: 'normal' },
    })
  }

  return NextResponse.json({ message: 'User removed from blacklist' })
}
