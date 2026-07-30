# ClawFeed

AI-powered news digest tool. Automatically generates structured summaries (4H/daily/weekly/monthly) from Twitter and RSS feeds.

## Credentials & Dependencies

ClawFeed runs in **read-only mode** with zero credentials — browse digests, view feeds, switch languages. Authentication features require OAuth or the administrative API key.

| Credential | Purpose | Required |
|-----------|---------|----------|
| `GOOGLE_CLIENT_ID` | Google OAuth login | For auth features |
| `GOOGLE_CLIENT_SECRET` | Google OAuth login | For auth features |
| `SESSION_SECRET` | Session cookie encryption | For auth features |
| `API_KEY` | Digest, config, and source administration | For agent writes |
| Xquik API key | TweetClaw public X reads | For optional X sources |

**Runtime dependencies:** SQLite via `better-sqlite3` (native addon, bundled).
TweetClaw is an optional, separately installed OpenClaw plugin for X sources.
No external database server is required.

## Setup

```bash
# Install dependencies
npm install

# Copy environment config
cp .env.example .env
# Edit .env with your settings

# Start API server
npm start
```

## Environment Variables

Configure in `.env` file:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DIGEST_PORT` | Server port | No | 8767 |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | For auth | - |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | For auth | - |
| `SESSION_SECRET` | Session cookie encryption key | For auth | - |
| `API_KEY` | Digest, config, and source administration | For agent writes | - |
| `DIGEST_DB` | SQLite database path | No | `data/digest.db` |
| `ALLOWED_ORIGINS` | CORS allowed origins | No | localhost |

## API Server

Runs on port `8767` by default. Set `DIGEST_PORT` env to change.

### Endpoints

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /api/digests | List digests (?type=4h\|daily\|weekly&limit=20&offset=0) | - |
| GET | /api/digests/:id | Get single digest | - |
| POST | /api/digests | Create digest (internal) | API key |
| GET | /api/sources | List sources | Optional; API key lists all |
| POST | /api/sources | Create source | Session or API key |
| PUT | /api/sources/:id | Update source | Owner or API key |
| DELETE | /api/sources/:id | Soft-delete source | Owner or API key |
| GET | /api/auth/google | Start Google OAuth flow | - |
| GET | /api/auth/callback | OAuth callback endpoint | - |
| GET | /api/auth/me | Get current user info | Yes |
| POST | /api/auth/logout | Logout user | Yes |
| GET | /api/marks | List user bookmarks | Yes |
| POST | /api/marks | Add bookmark | Yes |
| DELETE | /api/marks/:id | Remove bookmark | Yes |
| GET | /api/config | Get configuration | - |
| PUT | /api/config | Update configuration | API key |

## Web Dashboard

Serve `web/index.html` via your reverse proxy or any static file server.

## Templates

- `templates/curation-rules.md` — Customize feed curation rules
- `templates/digest-prompt.md` — Customize the AI summarization prompt

## Configuration

Copy `config.example.json` to `config.json` and edit. See README for details.

## Optional X Sources With TweetClaw

ClawFeed stores source definitions and finished digests. The current server does
not fetch X content itself. For `twitter_feed` and `twitter_list` sources, use
TweetClaw's `explore` and `tweetclaw` tools inside OpenClaw. Build a reviewed,
cited digest and submit it through `POST /api/digests`.

Follow `docs/tweetclaw-x-sources.md` for installation, source registration,
exact read flow, cost approval, untrusted-content handling, and write
boundaries.

## Reverse Proxy (Caddy example)

```
handle /digest/api/* {
    uri strip_prefix /digest/api
    reverse_proxy localhost:8767
}
handle_path /digest/* {
    root * /path/to/clawfeed/web
    file_server
}
```
