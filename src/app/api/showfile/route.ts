import { db } from '@/lib/db'
import { validateSession, extractBearerToken, isNotBlacklisted } from '@/lib/auth'
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

  const showfiles = await db.showFile.findMany({
    where: { userId: user.id },
    select: {
      id: true,
      name: true,
      description: true,
      lastSavedAt: true,
      createdAt: true,
      updatedAt: true,
      robloxPlaceId: true,
    },
    orderBy: { updatedAt: 'desc' },
  })

  return NextResponse.json({ showfiles })
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

  if (!isNotBlacklisted(user)) {
    return NextResponse.json({ error: 'Forbidden: Blacklisted users cannot create showfiles' }, { status: 403 })
  }

  let body: Record<string, unknown>
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 422 })
  }

  const { name, description } = body

  if (!name || typeof name !== 'string') {
    return NextResponse.json({ error: 'Name is required' }, { status: 422 })
  }

  if (name.length > 70) {
    return NextResponse.json({ error: 'Name must be 70 characters or less' }, { status: 422 })
  }

  if (description !== undefined && description !== null && typeof description !== 'string') {
    return NextResponse.json({ error: 'Description must be a string' }, { status: 422 })
  }

  if (description && typeof description === 'string') {
    const wordCount = description.trim().split(/\s+/).filter(Boolean).length
    if (wordCount > 500) {
      return NextResponse.json({ error: 'Description must be 500 words or less' }, { status: 422 })
    }
  }

  // Check for unique name per user
  const existing = await db.showFile.findUnique({
    where: {
      userId_name: { userId: user.id, name },
    },
  })

  if (existing) {
    return NextResponse.json({ error: 'A showfile with this name already exists' }, { status: 409 })
  }

  const defaultData = JSON.stringify({
    groups: [],
    effects: [],
    positions: [],
    timecode: [],
  })

  const showfile = await db.showFile.create({
    data: {
      userId: user.id,
      name,
      description: description || null,
      data: defaultData,
    },
  })

  return NextResponse.json({ showfile }, { status: 201 })
}
