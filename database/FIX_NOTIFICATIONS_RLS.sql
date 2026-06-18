-- ============================================
-- FIX NOTIFICATIONS RLS POLICY
-- This allows users to send notifications to OTHER users
-- Run this in Supabase SQL Editor
-- ============================================

-- Drop the existing insert policy
DROP POLICY IF EXISTS "Users can insert notifications" ON notifications;

-- Create new policy that allows authenticated users to insert notifications for anyone
-- This is needed so sellers can send notifications to buyers (and vice versa)
CREATE POLICY "Users can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Verify the policy was created
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'notifications' AND cmd = 'INSERT';

-- Test: Show all notification policies
SELECT
  tablename,
  policyname,
  cmd as operation,
  roles,
  qual as using_clause,
  with_check as check_clause
FROM pg_policies
WHERE tablename = 'notifications'
ORDER BY cmd, policyname;
