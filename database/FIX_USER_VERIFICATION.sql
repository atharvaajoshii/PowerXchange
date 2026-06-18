-- ============================================
-- PowerXchange - FIX USER VERIFICATION ISSUE
-- Run this ENTIRE script in Supabase SQL Editor
-- ============================================

-- 1. First, let's see what columns exist in your profiles table
-- Run this first to check:
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. ADD MISSING COLUMNS (if they don't exist)
-- These are the columns AdminUsers.jsx and Profile.jsx expect

-- Add status column for verification tracking
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- Add role column for admin/user distinction
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

-- Add full_name column (Signup.jsx uses this)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS full_name TEXT;

-- Add USN column
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS usn TEXT;

-- Add ID card URL for verification
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS id_card_url TEXT;

-- Add rejection reason
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Add approved_at timestamp
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP;

-- Add phone number
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;

-- Add location
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location TEXT;

-- Add photo_url for profile pictures
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- 3. MIGRATE EXISTING DATA

-- If you have is_verified column, migrate to status
DO $$
BEGIN
  -- Check if is_verified column exists
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_verified') THEN
    -- Update status based on is_verified
    UPDATE profiles SET status = 'approved' WHERE is_verified = true;
    UPDATE profiles SET status = 'pending' WHERE is_verified = false OR is_verified IS NULL;
  END IF;
END $$;

-- If you have 'name' column but not 'full_name', copy the data
UPDATE profiles SET full_name = name WHERE full_name IS NULL AND name IS NOT NULL;

-- 4. FIX THE TRIGGER - Recreate handle_new_user function
-- This ensures profiles are created correctly on signup

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    full_name,
    email,
    college,
    role,
    status,
    created_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', SPLIT_PART(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'college', ''),
    'user',
    'pending',  -- New users start as pending until admin approves
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    college = EXCLUDED.college,
    email = EXCLUDED.email,
    status = EXCLUDED.status;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 5. DISABLE ROW LEVEL SECURITY (for testing - enable in production)
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE books DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE cart DISABLE ROW LEVEL SECURITY;

-- 6. CREATE ADMIN USER(S)
-- Update this with your actual admin email(s)
UPDATE profiles
SET role = 'admin', status = 'approved', approved_at = NOW()
WHERE email IN (
  'jatharva1701@gmail.com'
  -- Add more admin emails here if needed
);

-- 7. CREATE THE handle_new_user TRIGGER FOR FUTURE SIGNUPS
-- Ensure the trigger fires for all new users
DO $$
BEGIN
  -- Check if trigger exists, if not create it
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_new_user();
  END IF;
END $$;

-- 8. CREATE INDEXES FOR BETTER PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_college ON profiles(college);

-- 9. VERIFY THE SETUP
-- Run these queries to verify everything is set up correctly

-- Check profiles table structure
SELECT '=== PROFILES TABLE STRUCTURE ===' as info;
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Check existing profiles
SELECT '=== EXISTING PROFILES ===' as info;
SELECT id, email, full_name, role, status, created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 10;

-- Check if admin exists
SELECT '=== ADMIN USERS ===' as info;
SELECT id, email, full_name, role, status
FROM profiles
WHERE role = 'admin';

-- Check auth users
SELECT '=== AUTH USERS ===' as info;
SELECT id, email, created_at, email_confirmed_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- 10. HELPER FUNCTION: Manually verify a user by email
-- Usage: SELECT verify_user_by_email('user@college.edu');
CREATE OR REPLACE FUNCTION verify_user_by_email(user_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  user_uuid UUID;
BEGIN
  SELECT id INTO user_uuid FROM profiles WHERE email = user_email;
  IF user_uuid IS NULL THEN
    RETURN FALSE;
  END IF;

  UPDATE profiles
  SET status = 'approved', approved_at = NOW()
  WHERE id = user_uuid;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 11. HELPER FUNCTION: Delete user completely (for testing)
-- Usage: SELECT delete_test_user('test@test.com');
CREATE OR REPLACE FUNCTION delete_test_user(user_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  user_uuid UUID;
BEGIN
  SELECT id INTO user_uuid FROM profiles WHERE email = user_email;
  IF user_uuid IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Delete from auth.users (profiles will cascade)
  DELETE FROM auth.users WHERE id = user_uuid;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VERIFICATION CHECKLIST
-- ============================================
-- After running this script:
-- 1. Check that profiles table has: status, role, full_name columns
-- 2. Check that at least one admin user exists with role='admin' and status='approved'
-- 3. Try signing up a new user and check if profile is created
-- 4. Check AdminUsers page shows the new user

-- TO VERIFY A NEW USER MANUALLY:
-- UPDATE profiles SET status = 'approved', approved_at = NOW() WHERE email = 'newuser@college.edu';
-- ============================================
