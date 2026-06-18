-- ============================================
-- Fix existing books with missing seller_name
-- Run this in Supabase SQL Editor
-- ============================================

-- First, check what columns exist in profiles
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'profiles';

-- Update books with empty seller_name using the seller's profile full_name
UPDATE books b
SET seller_name = (
  SELECT p.full_name FROM profiles p WHERE p.id = b.seller_id
)
WHERE (b.seller_name IS NULL OR b.seller_name = '')
  AND b.seller_id IS NOT NULL;

-- Verify the fix
SELECT
  id,
  title,
  seller_id,
  seller_name,
  seller_college,
  seller_city
FROM books
WHERE seller_name IS NULL OR seller_name = ''
ORDER BY created_at DESC;

-- Show updated books
SELECT
  'Books with seller_name now populated:' as info,
  COUNT(*) as count
FROM books
WHERE seller_name IS NOT NULL AND seller_name != '';
