import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { generateCode, CODE_EXPIRY } from '@/lib/auth'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { robloxId, robloxUsername, robloxPlaceId } = body

    if (!robloxId || typeof robloxId !== 'string') {
      return NextResponse.json(
        { error: 'robloxId is required' },
        { status: 400 }
      )
    }

    if (!robloxUsername || typeof robloxUsername !== 'string') {
      return NextResponse.json(
        { error: 'robloxUsername is required' },
        { status: 400 }
      )
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

    // Create the verification code (no user association yet — will be linked on verify)
    await db.loginCode.create({
      data: {
        code,
        type: 'verification',
        robloxId,
        robloxUsername,
        robloxPlaceId: robloxPlaceId || null,
        expiresAt,
      },
    })

    return NextResponse.json({
      code,
      expiresAt,
    })
  } catch (error) {
    console.error('[auth/verify-code] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
