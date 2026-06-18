-- =============================================================================
-- Migration: Create activity_logs table
-- Run this once against your PostgreSQL database.
-- =============================================================================

CREATE TABLE IF NOT EXISTS activity_logs (
    id          BIGSERIAL PRIMARY KEY,
    logged_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Who did it
    user_id     INTEGER     REFERENCES users(id) ON DELETE SET NULL,
    username    VARCHAR(50) NOT NULL,           -- snapshot in case user is deleted
    user_role   VARCHAR(20) NOT NULL,

    -- What happened (human-readable)
    action      VARCHAR(80) NOT NULL,           -- e.g. "Deleted product"
    description TEXT        NOT NULL,           -- full sentence
    
    -- Extra context (optional, nullable)
    target_type VARCHAR(40),                    -- "product" | "activity" | "user" | "session"
    target_id   VARCHAR(100),                   -- inventory_id, activity id, user id, etc.
    ip_address  VARCHAR(45),                    -- IPv4 or IPv6
    extra       JSONB                           -- any additional key/value pairs
);

-- Index for the admin list view (most-recent-first, fast range scan by date)
CREATE INDEX IF NOT EXISTS idx_activity_logs_logged_at
    ON activity_logs (logged_at DESC);

-- Index to look up all actions by a specific user
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id
    ON activity_logs (user_id);

-- Comment
COMMENT ON TABLE activity_logs IS
    'Human-readable audit trail. Rows older than 90 days are purged automatically '
    'by the /api/logs/cleanup endpoint or a scheduled job.';