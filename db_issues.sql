-- =============================================================================
-- Migration: 001_fix_data_issues.sql
-- Fixes the data problems described in database_to_fix.txt:
--
--   #4  Dirty data in products — bm/fg_production_line text doesn't match
--       its production_line_code, plus a doubled item_id prefix on one
--       product's activity.
--   #12 products.quantity is double precision but used as a whole number.
--
-- Safe to run multiple times (idempotent): the UPDATEs are scoped to the
-- exact bad values, and the trigger/constraint are created with
-- CREATE OR REPLACE / DROP IF EXISTS guards.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------
-- 1. Fix the three known dirty rows in products
--    (verified against the dump: these are the only rows where the
--    free-text line column doesn't match the convention used by every
--    other row sharing that production_line_code)
-- -----------------------------------------------------------------------

-- 1PSG9229: both bm/fg text columns held an activity name ("L01 LABELING/
-- CODING") instead of the line name.
UPDATE products
SET bm_production_line = 'L01 - L1 COATINGS',
    fg_production_line = 'L01 - L1 COATINGS'
WHERE inventory_id = '1PSG9229'
  AND bm_production_line = 'L01 LABELING/CODING'
  AND fg_production_line = 'L01 LABELING/CODING';

-- BM000055: both bm/fg text columns held "L06 MIXING" instead of the line name.
UPDATE products
SET bm_production_line = 'L06 - L6 EPOXY LINE',
    fg_production_line = 'L06 - L6 EPOXY LINE'
WHERE inventory_id = 'BM000055'
  AND bm_production_line = 'L06 MIXING'
  AND fg_production_line = 'L06 MIXING';

-- 1APU5A5I04: fg_production_line held a slightly different name
-- ("L01 - Line 01 COATINGS") than the rest of the L01 products use.
-- bm_production_line was already correct.
UPDATE products
SET fg_production_line = 'L01 - L1 COATINGS'
WHERE inventory_id = '1APU5A5I04'
  AND fg_production_line = 'L01 - Line 01 COATINGS';

-- -----------------------------------------------------------------------
-- 2. Fix the doubled line-code prefix in 1APU5A5I04's activity item_ids.
--    The ticket only called out one row ("L01 L01 LABELING/CODING") as an
--    example, but checking the full activities table shows all three of
--    this product's activities have the same doubled prefix
--    ("L01 L01 LETDOWN", "L01 L01 PACKING/PALLETIZ" too) and no other
--    product is affected. Using a regex match/replace instead of one
--    hardcoded string so it catches all of them in one statement.
-- -----------------------------------------------------------------------
UPDATE activities
SET item_id = regexp_replace(item_id, '^([A-Za-z0-9]+) \1 ', '\1 ')
WHERE inventory_id = '1APU5A5I04'
  AND item_id ~ '^([A-Za-z0-9]+) \1 ';

-- -----------------------------------------------------------------------
-- 3. Prevent this drift from recurring: keep bm/fg_production_line text in
--    sync with its *_code automatically, for every line we already have a
--    confirmed canonical label for. (production_line_code is still the
--    source of truth and remains FK-constrained as before; this just stops
--    the free-text column from silently going stale.)
-- -----------------------------------------------------------------------

ALTER TABLE production_lines
    ADD COLUMN IF NOT EXISTS canonical_line_text varchar(100);

-- Canonical text derived from the existing (clean) majority value for each
-- code already in use across products — i.e. exactly what every other row
-- for that code already says.
UPDATE production_lines SET canonical_line_text = 'L01 - L1 COATINGS' WHERE production_line_code = 'L01';
UPDATE production_lines SET canonical_line_text = 'L02 - L2 CYANO BOTTLE FILLING' WHERE production_line_code = 'L02';
UPDATE production_lines SET canonical_line_text = 'L04A - L4A ELASTO MIXING' WHERE production_line_code = 'L04A';
UPDATE production_lines SET canonical_line_text = 'L04B - L4B SEMI AUTO FILLING' WHERE production_line_code = 'L04B';
UPDATE production_lines SET canonical_line_text = 'L04C - L4C ATO FILLING' WHERE production_line_code = 'L04C';
UPDATE production_lines SET canonical_line_text = 'L06 - L6 EPOXY LINE' WHERE production_line_code = 'L06';
UPDATE production_lines SET canonical_line_text = 'L09 - L9 EPS - BLOCKS' WHERE production_line_code = 'L09';
UPDATE production_lines SET canonical_line_text = 'L10 - L10 CONTACT BOND' WHERE production_line_code = 'L10';
UPDATE production_lines SET canonical_line_text = 'L11 - L11 SILICONE FILLING LINE' WHERE production_line_code = 'L11';
UPDATE production_lines SET canonical_line_text = 'L12 - L12 SPECIAL PRODUCTS - EPOXY BASED' WHERE production_line_code = 'L12';
UPDATE production_lines SET canonical_line_text = 'L13 - L13 SPECIAL PRODUCTS - WATER BASED' WHERE production_line_code = 'L13';
UPDATE production_lines SET canonical_line_text = 'L14 - L14 SKIM COAT' WHERE production_line_code = 'L14';
-- NOTE: L03, L05, L07, L08, L09A and SIPS aren't referenced by any product
-- yet, so they're intentionally left NULL here rather than guessed at. The
-- trigger below only enforces a line once it has a canonical_line_text —
-- add one (and it will start being enforced automatically) whenever a real
-- product first uses that line.

CREATE OR REPLACE FUNCTION sync_production_line_text() RETURNS trigger AS $$
DECLARE
    bm_text varchar(100);
    fg_text varchar(100);
BEGIN
    IF NEW.bm_production_line_code IS NOT NULL THEN
        SELECT canonical_line_text INTO bm_text
        FROM production_lines WHERE production_line_code = NEW.bm_production_line_code;
        IF bm_text IS NOT NULL THEN
            NEW.bm_production_line := bm_text;
        END IF;
    END IF;

    IF NEW.fg_production_line_code IS NOT NULL THEN
        SELECT canonical_line_text INTO fg_text
        FROM production_lines WHERE production_line_code = NEW.fg_production_line_code;
        IF fg_text IS NOT NULL THEN
            NEW.fg_production_line := fg_text;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_production_line_text ON products;
CREATE TRIGGER trg_sync_production_line_text
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION sync_production_line_text();

-- -----------------------------------------------------------------------
-- 4. quantity is semantically a whole number — enforce it at the DB level
--    too, not just in the API layer (items.py / update.py already validate
--    this on the way in).
-- -----------------------------------------------------------------------
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_quantity_whole_number;
ALTER TABLE products
    ADD CONSTRAINT products_quantity_whole_number
    CHECK (quantity IS NULL OR quantity = FLOOR(quantity));

COMMIT;

-- -----------------------------------------------------------------------
-- Verification queries (run manually, not part of the migration):
--
SELECT inventory_id, bm_production_line, bm_production_line_code, fg_production_line, fg_production_line_code
   FROM products WHERE inventory_id IN ('1PSG9229', 'BM000055', '1APU5A5I04');
  SELECT id, inventory_id, item_id, activity_name
   FROM activities WHERE inventory_id = '1APU5A5I04';
-- -----------------------------------------------------------------------