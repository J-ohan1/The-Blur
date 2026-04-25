import { db } from '@/lib/db'
import { validateSession, extractBearerToken, isNotBlacklisted } from '@/lib/auth'
import { NextResponse } from 'next/server'

interface BlurFile {
  version: string
  name: string
  description?: string
  data: unknown
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
    return NextResponse.json({ error: 'Forbidden: Blacklisted users cannot import showfiles' }, { status: 403 })
  }

  // Parse FormData
  let formData: FormData
  try {
    formData = await request.formData()
  } catch {
    return NextResponse.json({ error: 'Invalid form data' }, { status: 422 })
  }

  const file = formData.get('file')
  if (!file || !(file instanceof File)) {
    return NextResponse.json({ error: 'File is required' }, { status: 422 })
  }

  // Check file extension
  if (!file.name.endsWith('.blur')) {
    return NextResponse.json({ error: 'File must have .blur extension' }, { status: 422 })
  }

  // Parse JSON content
  let blurData: BlurFile
  try {
    const text = await file.text()
    blurData = JSON.parse(text)
  } catch {
    return NextResponse.json({ error: 'Invalid .blur file: not valid JSON' }, { status: 422 })
  }

  // Validate structure
  if (!blurData.version || typeof blurData.version !== 'string') {
    return NextResponse.json({ error: 'Invalid .blur file: missing version' }, { status: 422 })
  }

  if (!blurData.name || typeof blurData.name !== 'string') {
    return NextResponse.json({ error: 'Invalid .blur file: missing name' }, { status: 422 })
  }

  if (!blurData.data) {
    return NextResponse.json({ error: 'Invalid .blur file: missing data' }, { status: 422 })
  }

  // Resolve name conflicts
  let finalName = blurData.name.substring(0, 70)
  const existing = await db.showFile.findUnique({
    where: {
      userId_name: { userId: user.id, name: finalName },
    },
  })

  if (existing) {
    finalName = `${finalName} (Imported)`
    // Check if even the imported name conflicts
    const existing2 = await db.showFile.findUnique({
      where: {
        userId_name: { userId: user.id, name: finalName },
      },
    })
    if (existing2) {
      // Append timestamp to make it unique
      finalName = `${blurData.name.substring(0, 50)} (Imported ${Date.now()})`
    }
  }

  // Serialize the data field for storage
  const dataForStorage = typeof blurData.data === 'string' ? blurData.data : JSON.stringify(blurData.data)

  const showfile = await db.showFile.create({
    data: {
      userId: user.id,
      name: finalName,
      description: blurData.description || null,
      data: dataForStorage,
    },
  })

  return NextResponse.json({ showfile }, { status: 201 })
}
