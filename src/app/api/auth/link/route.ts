import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { buildUserResponse } from '@/lib/auth'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { discordId, discordUsername, robloxId, robloxUsername } = body

    // Validate required fields
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

    // Check if this exact link already exists
    const existingLink = await db.accountLink.findUnique({
      where: { discordId_robloxId: { discordId, robloxId } },
    })

    if (existingLink) {
      // Already linked — return the user
      const user = await db.user.findUnique({
        where: { discordId },
      })
      return NextResponse.json({
        success: true,
        user: user ? buildUserResponse(user) : null,
      })
    }

    // Check for conflicts: discordId linked to a different robloxId
    let warning: string | undefined
    const existingDiscordLink = await db.accountLink.findFirst({
      where: { discordId, robloxId: { not: robloxId } },
    })

    if (existingDiscordLink) {
      warning = `Discord ID ${discordId} is already linked to a different Roblox account`
    }

    // Check for conflicts: robloxId linked to a different discordId
    const existingRobloxLink = await db.accountLink.findFirst({
      where: { robloxId, discordId: { not: discordId } },
    })

    if (existingRobloxLink) {
      warning = warning
        ? `${warning}; Roblox ID ${robloxId} is also already linked to a different Discord account`
        : `Roblox ID ${robloxId} is already linked to a different Discord account`
    }

    // Find or create user
    // Try by discordId first
    let user = await db.user.findUnique({ where: { discordId } })

    if (user) {
      // Update with roblox info
      user = await db.user.update({
        where: { id: user.id },
        data: {
          robloxId,
          robloxUsername,
        },
      })
    } else {
      // Try by robloxId
      user = await db.user.findUnique({ where: { robloxId } })

      if (user) {
        // Update with discord info
        user = await db.user.update({
          where: { id: user.id },
          data: {
            discordId,
            discordUsername,
          },
        })
      } else {
        // Create new user with both
        user = await db.user.create({
          data: {
            discordId,
            discordUsername,
            robloxId,
            robloxUsername,
          },
        })
      }
    }

    // Create the account link
    await db.accountLink.create({
      data: {
        discordId,
        robloxId,
      },
    })

    return NextResponse.json({
      success: true,
      ...(warning && { warning }),
      user: buildUserResponse(user),
    })
  } catch (error) {
    console.error('[auth/link] Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
