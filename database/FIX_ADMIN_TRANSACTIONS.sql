-- Fix Admin Transactions Access
-- Run this in Supabase SQL Editor to ensure admins can view all transactions

-- First, disable RLS temporarily to check current state
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admins can view all transactions" ON transactions;
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can create transactions" ON transactions;
DROP POLICY IF EXISTS "Buyers can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Sellers can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Sellers can update own transactions" ON transactions;
DROP POLICY IF EXISTS "Anyone can insert transactions" ON transactions;

-- Create comprehensive admin policy - admins can do anything
CREATE POLICY "Admins can manage all transactions"
  ON transactions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Users can view their own transactions (as buyer or seller)
CREATE POLICY "Users can view own transactions"
  ON transactions FOR SELECT
  USING (
    auth.uid() = buyer_id
    OR auth.uid() = seller_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Buyers can create transactions
CREATE POLICY "Users can create transactions"
  ON transactions FOR INSERT
  WITH CHECK (
    auth.uid() = buyer_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Sellers can update their transactions
CREATE POLICY "Sellers can update own transactions"
  ON transactions FOR UPDATE
  USING (
    auth.uid() = seller_id
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Grant all permissions to authenticated users (needed for RLS)
GRANT ALL ON transactions TO authenticated;
