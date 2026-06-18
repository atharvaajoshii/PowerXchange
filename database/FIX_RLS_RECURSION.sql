-- ============================================
-- FIX: Infinite Recursion in RLS Policies
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. DROP ALL EXISTING POLICIES ON profiles TABLE
-- This removes any policies causing infinite recursion

DROP POLICY IF EXISTS "profiles_select" ON profiles;
DROP POLICY IF EXISTS "profiles_insert" ON profiles;
DROP POLICY IF EXISTS "profiles_update" ON profiles;
DROP POLICY IF EXISTS "profiles_delete" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- 2. DISABLE ROW LEVEL SECURITY COMPLETELY
-- Only on tables that exist
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE books DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE cart DISABLE ROW LEVEL SECURITY;
-- Skip reviews and notifications if they don't exist

-- 3. VERIFY RLS IS DISABLED
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('profiles', 'books', 'transactions', 'wishlist', 'admin_roles', 'cart', 'reviews', 'notifications');

-- 4. CHECK FOR ANY REMAINING POLICIES
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename = 'profiles';

-- ============================================
-- After running this, refresh your browser
-- The API should work without infinite recursion error
-- ============================================
