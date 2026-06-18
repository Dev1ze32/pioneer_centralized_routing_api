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


-- Drop the duplicate
ALTER TABLE public.products DROP CONSTRAINT fk_products_production_line;

-- Fix: add ON UPDATE CASCADE to the FG FK as well
ALTER TABLE public.products DROP CONSTRAINT fk_products_fg_line;
ALTER TABLE public.products ADD CONSTRAINT fk_products_fg_line
    FOREIGN KEY (fg_production_line_code)
    REFERENCES public.production_lines(production_line_code)
    ON UPDATE CASCADE;

ALTER TABLE public.activities ALTER COLUMN activity_name SET NOT NULL;

DELETE FROM products WHERE inventory_id = '1234567890';