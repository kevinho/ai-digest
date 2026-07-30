# ClawFeed — Test Suite

## Index

| Section | Category | Tests | Status |
|---------|----------|-------|--------|
| [1](#1-authentication-6-tests) | Authentication | 6 | ✅ |
| [2](#2-digest-browsing--public-3-tests) | Digest Browsing (public) | 3 | ✅ |
| [3](#3-sources--crud--visibility-16-tests) | Sources CRUD + Visibility | 16 | ✅ |
| [4](#4-source-ownership-4-tests) | Source Ownership | 4 | ✅ |
| [5](#5-packs--create--share-4-tests) | Packs Create + Share | 4 | ✅ |
| [6](#6-pack-install--fresh-user-5-tests) | Pack Install (fresh user) | 5 | ✅ |
| [7](#7-pack-dedup-2-tests) | Pack Dedup | 2 | ✅ |
| [8](#8-cross-install-with-overlap-1-test) | Cross-Install Overlap | 1 | ✅ |
| [9](#9-subscription-management-2-tests) | Subscription Management | 2 | ✅ |
| [10](#10-marks--crud--isolation-9-tests) | Marks CRUD + Isolation | 9 | ✅ |
| [11](#11-data-isolation-2-tests) | Data Isolation | 2 | ✅ |
| [12](#12-feed-output-4-tests) | Feed Output | 4 | ✅ |
| [13](#13-api-security-5-tests) | API Security | 5 | ✅ |
| [14](#14-edge-cases-2-tests--2-diagnostics) | Edge Cases | 2 + 2 diagnostics | ✅ |
| [15](#15-source-deletion--subscriber-impact-3-tests) | Source Deletion Cascade | 3 | ✅ |
| [16](#16-soft-delete-sources-7-tests) | Soft Delete Sources | 7 | ✅ |
| [17](#17-source-dedup-at-scale-planned) | Source Dedup at Scale | 5 | 🔜 |
| [18](#18-subscription-volume-planned) | Subscription Volume | 3 | 🔜 |

**Total: 75 active ✅ + 8 planned 🔜 = 83**

---

## Quick Start

```bash
# 1. Setup test users (creates 4 fake users in DB)
bash test/setup.sh

# 2. Run E2E tests
bash test/e2e.sh

# 3. Teardown (removes all test data)
bash test/teardown.sh
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AI_DIGEST_API` | `http://127.0.0.1:8767/api` | API base URL |
| `AI_DIGEST_FEED` | `http://127.0.0.1:8767/feed` | Feed base URL |
| `AI_DIGEST_DB` | `../data/test.db` (relative) | Isolated SQLite test DB |
| `API_KEY` | unset | Run the 9 API-key source administration tests |
| `ALLOW_REMOTE_E2E` | `0` | Permit an explicitly isolated remote target |

### Local Testing

```bash
AI_DIGEST_API=http://localhost:8767/api \
AI_DIGEST_FEED=http://localhost:8767/feed \
bash test/e2e.sh
```

The suite refuses non-loopback API targets by default because it creates,
updates, and deletes data. Set `ALLOW_REMOTE_E2E=1` only for an isolated
non-production environment.

---

## Test Users

| User | ID | Session Cookie | Role |
|------|----|----------------|------|
| Alice | 100 | `test-sess-alice` | Creates sources & packs |
| Bob | 101 | `test-sess-bob` | Cross-user isolation tests |
| Carol | 102 | `test-sess-carol` | Fresh user (pack install) |
| Dave | 103 | `test-sess-dave` | Additional install tests |

ID range 100–199 reserved for test data; teardown cleans by range.

---

## Test Cases

### 1. Authentication (6 tests)
| # | Case | Method |
|---|------|--------|
| 1.1 | Alice auth returns correct name | `GET /auth/me` |
| 1.2 | Bob auth returns correct name | `GET /auth/me` |
| 1.3 | Carol auth returns correct name | `GET /auth/me` |
| 1.4 | Dave auth returns correct name | `GET /auth/me` |
| 1.5 | Visitor (no cookie) → "not authenticated" | `GET /auth/me` |
| 1.6 | Invalid session cookie → 401 | `GET /auth/me` |

### 2. Digest Browsing — Public (3 tests)
| # | Case | Method |
|---|------|--------|
| 2.1 | 4H digest list (no auth required) | `GET /digests?type=4h` |
| 2.2 | Daily digest list | `GET /digests?type=daily` |
| 2.3 | Weekly digest list | `GET /digests?type=weekly` |

### 3. Sources — CRUD + Visibility (16 tests)
| # | Case | Method |
|---|------|--------|
| 3.1 | Alice creates 3 sources (2 public, 1 private) | `POST /sources` ×3 |
| 3.2 | Alice auto-subscribed to all 3 | `GET /subscriptions` |
| 3.3 | Bob creates 1 public source | `POST /sources` |
| 3.4 | Visitor sees Alice's public sources | `GET /sources` |
| 3.5 | Visitor cannot see private sources | `GET /sources` (negative) |
| 3.6 | Visitor sees Bob's public source | `GET /sources` |
| 3.7 | Visitor cannot create sources → 401 | `POST /sources` |
| 3.8 | API key creates a private source | `POST /sources` |
| 3.9 | API key reads the private source | `GET /sources/:id` |
| 3.10 | Object config is serialized | `GET /sources/:id` |
| 3.11 | API key lists the private source | `GET /sources` |
| 3.12 | Visitor cannot read the private source → 404 | `GET /sources/:id` |
| 3.13 | API key updates the source | `PUT /sources/:id` |
| 3.14 | Object config update is serialized | `GET /sources/:id` |
| 3.15 | Wrong API key cannot update the source → 401 | `PUT /sources/:id` |
| 3.16 | API key deletes the source | `DELETE /sources/:id` |

### 4. Source Ownership (4 tests)
| # | Case | Method |
|---|------|--------|
| 4.1 | Bob cannot delete Alice's source → 403 | `DELETE /sources/:id` |
| 4.2 | Alice deletes her private source | `DELETE /sources/:id` |
| 4.3 | Alice retains the soft-deleted subscription | `GET /subscriptions` |
| 4.4 | Deleted subscription exposes `sourceDeleted` | `GET /subscriptions` |

### 5. Packs — Create + Share (4 tests)
| # | Case | Method |
|---|------|--------|
| 5.1 | Alice creates pack from her sources | `POST /packs` |
| 5.2 | Pack in public list | `GET /packs` |
| 5.3 | Pack detail accessible | `GET /packs/:slug` |
| 5.4 | Visitor cannot install pack → 401 | `POST /packs/:slug/install` |

### 6. Pack Install — Fresh User (5 tests)
| # | Case | Method |
|---|------|--------|
| 6.1 | Carol starts with 0 subscriptions | `GET /subscriptions` |
| 6.2 | Carol installs Alice's pack | `POST /packs/:slug/install` |
| 6.3 | Install reports 2 added sources | `POST /packs/:slug/install` |
| 6.4 | Carol subscribed to Alice's RSS | `GET /subscriptions` |
| 6.5 | Carol subscribed to Alice's HN | `GET /subscriptions` |

### 7. Pack Dedup (2 tests)
| # | Case | Method |
|---|------|--------|
| 7.1 | Re-install → 0 added | `POST /packs/:slug/install` |
| 7.2 | Dave installs same pack → 2 added | `POST /packs/:slug/install` |

### 8. Cross-Install with Overlap (1 test)
| # | Case | Method |
|---|------|--------|
| 8.1 | Bob (already subscribed to 1) installs pack → partial add | `POST /packs/:slug/install` |

### 9. Subscription Management (2 tests)
| # | Case | Method |
|---|------|--------|
| 9.1 | Carol unsubscribes → count decreases | `DELETE /subscriptions/:sourceId` |
| 9.2 | Carol re-subscribes → count restores | `POST /subscriptions` |

### 10. Marks — CRUD + Isolation (9 tests)
| # | Case | Method |
|---|------|--------|
| 10.1 | Alice creates mark | `POST /marks` |
| 10.2 | Bob creates mark on same digest | `POST /marks` |
| 10.3 | Alice sees her mark | `GET /marks` |
| 10.4 | Alice cannot see Bob's mark | `GET /marks` (negative) |
| 10.5 | Bob sees his mark | `GET /marks` |
| 10.6 | Bob cannot see Alice's mark | `GET /marks` (negative) |
| 10.7 | Carol has 0 marks | `GET /marks` |
| 10.8 | Visitor → 401 | `GET /marks` |
| 10.9 | Alice deletes her mark | `DELETE /marks/:id` |

### 11. Data Isolation (2 tests)
| # | Case | Method |
|---|------|--------|
| 11.1 | Alice's subscriptions are hers only | `GET /subscriptions` |
| 11.2 | Bob's subscriptions include his source | `GET /subscriptions` |

### 12. Feed Output (4 tests)
| # | Case | Method |
|---|------|--------|
| 12.1 | JSON Feed → 200 | `GET /feed/kevin.json` |
| 12.2 | JSON Feed valid format | `GET /feed/kevin.json` |
| 12.3 | RSS Feed → 200 | `GET /feed/kevin.rss` |
| 12.4 | Invalid slug → 404 | `GET /feed/xxx.json` |

### 13. API Security (5 tests)
| # | Case | Method |
|---|------|--------|
| 13.1 | POST digests without API key → 401 | `POST /digests` |
| 13.2 | Create source without login → 401 | `POST /sources` |
| 13.3 | Install pack without login → 401 | `POST /packs/:slug/install` |
| 13.4 | Delete source without login → 401 | `DELETE /sources/:id` |
| 13.5 | Access marks without login → 401 | `GET /marks` |

### 14. Edge Cases (2 tests + 2 diagnostics)
| # | Case | Method |
|---|------|--------|
| 14.1 | Triple-install is idempotent | `POST /packs/:slug/install` |
| 14.2 | Double-subscribe handled | `POST /subscriptions` |
| 14.3 | Subscribe to nonexistent source | `POST /subscriptions` |
| 14.4 | Create source with empty name | `POST /sources` (TODO: validate) |

### 15. Source Deletion + Subscriber Impact (3 tests)
| # | Case | Method |
|---|------|--------|
| 15.1 | Alice soft-deletes source → Carol keeps subscription | `DELETE /sources/:id` |
| 15.2 | Carol sees the source as deleted | `GET /subscriptions` |
| 15.3 | Pack still exists after source deletion | `GET /packs/:slug` |

**Total: 75 test assertions**

---

### 16. Soft Delete Sources (7 tests)
| # | Case | Method |
|---|------|--------|
| 16.1 | Delete source → `is_deleted=1`, not removed from DB | `DELETE /sources/:id` |
| 16.2 | Deleted source hidden from `GET /sources` | `GET /sources` |
| 16.3 | Subscriber sees deleted source as "已停用" | `GET /subscriptions` |
| 16.4 | Pack install skips deleted source (no zombie) | `POST /packs/:slug/install` |
| 16.5 | Pack install skips deleted, creates non-deleted only | `POST /packs/:slug/install` (mixed) |
| 16.6 | Re-install after source deleted → 0 added (not recreated) | `POST /packs/:slug/install` |
| 16.7 | Deleted source is absent from active sources | `GET /sources` |

### 17. Source Dedup at Scale (planned)
| # | Case | Method |
|---|------|--------|
| 17.1 | Two users create same RSS URL → same source, not duplicate | `POST /sources` ×2 |
| 17.2 | Subscribe to existing public source (no new row in sources) | `POST /subscriptions` |
| 17.3 | Pack install matches by type+config, reuses existing source | `POST /packs/:slug/install` |
| 17.4 | Bulk subscribe 100 sources (perf baseline) | `POST /subscriptions/bulk` |
| 17.5 | Same subscription combo = same digest cache key | `GET /api/digest-combinations` (future) |

### 18. Subscription Volume (planned)
| # | Case | Method |
|---|------|--------|
| 18.1 | User with 100 subscriptions → list returns all | `GET /subscriptions` |
| 18.2 | Source with 100 subscribers → subscriber count correct | `GET /sources/:id` |
| 18.3 | Delete source with 100 subscribers → all subs marked inactive | `DELETE /sources/:id` |

---

## Known Issues / TODOs

- [ ] Empty source name accepted (no server-side validation) — test 14.4
- [ ] Pack stores JSON snapshot; source deletion creates zombie data — test 15.2 (see ARCHITECTURE.md)
- [ ] Subscribe to nonexistent source doesn't return 404
- [ ] Mark deletion of nonexistent ID behavior undefined

---

## Iteration Log

### v1 — 2026-02-22
- Initial E2E suite: 44 tests across 14 categories
- 3 test users (Elon, Kevin, Coco) with hardcoded sessions
- Manual browser testing for UI flows

### v3 — 2026-02-22 (planned)
- Soft delete test cases (Section 16): 7 tests covering is_deleted flag, pack skip, no zombie
- Source dedup tests (Section 17): 5 tests for same-URL dedup, type+config matching
- Subscription volume tests (Section 18): 3 tests for scale baseline (100 subs/source)
- Total planned: ~67 assertions

### v2 — 2026-02-22
- Refactored to 4 test users (Alice, Bob, Carol, Dave) with ID range 100-199
- Added setup.sh / teardown.sh for clean isolation
- Expanded to 15 categories, ~52 assertions
- Added source deletion cascade tests (Section 15)
- Added edge case tests (Section 14)
- Helper functions: `check`, `check_not`, `check_code`, `jq_val`, `jq_len`
