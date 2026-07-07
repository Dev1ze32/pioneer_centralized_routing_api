-- =============================================================================
-- Migration: Add created_at / updated_at timestamps to products table
--
-- Safe to run multiple times (IF NOT EXISTS guards each step).
-- Run this against the live DB BEFORE deploying the updated backend code.
-- =============================================================================

-- 1. Add created_at column
ALTER TABLE public.products
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Add updated_at column
ALTER TABLE public.products
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 3. Back-fill created_at from the earliest audit log entry for each product.
--    If no log entry exists (product pre-dates audit logging), keep NOW().
UPDATE public.products p
SET created_at = COALESCE(
    (
        SELECT MIN(al.logged_at)
        FROM   public.activity_logs al
        WHERE  al.target_type = 'product'
          AND  UPPER(al.target_id) = UPPER(p.inventory_id)
          AND  al.action = 'Created product'
    ),
    NOW()
);

-- 4. Set updated_at = created_at for all existing rows as a sane baseline.
UPDATE public.products
SET updated_at = created_at;

-- 5. Attach the existing trigger so future UPDATEs auto-bump updated_at.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE  tgname   = 'set_products_updated_at'
          AND  tgrelid  = 'public.products'::regclass
    ) THEN
        CREATE TRIGGER set_products_updated_at
        BEFORE UPDATE ON public.products
        FOR EACH ROW
        EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END;
$$;

-- Verify
SELECT inventory_id, created_at, updated_at
FROM public.products
ORDER BY created_at
LIMIT 10;
