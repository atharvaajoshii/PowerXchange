-- ============================================
-- Delete a user by email
-- Replace 'user@example.com' with the actual email
-- ============================================

-- Delete user from auth.users (profiles will auto-delete via CASCADE)
DELETE FROM auth.users
WHERE email = 'user@example.com';

-- ============================================
-- OR: Delete by user ID
-- Replace the UUID below with actual user ID
-- ============================================

-- DELETE FROM auth.users
-- WHERE id = '00000000-0000-0000-0000-000000000000';

-- ============================================
-- Verify deletion
-- ============================================
-- SELECT email FROM auth.users WHERE email = 'user@example.com';
