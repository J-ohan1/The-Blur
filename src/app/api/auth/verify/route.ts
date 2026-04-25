import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { hashToken, SESSION_DURATION, buildUserResponse } from '@/lib/auth'
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

    // Find the verification code
    const loginCode = await db.loginCode.findUnique({
      where: { code: normalizedCode },
    })

    if (!loginCode) {
      return NextResponse.json(
        { error: 'Invalid code' },
        { status: 404 }
      )
    }

    // Must be a verification type code
    if (loginCode.type !== 'verification') {
      return NextResponse.json(
        { error: 'This code is not a verification code' },
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

    // Must have robloxId
    if (!loginCode.robloxId) {
      return NextResponse.json(
        { error: 'Verification code has no associated Roblox ID' },
        { status: 400 }
      )
    }

    // Mark code as used
    await db.loginCode.update({
      where: { id: loginCode.id },
      data: { usedAt: new Date() },
    })

    // Check if a user already exists with this robloxId
    let user = await db.user.findUnique({
      where: { robloxId: loginCode.robloxId },
    })

    let isNewUser = false

    if (!user) {
      // Create a new user with just the Roblox info
      user = await db.user.create({
        data: {
          robloxId: loginCode.robloxId,
          robloxUsername: loginCode.robloxUsername,
          role: 'temp_whitelisted',
          tempWhitelistExpiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24-hour temp whitelist
        },
      })
      isNewUser = true
    } else {
      // Update robloxUsername in case it changed
      if (loginCode.robloxUsername && loginCode.robloxUsername !== user.robloxUsername) {
        user = await db.user.update({
          where: { id: user.id },
          data: { robloxUsername: loginCode.robloxUsername },
        })
      }
    }

    // Create session — store HASHED token in DB, return plain token to client
    const plainToken = crypto.randomUUID()
    const hashedToken = hashToken(plainToken)
    const expiresAt = new Date(Date.now() + SESSION_DURATION)

    await db.session.create({
      data: {
        token: hashedToken,
        userId: user.id,
        expiresAt,
      },
    })

    return NextResponse.json({
      token: plainToken,
      user: buildUserResponse(user),
      isNewUser,
    })
  } catch (error) {
    console.error('[auth/verify] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
