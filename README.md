# The Blur — Website

The web panel for **The Blur Lasers** — a community laser light control system that connects Discord, a Website, and Roblox.

## Architecture

```
Discord Bot ◄──┐
               │
         The Blur Server ◄──► Roblox Game
               │
Website   ◄──┘
```

- **Website (this repo)**: Next.js 16 dashboard for controlling lasers, managing showfiles, and the community Hub
- **[Server](https://github.com/J-ohan1/The-Blur-Server)**: Combined WebSocket service + Discord bot (one deployment!)
- **[Roblox Scripts](https://github.com/J-ohan1/The-Blur-Roblox)**: In-game scripts for laser bridge, access control, and verification GUI

## Features

- 🔐 **Login Code Auth**: 6-digit alphanumeric codes (5-min expiry) generated via Discord `/login`
- 🔗 **Account Linking**: Discord ↔ Roblox ID mapping with duplicate detection
- 🎨 **Laser Control Panel**: Real-time control of lasers with groups, effects, timecode, and faders
- 📁 **Showfile System**: Create, save, import/export laser shows (`.blur` format)
- 👥 **User Roles**: Staff, Whitelisted, Temp Whitelisted, Normal, Blacklisted
- 🏠 **Community Hub**: Share and download community effects
- 🎫 **Verification Codes**: Roblox generates codes → Website validates them
- 🔄 **Real-time**: WebSocket (Socket.IO) for Website ↔ Roblox communication

## Tech Stack

- **Framework**: Next.js 16 (App Router) + TypeScript
- **Styling**: Tailwind CSS 4 + shadcn/ui
- **Database**: Prisma ORM with SQLite
- **State**: Zustand + TanStack Query
- **Runtime**: Bun

## Quick Start

```bash
git clone https://github.com/J-ohan1/The-Blur-Website.git
cd The-Blur-Website
bun install
cp .env.example .env
bun run db:push
bun run dev
```

Open http://localhost:3000

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | SQLite database path | `file:./dev.db` |
| `WS_SERVICE_URL` | WebSocket service URL | `http://localhost:3003` |
| `WEBSITE_URL` | Public website URL | `http://localhost:3000` |

## Deploy to Vercel

1. Push to GitHub
2. Import repo in Vercel
3. Set environment variables
4. Deploy

## API Endpoints

### Authentication
- `POST /api/auth/code` — Generate a login code
- `POST /api/auth/login` — Validate login code, create session
- `POST /api/auth/verify-code` — Verify a Roblox-generated code
- `GET /api/auth/me` — Get current user info
- `PUT /api/auth/me` — Update user preferences
- `POST /api/auth/link` — Link Discord ↔ Roblox accounts
- `POST /api/auth/session` — Validate session token

### Showfiles
- `GET /api/showfile` — List user's showfiles
- `POST /api/showfile` — Create a showfile
- `GET /api/showfile/[id]` — Get a showfile
- `PUT /api/showfile/[id]` — Update a showfile
- `DELETE /api/showfile/[id]` — Delete a showfile
- `POST /api/showfile/link` — Link showfile to a Roblox place
- `GET /api/showfile/export/[id]` — Export as `.blur` file
- `POST /api/showfile/import` — Import a `.blur` file

### Hub (Community Effects)
- `GET /api/hub` — List community effects
- `POST /api/hub` — Publish an effect
- `GET /api/hub/[id]` — Get an effect

### Roblox Access
- `GET /api/roblox/access?placeId=X` — Get whitelist/blacklist data

### Admin
- `GET /api/blacklist` — List blacklisted users
- `POST /api/blacklist` — Add to blacklist
- `DELETE /api/blacklist` — Remove from blacklist
- `GET /api/whitelist` — List whitelisted users
- `POST /api/whitelist` — Add to whitelist
- `DELETE /api/whitelist` — Remove from whitelist

## .blur File Format

```json
{
  "version": "1.0",
  "name": "Show Name",
  "description": "Show description",
  "exportedAt": "2024-01-01T00:00:00.000Z",
  "exportedBy": "Username",
  "data": {
    "groups": [...],
    "effects": [...],
    "positions": [...],
    "timecode": [...]
  }
}
```

## License

Private — All rights reserved.
