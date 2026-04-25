import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { hashToken, SESSION_DURATION, buildUserResponse, CODE_EXPIRY } from '@/lib/auth'
import crypto from 'crypto'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { code } = body

    if (!code || typeof code !== 'string') {
      return NextResponse.json(
        { error: 'Code is required' },
        { status: 400 }
      )
    }

    // Normalize code to lowercase
    const normalizedCode = code.toLowerCase().trim()

    // Find the login code
    const loginCode = await db.loginCode.findUnique({
      where: { code: normalizedCode },
      include: { user: true },
    })

    if (!loginCode) {
      return NextResponse.json(
        { error: 'Invalid code' },
        { status: 404 }
      )
    }

    // Must be a login type code
    if (loginCode.type !== 'login') {
      return NextResponse.json(
        { error: 'This code is not a login code' },
        { status: 400 }
      )
    }

    // Check if expired
    if (loginCode.expiresAt < new Date()) {
      return NextResponse.json(
        { error: 'Code has expired' },
        { status: 410 }
      )
    }

    // Check if already used
    if (loginCode.usedAt) {
      return NextResponse.json(
        { error: 'Code has already been used' },
        { status: 410 }
      )
    }

    // Must have an associated user
    if (!loginCode.user) {
      return NextResponse.json(
        { error: 'No user associated with this code' },
        { status: 400 }
      )
    }

    // Mark code as used
    await db.loginCode.update({
      where: { id: loginCode.id },
      data: { usedAt: new Date() },
    })

    // Create session — store HASHED token in DB, return plain token to client
    const plainToken = crypto.randomUUID()
    const hashedToken = hashToken(plainToken)
    const expiresAt = new Date(Date.now() + SESSION_DURATION)

    await db.session.create({
      data: {
        token: hashedToken,
        userId: loginCode.userId!,
        expiresAt,
      },
    })

    return NextResponse.json({
      token: plainToken,
      user: buildUserResponse(loginCode.user),
    })
  } catch (error) {
    console.error('[auth/login] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
