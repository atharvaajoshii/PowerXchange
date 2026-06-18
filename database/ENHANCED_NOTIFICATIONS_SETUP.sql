-- ============================================
-- ENHANCED NOTIFICATIONS TABLE SETUP FOR POWERXCHANGE
-- Run this in Supabase SQL Editor
-- This script ensures proper notification system for buyer/seller interactions
-- ============================================

-- 1. Drop existing table if exists (to recreate with proper constraints)
DROP TABLE IF EXISTS notifications CASCADE;

-- 2. Create notifications table with proper constraints
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

-- 3. Create indexes for faster queries
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_transaction ON notifications(transaction_id);

-- 4. Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies

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

-- 6. Add update policy for transactions (so sellers can accept/decline)
-- This allows the seller of a transaction to update its status
DROP POLICY IF EXISTS "Sellers can update own transactions" ON transactions;
CREATE POLICY "Sellers can update own transactions"
  ON transactions FOR UPDATE
  USING (auth.uid() = seller_id);

-- 7. Allow buyers to view their own transactions
DROP POLICY IF EXISTS "Buyers can view own transactions" ON transactions;
CREATE POLICY "Buyers can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- 8. Verification query
SELECT 'notifications' as table_name, COUNT(*) as row_count FROM notifications;