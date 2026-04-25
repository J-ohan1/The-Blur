import { db } from '@/lib/db'
import { validateSession, extractBearerToken, isNotBlacklisted } from '@/lib/auth'
import { NextResponse } from 'next/server'

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const authHeader = request.headers.get('authorization')
  const token = extractBearerToken(authHeader)
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const user = await validateSession(token)
  if (!user) {
    return NextResponse.json({ error: 'Invalid or expired session' }, { status: 401 })
  }

  const { id } = await params

  const showfile = await db.showFile.findUnique({
    where: { id },
  })

  if (!showfile) {
    return NextResponse.json({ error: 'Showfile not found' }, { status: 404 })
  }

  if (showfile.userId !== user.id) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  return NextResponse.json({ showfile })
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
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
    return NextResponse.json({ error: 'Forbidden: Blacklisted users cannot edit showfiles' }, { status: 403 })
  }

  const { id } = await params

  const showfile = await db.showFile.findUnique({
    where: { id },
  })

  if (!showfile) {
    return NextResponse.json({ error: 'Showfile not found' }, { status: 404 })
  }

  if (showfile.userId !== user.id) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  let body: Record<string, unknown>
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 422 })
  }

  const { name, description, data } = body

  const updateData: Record<string, unknown> = {}

  if (name !== undefined) {
    if (typeof name !== 'string' || name.length === 0) {
      return NextResponse.json({ error: 'Name must be a non-empty string' }, { status: 422 })
    }
    if (name.length > 70) {
      return NextResponse.json({ error: 'Name must be 70 characters or less' }, { status: 422 })
    }

    // Check unique constraint if name is being changed
    if (name !== showfile.name) {
      const existing = await db.showFile.findUnique({
        where: {
          userId_name: { userId: user.id, name },
        },
      })
      if (existing) {
        return NextResponse.json({ error: 'A showfile with this name already exists' }, { status: 409 })
      }
    }

    updateData.name = name
  }

  if (description !== undefined) {
    if (typeof description !== 'string') {
      return NextResponse.json({ error: 'Description must be a string' }, { status: 422 })
    }
    const wordCount = description.trim().split(/\s+/).filter(Boolean).length
    if (wordCount > 500) {
      return NextResponse.json({ error: 'Description must be 500 words or less' }, { status: 422 })
    }
    updateData.description = description || null
  }

  if (data !== undefined) {
    if (typeof data !== 'string') {
      // Try to stringify if it's an object
      if (typeof data === 'object') {
        updateData.data = JSON.stringify(data)
      } else {
        return NextResponse.json({ error: 'Data must be a JSON string or object' }, { status: 422 })
      }
    } else {
      updateData.data = data
    }
    updateData.lastSavedAt = new Date()
  }

  const updated = await db.showFile.update({
    where: { id },
    data: updateData,
  })

  return NextResponse.json({ showfile: updated })
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const authHeader = request.headers.get('authorization')
  const token = extractBearerToken(authHeader)
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const user = await validateSession(token)
  if (!user) {
    return NextResponse.json({ error: 'Invalid or expired session' }, { status: 401 })
  }

  const { id } = await params

  const showfile = await db.showFile.findUnique({
    where: { id },
  })

  if (!showfile) {
    return NextResponse.json({ error: 'Showfile not found' }, { status: 404 })
  }

  if (showfile.userId !== user.id) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  // Note: if linked to a Roblox place, we still allow deletion but inform the client
  const linkedInfo = showfile.robloxPlaceId
    ? { warning: 'Showfile was linked to a Roblox place. The link has been removed.' }
    : {}

  await db.showFile.delete({
    where: { id },
  })

  return NextResponse.json({ message: 'Showfile deleted', ...linkedInfo })
}
