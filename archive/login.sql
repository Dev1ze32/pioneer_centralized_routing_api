-- ============================================================================
-- Users Table + Helpers for ACU Routing API Auth System
-- ============================================================================
-- Run this against your PostgreSQL database to create the users table,
-- role constraint, and indexes.
--
-- Example:
--   psql -U postgres -d routing_db -f 01_users.sql
-- ============================================================================

-- Drop if exists (careful: this deletes all user data)
-- DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(50) NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    role            VARCHAR(20) NOT NULL DEFAULT 'user',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Only allow valid roles: user (read-only), superuser (read/write),
    -- admin (full access including user management)
    CONSTRAINT users_role_check
        CHECK (role IN ('user', 'superuser', 'admin'))
);

-- Index for fast username lookups during login
CREATE INDEX IF NOT EXISTS idx_users_username
    ON users (username);

-- Index for filtering by role (useful for admin user listing)
CREATE INDEX IF NOT EXISTS idx_users_role
    ON users (role);

-- Partial index to quickly find active users only
CREATE INDEX IF NOT EXISTS idx_users_active
    ON users (id) WHERE is_active = TRUE;

-- ============================================================================
-- Auto-update `updated_at` on every row modification
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_users_updated_at ON users;

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Create a default admin user (change password after first login!)
-- This is a convenience for bootstrapping — the password hash below is
-- for 'changeme123' hashed with Argon2id.
--
-- IMPORTANT: Delete or disable this account after creating your own admin.
-- ============================================================================

INSERT INTO users (username, password_hash, role, is_active)
VALUES (
    'admin',
    '$argon2id$v=19$m=65536,t=3,p=4$MTIzNDU2Nzg5MGFiY2RlZg$ fakeplaceholder_donotuse',
    'admin',
    TRUE
)
ON CONFLICT (username) DO NOTHING;

-- NOTE: The above admin password is intentionally invalid.
-- Use the /api/auth/register endpoint (first registration is allowed)
-- or manually insert a properly Argon2-hashed password via the auth_utils.