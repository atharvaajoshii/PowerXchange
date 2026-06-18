-- ============================================
-- Add seller detail columns to books table
-- Run this in Supabase SQL Editor
-- ============================================

-- Add seller contact columns if they don't exist
ALTER TABLE books
ADD COLUMN IF NOT EXISTS seller_phone TEXT,
ADD COLUMN IF NOT EXISTS seller_email TEXT,
ADD COLUMN IF NOT EXISTS seller_address TEXT,
ADD COLUMN IF NOT EXISTS seller_city TEXT,
ADD COLUMN IF NOT EXISTS seller_pincode TEXT,
ADD COLUMN IF NOT EXISTS seller_college TEXT,
ADD COLUMN IF NOT EXISTS seller_location TEXT;

-- Add index for seller_id lookups (including college for display)
CREATE INDEX IF NOT EXISTS idx_books_seller_college ON books(seller_id, seller_college);

-- Verify columns were added
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'books'
  AND column_name LIKE 'seller_%'
ORDER BY column_name;
