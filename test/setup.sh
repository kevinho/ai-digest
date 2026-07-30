#!/bin/bash
# Test environment setup — creates fake users + sessions for multi-user testing
set -e

DB="${AI_DIGEST_DB:-$(dirname "$0")/../data/test.db}"
API="${AI_DIGEST_API:-http://127.0.0.1:8767/api}"

echo "🧪 Setting up test environment"
echo "   DB: $DB"
echo "   API: $API"

# ── Create test users (id 100-103, won't collide with real users) ──
sqlite3 "$DB" "
-- Test users
INSERT OR IGNORE INTO users (id, google_id, email, name, avatar, slug)
VALUES
  (100, 'test-alice', 'alice@test.local', 'Alice (Test)', '', 'alice-test'),
  (101, 'test-bob',   'bob@test.local',   'Bob (Test)',   '', 'bob-test'),
  (102, 'test-carol', 'carol@test.local', 'Carol (Test)', '', 'carol-test'),
  (103, 'test-dave',  'dave@test.local',  'Dave (Test)',  '', 'dave-test');

-- Test sessions (24h expiry)
INSERT OR REPLACE INTO sessions (id, user_id, expires_at) VALUES
  ('test-sess-alice', 100, datetime('now', '+1 day')),
  ('test-sess-bob',   101, datetime('now', '+1 day')),
  ('test-sess-carol', 102, datetime('now', '+1 day')),
  ('test-sess-dave',  103, datetime('now', '+1 day'));
"

echo ""
echo "✅ 4 test users created:"
echo "   Alice (id=100)  cookie: session=test-sess-alice"
echo "   Bob   (id=101)  cookie: session=test-sess-bob"
echo "   Carol (id=102)  cookie: session=test-sess-carol"
echo "   Dave  (id=103)  cookie: session=test-sess-dave"

# Verify API connectivity
for name in alice bob carol dave; do
  uid=$(curl -sf "$API/auth/me" -H "Cookie: session=test-sess-$name" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null)
  if [ -z "$uid" ]; then
    echo "   ❌ $name: auth failed"
  else
    echo "   ✅ $name: verified (id=$uid)"
  fi
done

echo ""
echo "🔧 Usage:"
echo '   ALICE="Cookie: session=test-sess-alice"'
echo "   curl -s \"\$API/auth/me\" -H \"\$ALICE\""
echo ""
echo "🧹 Teardown: bash test/teardown.sh"
