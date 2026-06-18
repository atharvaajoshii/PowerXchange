-- ============================================
-- FIX TRANSACTIONS TABLE RLS AND NOTIFICATIONS
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. First, ensure notifications table exists with proper setup
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

-- 2. Create indexes for notifications
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_transaction ON notifications(transaction_id);

-- 3. Enable RLS on notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all notifications"
  ON notifications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

-- 5. Fix transactions table RLS
-- First, enable RLS on transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for transactions
-- Allow buyers to view their own transactions
DROP POLICY IF EXISTS "Buyers can view own transactions" ON transactions;
CREATE POLICY "Buyers can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = buyer_id);

-- Allow sellers to view their own transactions  
DROP POLICY IF EXISTS "Sellers can view own transactions" ON transactions;
CREATE POLICY "Sellers can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = seller_id);

-- Allow sellers to update their own transactions (accept/decline)
DROP POLICY IF EXISTS "Sellers can update own transactions" ON transactions;
CREATE POLICY "Sellers can update own transactions"
  ON transactions FOR UPDATE
  USING (auth.uid() = seller_id);

-- Allow anyone to insert transactions (when buying)
DROP POLICY IF EXISTS "Anyone can insert transactions" ON transactions;
CREATE POLICY "Anyone can insert transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 7. Add updated_at trigger for transactions (if not exists)
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

-- 8. Verification queries
SELECT 'notifications' as table_name, COUNT(*) as row_count FROM notifications;
SELECT 'transactions' as table_name, COUNT(*) as row_count FROM transactions;

-- 9. Check RLS status
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename IN ('notifications', 'transactions');