# The Blur — Website

The web panel for **The Blur Lasers** — a community laser light control system that connects Discord, a Website, and Roblox.

## Architecture

```
Discord Bot ←→ Website ←→ Roblox Game
```

- **Website (this repo)**: Next.js 16 dashboard for controlling lasers, managing showfiles, and the community Hub
- **[Discord Bot](https://github.com/J-ohan1/The-Blur-Bot)**: Handles `/link`, `/login`, `/unlink`, `/status`, `/help` slash commands
- **[Roblox Scripts](https://github.com/J-ohan1/The-Blur-Roblox)**: In-game scripts for laser bridge, access control, and verification GUI

## Features

- 🔐 **Login Code Auth**: 6-digit alphanumeric codes (5-min expiry) generated via Discord `/login`
- 🔗 **Account Linking**: Discord ↔ Roblox ID mapping with duplicate detection
- 🎨 **Laser Control Panel**: Real-time control of lasers with groups, effects, timecode, and faders
- 📁 **Showfile System**: Create, save, import/export laser shows (`.blur` format)
- 👥 **User Roles**: Staff, Whitelisted, Temp Whitelisted, Normal, Blacklisted
- 🏠 **Community Hub**: Share and download community effects
- 🎫 **Verification Codes**: Roblox generates codes → Website validates them
- 🔄 **Real-time**: WebSocket service (Socket.IO) for Website ↔ Roblox communication

## Tech Stack

- **Framework**: Next.js 16 (App Router) + TypeScript
- **Styling**: Tailwind CSS 4 + shadcn/ui
- **Database**: Prisma ORM with SQLite
- **State**: Zustand + TanStack Query
- **Real-time**: Socket.IO ([The-Blur-WS repo](https://github.com/J-ohan1/The-Blur-WS))
- **Runtime**: Bun

## Project Structure

```
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── api/                # API routes
│   │   │   ├── auth/           # Login, verify, session, link
│   │   │   ├── showfile/       # CRUD + import/export
│   │   │   ├── hub/            # Community effects
│   │   │   ├── blacklist/      # Blacklist management
│   │   │   ├── whitelist/      # Whitelist management
│   │   │   └── roblox/         # Roblox access data
│   │   └── page.tsx            # Main SPA page
│   ├── components/
│   │   ├── blur/               # App-specific components
│   │   └── ui/                 # shadcn/ui components
│   ├── contexts/               # Auth context
│   ├── hooks/                  # Custom hooks
│   ├── lib/                    # Utilities (auth, db, etc.)
│   └── store/                  # Zustand stores
├── prisma/
│   └── schema.prisma           # Database schema
└── public/                     # Static assets
```

## Getting Started

### Prerequisites

- [Bun](https://bun.sh/) >= 1.0
- Node.js >= 18

### Installation

```bash
# Clone the repo
git clone https://github.com/J-ohan1/The-Blur-Website.git
cd The-Blur-Website

# Install dependencies
bun install

# Copy environment file
cp .env.example .env

# Set up database
bun run db:push

# Start the Next.js dev server (port 3000)
bun run dev
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | SQLite database path | `file:./dev.db` |
| `WS_SERVICE_URL` | WebSocket service URL | `http://localhost:3003` |
| `WEBSITE_URL` | Public website URL | `http://localhost:3000` |

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

## User Roles

| Role | Capabilities |
|------|-------------|
| **Staff** | Full admin access, manage users, blacklist/whitelist |
| **Whitelisted** | Full laser control, create/edit/delete showfiles, publish to Hub |
| **Temp Whitelisted** | Limited laser control, can only delete own creations, expires after set time |
| **Normal** | Can only view/rave (no laser control) |
| **Blacklisted** | Instantly kicked from game |

## .blur File Format

The custom `.blur` file format for showfile import/export:

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

## Deployment

### Vercel (Website)

1. Push to GitHub
2. Import repo in Vercel
3. Set environment variables
4. Deploy

### WebSocket Service (Justrunmyapp or similar)

1. Deploy the `mini-services/laser-ws` service
2. Set the `WS_SERVICE_URL` environment variable on the website
3. Ensure CORS is configured for the website domain

## License

Private — All rights reserved.
