-- Migration 016: Agent Friendly API — digest cache + webhooks

-- ── Digest cache (subscription_hash → shared LLM result) ──
CREATE TABLE IF NOT EXISTS digest_cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  hash TEXT NOT NULL,          -- subscription_hash = SHA256(sorted source_ids)
  type TEXT NOT NULL,          -- '4h', 'daily', 'weekly', 'monthly'
  content TEXT NOT NULL,
  item_count INTEGER DEFAULT 0,
  source_count INTEGER DEFAULT 0,
  model TEXT,
  created_at DATETIME DEFAULT (datetime('now')),
  expires_at DATETIME          -- NULL = no expiry, or set to now + interval
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_digest_cache_hash_type ON digest_cache(hash, type);
CREATE INDEX IF NOT EXISTS idx_digest_cache_created ON digest_cache(created_at);

-- ── Webhooks ──
CREATE TABLE IF NOT EXISTS webhooks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  secret TEXT NOT NULL,        -- HMAC-SHA256 signing secret
  events TEXT NOT NULL DEFAULT '["digest.created","source.updated"]', -- JSON array
  is_active INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT (datetime('now')),
  last_triggered_at DATETIME,
  failure_count INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_webhooks_user ON webhooks(user_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_active ON webhooks(is_active);

-- ── Webhook delivery log ──
CREATE TABLE IF NOT EXISTS webhook_deliveries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  webhook_id INTEGER NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
  event TEXT NOT NULL,
  payload TEXT NOT NULL,       -- JSON
  status INTEGER,              -- HTTP response status (NULL = pending/failed)
  response_body TEXT,
  error TEXT,
  created_at DATETIME DEFAULT (datetime('now')),
  delivered_at DATETIME
);
CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_webhook ON webhook_deliveries(webhook_id);
CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_created ON webhook_deliveries(created_at);

-- ── API keys (for agent/programmatic access) ──
CREATE TABLE IF NOT EXISTS api_keys (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  key_hash TEXT UNIQUE NOT NULL, -- SHA256 of the actual key
  key_prefix TEXT NOT NULL,      -- first 8 chars for display
  name TEXT,
  scopes TEXT NOT NULL DEFAULT '["read"]', -- JSON array: "read", "write", "webhooks"
  is_active INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT (datetime('now')),
  last_used_at DATETIME,
  expires_at DATETIME          -- NULL = no expiry
);
CREATE INDEX IF NOT EXISTS idx_api_keys_user ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys(key_hash);
