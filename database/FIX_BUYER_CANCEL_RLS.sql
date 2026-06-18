-- ============================================
-- FIX: Allow buyers to cancel their own transactions
-- Run this in Supabase SQL Editor
-- ============================================

-- Add policy to allow buyers to update their own transactions (for cancellation)
DROP POLICY IF EXISTS "Buyers can update own transactions" ON transactions;
CREATE POLICY "Buyers can update own transactions"
  ON transactions FOR UPDATE
  USING (auth.uid() = buyer_id);

-- Verify the policy exists
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'transactions' AND policyname LIKE '%buyer%';
