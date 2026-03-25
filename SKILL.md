---
name: clawfeed
description: Use this skill to operate the current ClawFeed app safely through its real API and UI capabilities. This skill can serve the dashboard, browse digests, manage sources and bookmarks, and manually write digests. It must not claim that automatic source fetching or automatic digest generation already exists unless the repository gains those runtime entrypoints.
---

# ClawFeed

Use this skill to operate the ClawFeed repository as it exists now.

This repository currently provides:

- A Node.js API server and web dashboard
- SQLite-backed storage for digests, marks, sources, packs, subscriptions, and auth sessions
- Public digest browsing endpoints
- Authenticated source and bookmark management
- A protected `POST /api/digests` endpoint that writes a digest record to the database

This repository does not currently provide a complete runtime pipeline for:

- Fetching content from a `source`
- Running AI summarization from that fetched content
- Scheduling digest generation with a built-in cron or worker
- Turning a `twitter_list` source directly into a digest with a single command

Do not infer those missing capabilities from product copy or roadmap docs.

## Capability Boundaries

### Supported now

- Start the ClawFeed API server
- Serve or inspect the dashboard
- Read digest lists and individual digests
- Create a digest only when digest content is already prepared
- Manage marks/bookmarks through the API
- Manage sources through the API
- Inspect the database and current source state

### Not supported now

- Automatic source collection
- Automatic digest generation from sources
- Built-in cron jobs or workers for digest generation
- Direct summarization of X/Twitter lists through an implemented local pipeline

If a user asks for unsupported behavior, state the gap clearly and stop pretending the pipeline exists.

## How To Work

### 1. Confirm the request type

Map the user request to one of these categories:

- Browse digests
- Run or inspect the dashboard/API
- Manage bookmarks/marks
- Manage sources
- Manually insert a digest
- Investigate why automatic generation is not working
- Implement missing pipeline code

### 2. Start from the real runtime

Use the repository scripts that actually exist:

```bash
npm install
npm start
```

The API server runs on port `8767` by default.

If needed, create a `.env` file from `.env.example` and set values only for features being used.

### 3. Validate available endpoints

Use the running API rather than assumptions. The core currently implemented paths are:

- `GET /api/digests`
- `GET /api/digests/:id`
- `POST /api/digests`
- `GET /api/marks`
- `POST /api/marks`
- `DELETE /api/marks/:id`
- `GET /api/sources`
- `POST /api/sources`
- `PUT /api/sources/:id`
- `DELETE /api/sources/:id`

### 4. Choose the correct path for the task

If the user wants to browse or inspect digests:

- Start the server if needed
- Use `GET /api/digests` or `GET /api/digests/:id`

If the user wants bookmarks or marks:

- Use the marks endpoints
- These require authentication

If the user wants source management:

- Use the sources endpoints
- These require authentication

If the user wants to create a digest record:

- Only use `POST /api/digests` when the digest content already exists
- Treat this as a write operation, not as generation

If the user wants a digest generated from a source:

- Explain that the current repository does not expose a collector or summarizer runtime entrypoint
- Check whether the source has ever been fetched
- If `fetch_count = 0` or `last_fetched_at = null`, explain that the source is only registered, not collected
- Offer one of these fallback paths:
  - Manually produce digest content outside this pipeline, then write it with `POST /api/digests`
  - Implement the missing fetch/summarize/write pipeline in code

## Important Rules

- Do not claim there is a working cron unless you can point to an actual command or scheduler configuration in this repository.
- Do not claim there is a worker unless you can point to an implemented runtime entrypoint.
- Do not treat `POST /api/digests` as "generate digest from source". It only persists a digest payload.
- Do not assume a `twitter_list` source can be fetched just because its record exists in the database.
- Do not describe roadmap or architecture documents as if they are live features.

## Interpreting Source State

When diagnosing a source, inspect its stored state before promising anything.

Signs that a source is only registered and has not been processed:

- `fetch_count = 0`
- `last_fetched_at = null`

That means the source exists in the database, but the collection pipeline has not run for it.

## What To Say When The User Expects Automatic Digests

Use a direct explanation:

- The source record exists.
- The current repository does not include a runnable collector plus summarizer pipeline.
- The app can store digests and manage sources, but it cannot yet turn this source into a digest automatically from the current local entrypoints.

Then offer the next concrete options:

- Start and validate the existing ClawFeed server
- Manually insert a prepared digest
- Implement the missing minimal pipeline

## Credentials And Dependencies

ClawFeed can run in read-only mode without OAuth credentials.

| Credential | Purpose | Required |
|-----------|---------|----------|
| `GOOGLE_CLIENT_ID` | Google OAuth login | Only for auth features |
| `GOOGLE_CLIENT_SECRET` | Google OAuth login | Only for auth features |
| `SESSION_SECRET` | Session cookie encryption | Only for auth features |
| `API_KEY` | Protect `POST /api/digests` | Only for digest writes |

Runtime dependency:

- SQLite via `better-sqlite3`

## Customization Files

- `templates/curation-rules.md`
- `templates/digest-prompt.md`

These files describe curation and formatting, but they do not by themselves create a runnable fetch or summarization pipeline.
