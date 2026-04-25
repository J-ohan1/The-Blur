import { db } from '@/lib/db'
import { validateSession, extractBearerToken, isStaffOrWhitelisted } from '@/lib/auth'
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

  // Only staff/whitelisted can view whitelist
  if (!isStaffOrWhitelisted(user)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const users = await db.user.findMany({
    where: {
      OR: [
        { role: 'staff' },
        { role: 'whitelisted' },
        { role: 'temp_whitelisted' },
      ],
    },
    select: {
      id: true,
      robloxUsername: true,
      discordUsername: true,
      role: true,
      tempWhitelistedBy: true,
      tempWhitelistExpiresAt: true,
      createdAt: true,
    },
    orderBy: { createdAt: 'desc' },
  })

  return NextResponse.json(users)
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

  // Only whitelisted/staff can add to whitelist
  if (!isStaffOrWhitelisted(user)) {
    return NextResponse.json({ error: 'Forbidden: Only whitelisted or staff users can manage the whitelist' }, { status: 403 })
  }

  let body: Record<string, unknown>
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 422 })
  }

  const { userId, role } = body

  if (!userId || typeof userId !== 'string') {
    return NextResponse.json({ error: 'userId is required' }, { status: 422 })
  }

  if (!role || typeof role !== 'string') {
    return NextResponse.json({ error: 'role is required' }, { status: 422 })
  }

  if (role !== 'whitelisted' && role !== 'temp_whitelisted') {
    return NextResponse.json({ error: 'role must be "whitelisted" or "temp_whitelisted"' }, { status: 422 })
  }

  // Only staff can grant permanent whitelist
  if (role === 'whitelisted' && user.role !== 'staff') {
    return NextResponse.json({ error: 'Forbidden: Only staff can grant permanent whitelist' }, { status: 403 })
  }

  const targetUser = await db.user.findUnique({
    where: { id: userId },
  })

  if (!targetUser) {
    return NextResponse.json({ error: 'User not found' }, { status: 404 })
  }

  const updateData: Record<string, unknown> = {
    role,
  }

  if (role === 'temp_whitelisted') {
    updateData.tempWhitelistedBy = user.id
    updateData.tempWhitelistExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000) // 24h default
  } else {
    updateData.tempWhitelistedBy = null
    updateData.tempWhitelistExpiresAt = null
  }

  const updatedUser = await db.user.update({
    where: { id: userId },
    data: updateData,
  })

  return NextResponse.json(updatedUser)
}
