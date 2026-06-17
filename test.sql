ALTER TABLE public.products

    ADD COLUMN quantity double precision;

 

-- Drops the unused qty_required column from activities.
-- Every row currently has this as NULL — it was never wired up to
-- anything in the app, so it's safe to remove.
-- Run this AFTER deploying the updated update.py (which no longer
-- references qty_required), so the running app never hits a
-- "column does not exist" error mid-deploy.

ALTER TABLE public.activities
    DROP COLUMN qty_required;