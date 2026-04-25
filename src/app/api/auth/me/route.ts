import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { validateSession, extractBearerToken, buildUserResponse } from '@/lib/auth'

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
    console.error('[auth/me] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function PUT(request: NextRequest) {
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

    let body: Record<string, unknown>
    try {
      body = await request.json()
    } catch {
      return NextResponse.json(
        { error: 'Invalid JSON body' },
        { status: 422 }
      )
    }

    const { displayPreference, discordUsername, discordAvatar } = body

    const updateData: Record<string, unknown> = {}

    if (displayPreference !== undefined) {
      if (typeof displayPreference !== 'string' || !['roblox', 'discord'].includes(displayPreference)) {
        return NextResponse.json(
          { error: 'displayPreference must be "roblox" or "discord"' },
          { status: 422 }
        )
      }
      updateData.displayPreference = displayPreference
    }

    if (discordUsername !== undefined) {
      if (typeof discordUsername !== 'string' || discordUsername.length === 0) {
        return NextResponse.json(
          { error: 'discordUsername must be a non-empty string' },
          { status: 422 }
        )
      }
      updateData.discordUsername = discordUsername
    }

    if (discordAvatar !== undefined) {
      if (typeof discordAvatar !== 'string') {
        return NextResponse.json(
          { error: 'discordAvatar must be a string' },
          { status: 422 }
        )
      }
      updateData.discordAvatar = discordAvatar || null
    }

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json(
        { error: 'No valid fields to update' },
        { status: 422 }
      )
    }

    const updatedUser = await db.user.update({
      where: { id: user.id },
      data: updateData,
    })

    return NextResponse.json({
      user: buildUserResponse(updatedUser),
    })
  } catch (error) {
    console.error('[auth/me PUT] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
