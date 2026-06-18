-- ============================================
-- FINAL COMPREHENSIVE FIX FOR POWERXCHANGE
-- Run this ONE script to fix all issues
-- ============================================

-- 0. Fix books with invalid seller_id (referencing non-existent profiles)
-- This must run BEFORE recreating the transactions table

-- First, show what will be deleted
SELECT 'Books with invalid seller_id to be deleted:' as info;
SELECT id, title, seller_id,
  CASE
    WHEN seller_id IS NULL THEN 'seller_id is NULL'
    WHEN seller_id NOT IN (SELECT id FROM profiles) THEN 'seller_id not in profiles'
    ELSE 'other issue'
  END as issue
FROM books
WHERE seller_id IS NULL
   OR seller_id NOT IN (SELECT id FROM profiles);

-- Now delete them
DELETE FROM books
WHERE seller_id IS NULL
   OR seller_id NOT IN (SELECT id FROM profiles);

-- Verify deletion
SELECT 'Remaining books:' as info, COUNT(*) as count FROM books;

-- 1. First, ensure we have the correct transactions table structure
-- Drop and recreate with proper RLS setup
DROP TABLE IF EXISTS transactions CASCADE;

-- Create transactions table with proper structure
CREATE TABLE transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  price NUMERIC NOT NULL,
  status TEXT CHECK (status IN ('pending', 'completed', 'cancelled')) DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes for transactions
CREATE INDEX idx_transactions_book ON transactions(book_id);
CREATE INDEX idx_transactions_buyer ON transactions(buyer_id);
CREATE INDEX idx_transactions_seller ON transactions(seller_id);
CREATE INDEX idx_transactions_status ON transactions(status);

-- 3. Enable RLS on transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- 4. Create notifications table
DROP TABLE IF EXISTS notifications CASCADE;

CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN (
    'purchase_request',    -- Buyer requests to buy a book
    'request_accepted',    -- Seller accepts the buyer's request (BILL IS READY)
    'request_cancelled',   -- Seller declines/cancels the request
    'exchange_request'     -- Buyer requests to exchange a book
  )),
  title TEXT NOT NULL,
  message TEXT,
  transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create indexes for notifications
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_transaction ON notifications(transaction_id);

-- 6. Enable RLS on notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies for transactions
-- Allow buyers to view their own transactions
CREATE POLICY "Buyers can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = buyer_id);

-- Allow sellers to view their own transactions  
CREATE POLICY "Sellers can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = seller_id);

-- Allow sellers to update their own transactions (accept/decline)
CREATE POLICY "Sellers can update own transactions"
  ON transactions FOR UPDATE
  USING (auth.uid() = seller_id);

-- Allow anyone to insert transactions (when buying)
CREATE POLICY "Anyone can insert transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 8. RLS Policies for notifications
-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Authenticated users can insert notifications (for sending to others)
CREATE POLICY "Users can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Admins can manage all notifications
CREATE POLICY "Admins can manage all notifications"
  ON notifications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

-- 9. Add updated_at trigger for transactions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 10. Verification queries
SELECT '✅ Tables created successfully' as status;
SELECT 'transactions' as table_name, COUNT(*) as row_count FROM transactions;
SELECT 'notifications' as table_name, COUNT(*) as row_count FROM notifications;

-- 11. Check RLS status
SELECT 
  tablename, 
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('notifications', 'transactions')
ORDER BY tablename;

-- 12. Check policies
SELECT 
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename IN ('notifications', 'transactions')
ORDER BY tablename, policyname;

-- ============================================
-- INSTRUCTIONS:
-- 1. Copy this entire file
-- 2. Paste into Supabase SQL Editor
-- 3. Run the script
-- 4. Test the system with two user accounts
-- ============================================