import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { generateCode, CODE_EXPIRY } from '@/lib/auth'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { discordId, discordUsername, discordAvatar } = body

    if (!discordId || typeof discordId !== 'string') {
      return NextResponse.json(
        { error: 'discordId is required' },
        { status: 400 }
      )
    }

    if (!discordUsername || typeof discordUsername !== 'string') {
      return NextResponse.json(
        { error: 'discordUsername is required' },
        { status: 400 }
      )
    }

    // Find or create user by discordId
    let user = await db.user.findUnique({
      where: { discordId },
    })

    if (!user) {
      user = await db.user.create({
        data: {
          discordId,
          discordUsername,
          discordAvatar: discordAvatar || null,
        },
      })
    } else {
      // Update username/avatar if changed
      await db.user.update({
        where: { id: user.id },
        data: {
          discordUsername,
          ...(discordAvatar !== undefined && { discordAvatar: discordAvatar || null }),
        },
      })
    }

    // Generate a unique code
    let code: string
    let attempts = 0
    do {
      code = generateCode()
      const existing = await db.loginCode.findUnique({ where: { code } })
      if (!existing) break
      attempts++
    } while (attempts < 10)

    if (attempts >= 10) {
      return NextResponse.json(
        { error: 'Failed to generate unique code, try again' },
        { status: 500 }
      )
    }

    const expiresAt = new Date(Date.now() + CODE_EXPIRY)

    // Create the login code
    await db.loginCode.create({
      data: {
        code,
        type: 'login',
        userId: user.id,
        expiresAt,
      },
    })

    return NextResponse.json({
      code,
      expiresAt,
    })
  } catch (error) {
    console.error('[auth/code] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
