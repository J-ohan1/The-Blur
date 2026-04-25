import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { validateSession, extractBearerToken, hashToken, buildUserResponse } from '@/lib/auth'

export async function GET(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization')
    const token = extractBearerToken(authHeader)

    if (!token) {
      return NextResponse.json(
        { error: 'Authorization header required' },
        { status: 401 }
      )
    }

    const user = await validateSession(token)

    if (!user) {
      return NextResponse.json(
        { error: 'Invalid or expired session' },
        { status: 401 }
      )
    }

    return NextResponse.json({
      user: buildUserResponse(user),
    })
  } catch (error) {
    console.error('[auth/session GET] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization')
    const token = extractBearerToken(authHeader)

    if (!token) {
      return NextResponse.json(
        { error: 'Authorization header required' },
        { status: 401 }
      )
    }

    // Hash the token to find it in the DB (tokens are stored hashed)
    const hashedToken = hashToken(token)

    // Find and delete the session
    const session = await db.session.findUnique({
      where: { token: hashedToken },
    })

    if (!session) {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      )
    }

    await db.session.delete({
      where: { id: session.id },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('[auth/session DELETE] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
