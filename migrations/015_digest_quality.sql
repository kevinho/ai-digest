-- Migration 015: Digest quality — source weights, item feedback, topic tracking, cross-source dedup

-- Source weights per user subscription
ALTER TABLE user_subscriptions ADD COLUMN weight REAL DEFAULT 1.0;

-- Item-level feedback (helpful / not_helpful)
CREATE TABLE IF NOT EXISTS item_feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  item_url TEXT NOT NULL,
  item_title TEXT DEFAULT '',
  signal TEXT NOT NULL CHECK(signal IN ('helpful', 'not_helpful')),
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(user_id, item_url)
);
CREATE INDEX IF NOT EXISTS idx_item_feedback_user ON item_feedback(user_id, created_at DESC);

-- Topic tracking: user interest topics (inferred or manual)
CREATE TABLE IF NOT EXISTS user_topics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  topic TEXT NOT NULL,
  score REAL DEFAULT 1.0,
  source TEXT DEFAULT 'manual' CHECK(source IN ('manual', 'inferred')),
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  UNIQUE(user_id, topic)
);
CREATE INDEX IF NOT EXISTS idx_user_topics_user ON user_topics(user_id);
