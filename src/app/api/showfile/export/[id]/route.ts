import { db } from '@/lib/db'
import { validateSession, extractBearerToken } from '@/lib/auth'
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

  // Parse the data field safely
  let parsedData: unknown
  try {
    parsedData = JSON.parse(showfile.data)
  } catch {
    parsedData = showfile.data // fallback: return raw string if not valid JSON
  }

  // Build .blur format
  const blurData = {
    version: '1.0',
    name: showfile.name,
    description: showfile.description || '',
    data: parsedData,
    exportedAt: new Date().toISOString(),
    exportedBy: user.robloxUsername || user.discordUsername || user.id,
  }

  const filename = `${showfile.name.replace(/[^a-zA-Z0-9_\- ]/g, '_')}.blur`

  return new Response(JSON.stringify(blurData, null, 2), {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${filename}"`,
    },
  })
}
