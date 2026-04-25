import { db } from '@/lib/db'
import { validateSession, extractBearerToken, isStaffOrWhitelisted } from '@/lib/auth'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const search = searchParams.get('search') || ''
  const type = searchParams.get('type') || ''
  const sort = searchParams.get('sort') || 'newest'
  const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10))
  const limit = Math.min(50, Math.max(1, parseInt(searchParams.get('limit') || '20', 10)))

  const where: Record<string, unknown> = {}

  if (search) {
    where.OR = [
      { name: { contains: search } },
      { tags: { contains: search } },
      { authorName: { contains: search } },
    ]
  }

  if (type) {
    where.type = type
  }

  const orderBy = sort === 'downloads'
    ? { downloads: 'desc' as const }
    : { createdAt: 'desc' as const }

  const [effects, total] = await Promise.all([
    db.hubEffect.findMany({
      where,
      orderBy,
      skip: (page - 1) * limit,
      take: limit,
    }),
    db.hubEffect.count({ where }),
  ])

  return NextResponse.json({
    effects,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  })
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

  // Only whitelisted/staff can upload
  if (!isStaffOrWhitelisted(user)) {
    return NextResponse.json({ error: 'Forbidden: Only whitelisted or staff users can upload' }, { status: 403 })
  }

  let body: Record<string, unknown>
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 422 })
  }

  const { name, type, tags, data } = body

  if (!name || typeof name !== 'string') {
    return NextResponse.json({ error: 'Name is required' }, { status: 422 })
  }

  if (!type || typeof type !== 'string') {
    return NextResponse.json({ error: 'Type is required' }, { status: 422 })
  }

  const validTypes = ['movement', 'pattern', 'chase', 'strobe', 'wave', 'custom']
  if (!validTypes.includes(type)) {
    return NextResponse.json({ error: `Type must be one of: ${validTypes.join(', ')}` }, { status: 422 })
  }

  if (!data) {
    return NextResponse.json({ error: 'Data is required' }, { status: 422 })
  }

  const tagsJson = Array.isArray(tags) ? JSON.stringify(tags) : typeof tags === 'string' ? tags : '[]'
  const dataJson = typeof data === 'string' ? data : JSON.stringify(data)

  const effect = await db.hubEffect.create({
    data: {
      name,
      authorId: user.id,
      authorName: user.robloxUsername || user.discordUsername || user.id,
      type,
      tags: tagsJson,
      data: dataJson,
    },
  })

  return NextResponse.json(effect, { status: 201 })
}
