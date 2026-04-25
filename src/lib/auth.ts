import { db } from '@/lib/db'
import crypto from 'crypto'

/** Session duration: 24 hours in milliseconds */
export const SESSION_DURATION = 24 * 60 * 60 * 1000

/** Code expiration: 5 minutes in milliseconds */
export const CODE_EXPIRY = 5 * 60 * 1000

/** Characters used for code generation (0-9, a-z) */
const CODE_CHARS = '0123456789abcdefghijklmnopqrstuvwxyz'

/**
 * Generate a random 6-character alphanumeric code (0-9, a-z)
 */
export function generateCode(): string {
  let code = ''
  for (let i = 0; i < 6; i++) {
    const idx = crypto.randomInt(0, CODE_CHARS.length)
    code += CODE_CHARS[idx]
  }
  return code
}

/**
 * Simple hash for session tokens (SHA-256 truncated)
 */
export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex').slice(0, 32)
}

/**
 * Validate a session token and return the associated user, or null if invalid/expired.
 * The token stored in the database is hashed, so we hash the incoming token before lookup.
 */
export async function validateSession(token: string) {
  if (!token) return null

  const hashedToken = hashToken(token)

  const session = await db.session.findUnique({
    where: { token: hashedToken },
    include: { user: true },
  })

  if (!session) return null
  if (session.expiresAt < new Date()) {
    // Clean up expired session
    await db.session.delete({ where: { id: session.id } }).catch(() => {})
    return null
  }

  return session.user
}

/**
 * Extract Bearer token from Authorization header
 */
export function extractBearerToken(authHeader: string | null): string | null {
  if (!authHeader) return null
  const parts = authHeader.split(' ')
  if (parts.length !== 2 || parts[0] !== 'Bearer') return null
  return parts[1]
}

/**
 * Check if a user has staff, whitelisted, or valid temp_whitelisted role.
 * Temp-whitelisted users must have an unexpired tempWhitelistExpiresAt.
 */
export function isStaffOrWhitelisted(user: {
  role: string
  tempWhitelistExpiresAt: Date | null
}): boolean {
  if (user.role === 'staff' || user.role === 'whitelisted') return true
  if (user.role === 'temp_whitelisted') {
    if (user.tempWhitelistExpiresAt && user.tempWhitelistExpiresAt > new Date()) {
      return true
    }
  }
  return false
}

/**
 * Check if a user is NOT blacklisted.
 * Returns true if the user is allowed to use the platform.
 */
export function isNotBlacklisted(user: { role: string }): boolean {
  return user.role !== 'blacklisted'
}

/**
 * Build a user response object with display name based on preference
 */
export function buildUserResponse(user: {
  id: string
  discordId: string | null
  robloxId: string | null
  robloxUsername: string | null
  discordUsername: string | null
  discordAvatar: string | null
  displayPreference: string
  role: string
  createdAt: Date
  updatedAt: Date
}) {
  const displayName =
    user.displayPreference === 'discord'
      ? user.discordUsername || user.robloxUsername || 'Unknown'
      : user.robloxUsername || user.discordUsername || 'Unknown'

  return {
    id: user.id,
    discordId: user.discordId,
    robloxId: user.robloxId,
    robloxUsername: user.robloxUsername,
    discordUsername: user.discordUsername,
    discordAvatar: user.discordAvatar,
    displayPreference: user.displayPreference,
    role: user.role,
    displayName,
  }
}
