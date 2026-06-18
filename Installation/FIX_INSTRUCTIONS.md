# PowerXchange - User Verification Fix Instructions

## Problems Identified

1. **User email verification doesn't work** - New users aren't getting verified
2. **User details don't show in admin/users pages** - Schema mismatch between code and database

## Root Cause

Your `profiles` table is missing critical columns that the code expects:
- `status` (TEXT: 'pending'/'approved') - for verification status
- `role` (TEXT: 'user'/'admin') - for admin authorization
- `full_name` (TEXT) - for displaying user name
- `photo_url`, `id_card_url` - for profile and ID images

The code in `AdminUsers.jsx` queries `status` column, but your database might have `is_verified` instead.

---

## Solution - Run These Steps in Order

### Step 1: Run the SQL Fix Script

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/brpdhqdiwnrexygsxulx
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `FIX_USER_VERIFICATION.sql`
4. Click **Run**

This script will:
- Add all missing columns to the `profiles` table
- Migrate existing data from `is_verified` to `status`
- Recreate the `handle_new_user` trigger
- Disable RLS for testing
- Set up your admin user
- Create helpful helper functions

### Step 2: Verify the Setup

After running the SQL, run these verification queries in the SQL Editor:

```sql
-- Check columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;

-- Check your admin user exists
SELECT id, email, full_name, role, status 
FROM profiles 
WHERE email = 'jatharva1701@gmail.com';

-- Check all profiles
SELECT email, full_name, role, status, created_at 
FROM profiles 
ORDER BY created_at DESC;
```

You should see:
- `status`, `role`, `full_name` columns listed
- Your admin user with `role = 'admin'` and `status = 'approved'`

### Step 3: Test New User Signup

1. Open your app in browser
2. Sign up a **new user** with a different email
3. Check browser console for errors (F12 → Console)
4. Go back to Supabase SQL Editor and run:

```sql
SELECT email, full_name, role, status, created_at 
FROM profiles 
ORDER BY created_at DESC 
LIMIT 5;
```

You should see the new user with `status = 'pending'` and `role = 'user'`.

### Step 4: Verify User in Admin Panel

1. Login as admin (`jatharva1701@gmail.com`)
2. Go to `/admin/users`
3. You should now see all users including the new signup

### Step 5: Manually Verify a User (Optional)

To manually approve a user:

```sql
UPDATE profiles 
SET status = 'approved', approved_at = NOW() 
WHERE email = 'newuser@college.edu';
```

Or use the helper function:

```sql
SELECT verify_user_by_email('newuser@college.edu');
```

---

## If Email Confirmation Is Still Not Working

Supabase may have email confirmation enabled. To disable it:

1. Go to **Authentication** → **Providers** → **Email**
2. Disable **"Confirm email"**
3. Or, enable **"Enable email signup"** and disable **"Double opt-in"**

Alternatively, add this to your `.env` for local testing:

```
# Not applicable for Supabase - handle in dashboard
```

---

## Column Mapping Reference

| Code Expects | Old Schema Had | Fix Applied |
|--------------|----------------|-------------|
| `status`     | `is_verified`  | Added + migrated |
| `role`       | (missing)      | Added with default 'user' |
| `full_name`  | `name`         | Added + data copied |
| `photo_url`  | (missing)      | Added |
| `id_card_url`| (missing)      | Added |

---

## Troubleshooting

### "User not showing in AdminUsers page"

1. Check browser console for errors
2. Run this query to see what's in profiles:
   ```sql
   SELECT * FROM profiles ORDER BY created_at DESC LIMIT 10;
   ```
3. Make sure `status` column has values ('pending' or 'approved')

### "Signup fails with error"

1. Check that the `handle_new_user` trigger exists:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
   ```
2. Re-run the trigger creation from `FIX_USER_VERIFICATION.sql`

### "Images not uploading"

1. Run `SETUP_PROFILE_STORAGE.sql` to create the storage bucket
2. Check bucket exists in **Storage** → `profile-images`

### "Still seeing old schema columns"

Drop and recreate the profiles table:

```sql
-- WARNING: This deletes all profile data!
DROP TABLE IF EXISTS profiles CASCADE;

CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  email TEXT,
  usn TEXT,
  college TEXT,
  id_card_url TEXT,
  photo_url TEXT,
  role TEXT DEFAULT 'user',
  status TEXT DEFAULT 'pending',
  rejection_reason TEXT,
  approved_at TIMESTAMP,
  is_blocked BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);
```

Then re-run `FIX_USER_VERIFICATION.sql`.

---

## Files Modified/Created

- `FIX_USER_VERIFICATION.sql` - Main fix script (RUN THIS FIRST)
- `SETUP_PROFILE_STORAGE.sql` - Storage bucket setup (already exists)
- `FIX_INSTRUCTIONS.md` - This file
