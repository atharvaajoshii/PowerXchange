-- ============================================
-- TEST SCRIPT FOR NOTIFICATIONS AND ORDERS
-- Run this in Supabase SQL Editor to test the system
-- ============================================

-- 1. Check if tables exist and have RLS enabled
SELECT 
  tablename, 
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('notifications', 'transactions', 'books', 'profiles')
ORDER BY tablename;

-- 2. Check RLS policies
SELECT 
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies 
WHERE tablename IN ('notifications', 'transactions')
ORDER BY tablename, policyname;

-- 3. Check if sample data exists
SELECT 
  'notifications' as table_name, 
  COUNT(*) as total_rows,
  COUNT(*) FILTER (WHERE is_read = false) as unread_count
FROM notifications

UNION ALL

SELECT 
  'transactions' as table_name,
  COUNT(*) as total_rows,
  COUNT(*) FILTER (WHERE status = 'pending') as pending_count
FROM transactions;

-- 4. Test transaction insertion (this should work if RLS is correct)
-- Note: This will fail if no authenticated user context, but shows the structure
-- INSERT INTO transactions (book_id, buyer_id, seller_id, price, status, notes)
-- VALUES 
--   ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003', 500, 'pending', 'Buyer wants to purchase this book');

-- 5. Test notification insertion
-- INSERT INTO notifications (user_id, type, title, message, transaction_id)
-- VALUES 
--   ('00000000-0000-0000-0000-000000000002', 'purchase_request', 'New Purchase Request!', 'Someone wants to buy your book', '00000000-0000-0000-0000-000000000001');

-- 6. Show table structures
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name IN ('notifications', 'transactions')
ORDER BY table_name, ordinal_position;