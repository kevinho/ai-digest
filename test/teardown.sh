#!/bin/bash
# Clean up all test data — removes test users and everything they created
set -e

DB="${AI_DIGEST_DB:-$(dirname "$0")/../data/test.db}"

echo "🧹 Tearing down test environment"

sqlite3 "$DB" "
-- Delete in dependency order
DELETE FROM user_subscriptions WHERE user_id BETWEEN 100 AND 199;
DELETE FROM marks WHERE user_id BETWEEN 100 AND 199;
DELETE FROM source_packs WHERE created_by BETWEEN 100 AND 199;
DELETE FROM sources WHERE created_by BETWEEN 100 AND 199;
DELETE FROM sessions WHERE user_id BETWEEN 100 AND 199;
DELETE FROM users WHERE id BETWEEN 100 AND 199;
"

echo "✅ All test users (id 100-199) and their data removed"
