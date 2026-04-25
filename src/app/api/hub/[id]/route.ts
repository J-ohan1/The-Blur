import { db } from '@/lib/db'
import { validateSession, extractBearerToken } from '@/lib/auth'
import { NextResponse } from 'next/server'

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params

  const effect = await db.hubEffect.findUnique({
    where: { id },
  })

  if (!effect) {
    return NextResponse.json({ error: 'Effect not found' }, { status: 404 })
  }

  // Increment download count
  await db.hubEffect.update({
    where: { id },
    data: { downloads: { increment: 1 } },
  })

  return NextResponse.json({ ...effect, downloads: effect.downloads + 1 })
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

  const effect = await db.hubEffect.findUnique({
    where: { id },
  })

  if (!effect) {
    return NextResponse.json({ error: 'Effect not found' }, { status: 404 })
  }

  // Only author or staff can delete
  if (effect.authorId !== user.id && user.role !== 'staff') {
    return NextResponse.json({ error: 'Forbidden: Only the author or staff can delete' }, { status: 403 })
  }

  await db.hubEffect.delete({
    where: { id },
  })

  return NextResponse.json({ message: 'Effect deleted' })
}
