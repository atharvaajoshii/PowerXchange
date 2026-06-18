-- ============================================
-- NOTIFICATIONS TABLE SETUP FOR POWERXCHANGE
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- 3. Disable Row Level Security (for testing)
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- 4. Verification - check if table exists
SELECT 'notifications' as table_name, COUNT(*) as row_count FROM notifications;
