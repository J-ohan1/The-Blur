import { createServer, IncomingMessage, ServerResponse } from 'http'
import { Server, Socket } from 'socket.io'

// ============================================================================
// Types
// ============================================================================

interface LaserCommand {
  id: string
  type: 'on_off' | 'fade' | 'effect' | 'position' | 'color' | 'fader' | 'group'
  groupIds: string[]
  payload: Record<string, any>
  timestamp: number
}

interface GamePlayer {
  robloxId: string
  robloxUsername: string
  role: 'whitelisted' | 'temp_whitelisted' | 'blacklisted' | 'normal'
}

interface GameConnection {
  placeId: string
  gameId: string
  laserCount: number
  creatorId: string
  creatorName: string
  connectedAt: number
  lastHeartbeat: number
  players: GamePlayer[]
}

interface VerificationEntry {
  code: string
  placeId: string
  gameId: string
  expiresAt: number
}

// ============================================================================
// In-Memory State
// ============================================================================

const gameConnections = new Map<string, GameConnection>()        // placeId -> GameConnection
const commandQueues = new Map<string, LaserCommand[]>()           // placeId -> LaserCommand[]
const verificationCodes = new Map<string, VerificationEntry>()    // code -> VerificationEntry
const connectedClients = new Map<string, Set<string>>()           // placeId -> Set<socketId>

// ============================================================================
// Constants
// ============================================================================

const PORT = 3003
const COMMAND_STALE_MS = 5000          // Commands older than 5s are discarded
const VERIFICATION_EXPIRE_MS = 300000  // Verification codes expire after 5 minutes
const HEARTBEAT_TIMEOUT_MS = 30000     // Game considered disconnected after 30s without heartbeat
const CLEANUP_INTERVAL_MS = 10000      // Cleanup stale data every 10s

// ============================================================================
// Helpers
// ============================================================================

function generateId(): string {
  return Math.random().toString(36).substring(2, 11) + Date.now().toString(36)
}

function generateVerificationCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789' // No confusing chars (0/O, 1/I/l)
  let code = ''
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return code
}

/** Purge stale commands older than COMMAND_STALE_MS */
function purgeStaleCommands(placeId: string): void {
  const queue = commandQueues.get(placeId)
  if (!queue) return
  const now = Date.now()
  const filtered = queue.filter(cmd => now - cmd.timestamp < COMMAND_STALE_MS)
  commandQueues.set(placeId, filtered)
}

/** Enqueue a command for a specific placeId */
function enqueueCommand(placeId: string, command: LaserCommand): void {
  if (!commandQueues.has(placeId)) {
    commandQueues.set(placeId, [])
  }
  commandQueues.get(placeId)!.push(command)
}

/** Dequeue all pending (non-stale) commands for a placeId, then clear */
function dequeueCommands(placeId: string): LaserCommand[] {
  purgeStaleCommands(placeId)
  const queue = commandQueues.get(placeId) || []
  commandQueues.set(placeId, [])
  return queue
}

/** Broadcast to all website clients watching a specific placeId */
function broadcastToPlace(placeId: string, event: string, data: any): void {
  const clients = connectedClients.get(placeId)
  if (!clients || clients.size === 0) return
  for (const socketId of clients) {
    const socket = io.sockets.sockets.get(socketId)
    if (socket) {
      socket.emit(event, data)
    }
  }
}

// ============================================================================
// Periodic Cleanup
// ============================================================================

setInterval(() => {
  const now = Date.now()

  // Remove expired verification codes
  for (const [code, entry] of verificationCodes) {
    if (now >= entry.expiresAt) {
      verificationCodes.delete(code)
    }
  }

  // Detect heartbeat timeouts — mark game as disconnected
  for (const [placeId, conn] of gameConnections) {
    if (now - conn.lastHeartbeat > HEARTBEAT_TIMEOUT_MS) {
      console.log(`[TIMEOUT] Game disconnected (heartbeat timeout): placeId=${placeId}`)
      gameConnections.delete(placeId)
      commandQueues.delete(placeId)
      broadcastToPlace(placeId, 'game:disconnected', { placeId, reason: 'heartbeat_timeout' })
    }
  }
}, CLEANUP_INTERVAL_MS)

// ============================================================================
// HTTP Request Handler (for Roblox HttpService)
// ============================================================================

function parseBody(req: IncomingMessage): Promise<any> {
  return new Promise((resolve, reject) => {
    let body = ''
    req.on('data', (chunk: Buffer) => { body += chunk.toString() })
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {})
      } catch {
        reject(new Error('Invalid JSON'))
      }
    })
    req.on('error', reject)
  })
}

function sendJSON(res: ServerResponse, status: number, data: any): void {
  if (res.headersSent) return
  res.writeHead(status, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify(data))
}

async function handleHTTPRequest(req: IncomingMessage, res: ServerResponse): Promise<void> {
  const url = new URL(req.url || '/', `http://localhost:${PORT}`)
  const pathname = url.pathname
  const method = (req.method || 'GET').toUpperCase()

  // Only handle /api/* and /health routes — everything else goes to socket.io
  if (!pathname.startsWith('/api/') && pathname !== '/health') {
    return // Let socket.io handle it
  }

  try {
    // ---- POST /api/game/connect ----
    if (pathname === '/api/game/connect' && method === 'POST') {
      const body = await parseBody(req)
      const { verificationCode, placeId, gameId, laserCount, creatorId, creatorName } = body

      if (!verificationCode || !placeId || !gameId) {
        sendJSON(res, 400, { error: 'Missing required fields: verificationCode, placeId, gameId' })
        return
      }

      // Validate verification code
      const entry = verificationCodes.get(verificationCode)
      if (!entry || entry.placeId !== placeId || entry.gameId !== gameId) {
        sendJSON(res, 403, { error: 'Invalid or expired verification code' })
        return
      }
      if (Date.now() >= entry.expiresAt) {
        verificationCodes.delete(verificationCode)
        sendJSON(res, 403, { error: 'Verification code expired' })
        return
      }

      // Code is valid — consume it
      verificationCodes.delete(verificationCode)

      // If there's already a connection for this placeId, disconnect it
      if (gameConnections.has(placeId)) {
        broadcastToPlace(placeId, 'game:disconnected', { placeId, reason: 'replaced' })
      }

      const connection: GameConnection = {
        placeId,
        gameId,
        laserCount: laserCount || 0,
        creatorId: creatorId || '',
        creatorName: creatorName || '',
        connectedAt: Date.now(),
        lastHeartbeat: Date.now(),
        players: [],
      }

      gameConnections.set(placeId, connection)
      console.log(`[CONNECT] Game connected: placeId=${placeId} gameId=${gameId} lasers=${laserCount} creator=${creatorName}`)

      // Notify website clients
      broadcastToPlace(placeId, 'game:connected', { placeId, connection })

      sendJSON(res, 200, { success: true, message: 'Game connected', connection })
      return
    }

    // ---- GET /api/game/commands ----
    if (pathname === '/api/game/commands' && method === 'GET') {
      const placeId = url.searchParams.get('placeId')
      if (!placeId) {
        sendJSON(res, 400, { error: 'Missing query parameter: placeId' })
        return
      }

      const commands = dequeueCommands(placeId)
      sendJSON(res, 200, { commands })
      return
    }

    // ---- POST /api/game/heartbeat ----
    if (pathname === '/api/game/heartbeat' && method === 'POST') {
      const body = await parseBody(req)
      const { placeId, playerCount, players } = body

      if (!placeId) {
        sendJSON(res, 400, { error: 'Missing required field: placeId' })
        return
      }

      const connection = gameConnections.get(placeId)
      if (!connection) {
        sendJSON(res, 404, { error: 'Game not connected' })
        return
      }

      connection.lastHeartbeat = Date.now()

      // Update player list if provided
      if (Array.isArray(players)) {
        connection.players = players.map((p: any) => ({
          robloxId: String(p.robloxId || p.userId || ''),
          robloxUsername: String(p.robloxUsername || p.username || ''),
          role: p.role || 'normal',
        }))
      }

      // Broadcast player list to website
      broadcastToPlace(placeId, 'player:list', {
        placeId,
        players: connection.players,
        playerCount: playerCount || connection.players.length,
      })

      // Broadcast laser status
      broadcastToPlace(placeId, 'laser:status', {
        placeId,
        laserCount: connection.laserCount,
        connected: true,
        lastHeartbeat: connection.lastHeartbeat,
      })

      sendJSON(res, 200, { success: true })
      return
    }

    // ---- POST /api/game/verify-code ----
    if (pathname === '/api/game/verify-code' && method === 'POST') {
      const body = await parseBody(req)
      const { placeId, gameId } = body

      if (!placeId || !gameId) {
        sendJSON(res, 400, { error: 'Missing required fields: placeId, gameId' })
        return
      }

      const code = generateVerificationCode()
      const entry: VerificationEntry = {
        code,
        placeId,
        gameId,
        expiresAt: Date.now() + VERIFICATION_EXPIRE_MS,
      }
      verificationCodes.set(code, entry)

      console.log(`[VERIFY-CODE] Generated code=${code} for placeId=${placeId} gameId=${gameId}`)

      sendJSON(res, 200, { code, expiresAt: entry.expiresAt })
      return
    }

    // ---- DELETE /api/game/disconnect ----
    if (pathname === '/api/game/disconnect' && method === 'DELETE') {
      const placeId = url.searchParams.get('placeId')
      if (!placeId) {
        sendJSON(res, 400, { error: 'Missing query parameter: placeId' })
        return
      }

      const existed = gameConnections.has(placeId)
      gameConnections.delete(placeId)
      commandQueues.delete(placeId)

      if (existed) {
        console.log(`[DISCONNECT] Game disconnected: placeId=${placeId}`)
        broadcastToPlace(placeId, 'game:disconnected', { placeId, reason: 'manual' })
      }

      sendJSON(res, 200, { success: true, wasConnected: existed })
      return
    }

    // ---- Health check ----
    if (pathname === '/health') {
      sendJSON(res, 200, {
        status: 'ok',
        uptime: process.uptime(),
        connections: gameConnections.size,
        pendingCommands: Array.from(commandQueues.entries()).map(([pid, q]) => ({
          placeId: pid,
          count: q.length,
        })),
        verificationCodes: verificationCodes.size,
      })
      return
    }

    // 404 for unhandled /api/* routes
    sendJSON(res, 404, { error: 'Not found' })
  } catch (err: any) {
    console.error(`[HTTP ERROR] ${method} ${pathname}:`, err.message)
    sendJSON(res, 500, { error: 'Internal server error' })
  }
}

// ============================================================================
// HTTP Server + Socket.io
// ============================================================================

const httpServer = createServer(handleHTTPRequest)

const io = new Server(httpServer, {
  // Default path is /socket.io/ — this allows our /api/* routes to work
  // alongside socket.io without conflicts
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'DELETE'],
  },
  pingTimeout: 60000,
  pingInterval: 25000,
})

// ============================================================================
// Socket.io Event Handlers (Website ↔ Server)
// ============================================================================

io.on('connection', (socket: Socket) => {
  console.log(`[WS CONNECT] Client: ${socket.id}`)

  // ------------------------------------------------------------------
  // Website client subscribes to a placeId room for real-time updates
  // ------------------------------------------------------------------
  socket.on('subscribe:place', (data: { placeId: string }) => {
    const { placeId } = data
    if (!placeId) return

    socket.join(`place:${placeId}`)

    // Track which sockets are watching which place
    if (!connectedClients.has(placeId)) {
      connectedClients.set(placeId, new Set())
    }
    connectedClients.get(placeId)!.add(socket.id)

    // Send current game state to the newly subscribed client
    const connection = gameConnections.get(placeId)
    if (connection) {
      socket.emit('game:connected', { placeId, connection })
      socket.emit('player:list', { placeId, players: connection.players, playerCount: connection.players.length })
      socket.emit('laser:status', {
        placeId,
        laserCount: connection.laserCount,
        connected: true,
        lastHeartbeat: connection.lastHeartbeat,
      })
    }

    console.log(`[SUBSCRIBE] Client ${socket.id} subscribed to placeId=${placeId}`)
  })

  socket.on('unsubscribe:place', (data: { placeId: string }) => {
    const { placeId } = data
    if (!placeId) return

    socket.leave(`place:${placeId}`)
    const clients = connectedClients.get(placeId)
    if (clients) {
      clients.delete(socket.id)
      if (clients.size === 0) connectedClients.delete(placeId)
    }

    console.log(`[UNSUBSCRIBE] Client ${socket.id} unsubscribed from placeId=${placeId}`)
  })

  // ------------------------------------------------------------------
  // Laser commands from the control panel
  // ------------------------------------------------------------------
  socket.on('laser:command', (data: {
    placeId: string
    type: LaserCommand['type']
    groupIds: string[]
    payload: Record<string, any>
  }) => {
    const { placeId, type, groupIds, payload } = data

    if (!placeId || !type) {
      socket.emit('error', { message: 'Missing placeId or type' })
      return
    }

    const command: LaserCommand = {
      id: generateId(),
      type,
      groupIds: groupIds || [],
      payload: payload || {},
      timestamp: Date.now(),
    }

    enqueueCommand(placeId, command)
    console.log(`[COMMAND] Queued ${type} for placeId=${placeId} groups=${JSON.stringify(groupIds)}`)

    // Acknowledge to sender
    socket.emit('command:ack', { commandId: command.id, placeId })

    // Notify all watchers that a command was queued
    broadcastToPlace(placeId, 'command:queued', { placeId, command })
  })

  // ------------------------------------------------------------------
  // Group configuration updates
  // ------------------------------------------------------------------
  socket.on('group:update', (data: { placeId: string; groups: any[] }) => {
    const { placeId, groups } = data
    if (!placeId) return

    const command: LaserCommand = {
      id: generateId(),
      type: 'group',
      groupIds: (groups || []).map((g: any) => g.id).filter(Boolean),
      payload: { groups },
      timestamp: Date.now(),
    }

    enqueueCommand(placeId, command)
    console.log(`[GROUP:UPDATE] placeId=${placeId} groups=${groups?.length || 0}`)

    broadcastToPlace(placeId, 'group:updated', { placeId, groups })
  })

  // ------------------------------------------------------------------
  // Effect trigger
  // ------------------------------------------------------------------
  socket.on('effect:trigger', (data: { placeId: string; effectId: string; effectName: string; groupIds: string[]; params?: Record<string, any> }) => {
    const { placeId, effectId, effectName, groupIds, params } = data
    if (!placeId || !effectId) return

    const command: LaserCommand = {
      id: generateId(),
      type: 'effect',
      groupIds: groupIds || [],
      payload: { effectId, effectName, params: params || {} },
      timestamp: Date.now(),
    }

    enqueueCommand(placeId, command)
    console.log(`[EFFECT:TRIGGER] placeId=${placeId} effect=${effectName} groups=${JSON.stringify(groupIds)}`)

    broadcastToPlace(placeId, 'effect:triggered', { placeId, effectId, effectName, groupIds })
  })

  // ------------------------------------------------------------------
  // Timecode playback controls
  // ------------------------------------------------------------------
  socket.on('timecode:play', (data: { placeId: string; timecodeId: string; fromStep?: number }) => {
    const { placeId, timecodeId, fromStep } = data
    if (!placeId) return

    const command: LaserCommand = {
      id: generateId(),
      type: 'fade', // Timecode uses fade commands under the hood
      groupIds: [],
      payload: { action: 'timecode:play', timecodeId, fromStep },
      timestamp: Date.now(),
    }

    enqueueCommand(placeId, command)
    console.log(`[TIMECODE:PLAY] placeId=${placeId} timecodeId=${timecodeId}`)

    broadcastToPlace(placeId, 'timecode:playing', { placeId, timecodeId, fromStep })
  })

  socket.on('timecode:stop', (data: { placeId: string; timecodeId: string }) => {
    const { placeId, timecodeId } = data
    if (!placeId) return

    const command: LaserCommand = {
      id: generateId(),
      type: 'fade',
      groupIds: [],
      payload: { action: 'timecode:stop', timecodeId },
      timestamp: Date.now(),
    }

    enqueueCommand(placeId, command)
    console.log(`[TIMECODE:STOP] placeId=${placeId} timecodeId=${timecodeId}`)

    broadcastToPlace(placeId, 'timecode:stopped', { placeId, timecodeId })
  })

  socket.on('timecode:step', (data: { placeId: string; timecodeId: string; step: number }) => {
    const { placeId, timecodeId, step } = data
    if (!placeId) return

    const command: LaserCommand = {
      id: generateId(),
      type: 'fade',
      groupIds: [],
      payload: { action: 'timecode:step', timecodeId, step },
      timestamp: Date.now(),
    }

    enqueueCommand(placeId, command)
    console.log(`[TIMECODE:STEP] placeId=${placeId} timecodeId=${timecodeId} step=${step}`)

    broadcastToPlace(placeId, 'timecode:stepped', { placeId, timecodeId, step })
  })

  // ------------------------------------------------------------------
  // Game-side socket events (if Roblox ever supports WebSocket)
  // These are mainly for future extensibility; Roblox uses HTTP polling
  // ------------------------------------------------------------------

  socket.on('game:connect', (data: { verificationCode: string; placeId: string; gameId: string; laserCount: number; creatorId: string; creatorName: string }) => {
    const { verificationCode, placeId, gameId, laserCount, creatorId, creatorName } = data

    const entry = verificationCodes.get(verificationCode)
    if (!entry || entry.placeId !== placeId || entry.gameId !== gameId || Date.now() >= entry.expiresAt) {
      socket.emit('error', { message: 'Invalid or expired verification code' })
      return
    }

    verificationCodes.delete(verificationCode)

    if (gameConnections.has(placeId)) {
      broadcastToPlace(placeId, 'game:disconnected', { placeId, reason: 'replaced' })
    }

    const connection: GameConnection = {
      placeId,
      gameId,
      laserCount: laserCount || 0,
      creatorId: creatorId || '',
      creatorName: creatorName || '',
      connectedAt: Date.now(),
      lastHeartbeat: Date.now(),
      players: [],
    }

    gameConnections.set(placeId, connection)
    console.log(`[GAME:CONNECT] placeId=${placeId} gameId=${gameId} (via WebSocket)`)

    broadcastToPlace(placeId, 'game:connected', { placeId, connection })
  })

  socket.on('game:laser-count', (data: { placeId: string; laserCount: number }) => {
    const { placeId, laserCount } = data
    const connection = gameConnections.get(placeId)
    if (!connection) return

    connection.laserCount = laserCount
    broadcastToPlace(placeId, 'laser:status', {
      placeId,
      laserCount,
      connected: true,
      lastHeartbeat: connection.lastHeartbeat,
    })
  })

  socket.on('game:heartbeat', (data: { placeId: string }) => {
    const connection = gameConnections.get(data.placeId)
    if (connection) {
      connection.lastHeartbeat = Date.now()
    }
  })

  socket.on('game:player-join', (data: { placeId: string; player: GamePlayer }) => {
    const connection = gameConnections.get(data.placeId)
    if (!connection) return

    // Add player if not already present
    if (!connection.players.find(p => p.robloxId === data.player.robloxId)) {
      connection.players.push(data.player)
    }

    broadcastToPlace(data.placeId, 'player:list', {
      placeId: data.placeId,
      players: connection.players,
      playerCount: connection.players.length,
    })
  })

  socket.on('game:player-leave', (data: { placeId: string; robloxId: string }) => {
    const connection = gameConnections.get(data.placeId)
    if (!connection) return

    connection.players = connection.players.filter(p => p.robloxId !== data.robloxId)

    broadcastToPlace(data.placeId, 'player:list', {
      placeId: data.placeId,
      players: connection.players,
      playerCount: connection.players.length,
    })
  })

  // ------------------------------------------------------------------
  // Disconnect
  // ------------------------------------------------------------------
  socket.on('disconnect', (reason) => {
    console.log(`[WS DISCONNECT] Client: ${socket.id} reason=${reason}`)

    // Remove from all place subscriptions
    for (const [placeId, clients] of connectedClients) {
      if (clients.has(socket.id)) {
        clients.delete(socket.id)
        if (clients.size === 0) connectedClients.delete(placeId)
      }
    }
  })

  socket.on('error', (error) => {
    console.error(`[WS ERROR] Client: ${socket.id}`, error)
  })
})

// ============================================================================
// Start Server
// ============================================================================

httpServer.listen(PORT, () => {
  console.log(`============================================`)
  console.log(`  Laser WebSocket Service`)
  console.log(`  Port: ${PORT}`)
  console.log(`  Started: ${new Date().toISOString()}`)
  console.log(`  HTTP API: /api/game/*, /health`)
  console.log(`  Socket.io: /socket.io/ (default path)`)
  console.log(`============================================`)
})

// ============================================================================
// Graceful Shutdown
// ============================================================================

function shutdown(signal: string): void {
  console.log(`\n[${signal}] Shutting down Laser WebSocket Service...`)
  io.disconnectSockets(true)
  httpServer.close(() => {
    console.log('Server closed.')
    process.exit(0)
  })
  // Force exit after 5s
  setTimeout(() => {
    console.error('Forced shutdown after timeout.')
    process.exit(1)
  }, 5000)
}

process.on('SIGTERM', () => shutdown('SIGTERM'))
process.on('SIGINT', () => shutdown('SIGINT'))
