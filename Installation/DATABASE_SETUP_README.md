# PowerXchange - Database Setup Guide

## Quick Setup (For Developers)

1. **Go to Supabase Dashboard**
   - Open your project at https://supabase.com
   - Go to **SQL Editor**

2. **Run the Setup Script**
   - Copy the entire content of `DATABASE_SETUP.sql`
   - Paste it in the SQL Editor
   - Click **Run**

3. **Create Admin Users**
   - After running the script, sign up for an account on your app
   - Go back to Supabase SQL Editor
   - Run this query (replace with your actual email):
   ```sql
   UPDATE profiles SET role = 'admin', status = 'approved'
   WHERE email IN ('your-email@college.edu', 'another-admin@college.edu');
   ```

4. **Verify Setup**
   - Run the verification query at the end of `DATABASE_SETUP.sql`
   - All tables should show row counts

## What This Sets Up

### Tables Created:
- **profiles** - User profiles (linked to Supabase Auth)
- **books** - Book listings with seller info
- **transactions** - Book purchase/exchange records
- **wishlist** - User wishlists
- **admin_roles** - Admin user management

### Features Enabled:
- ✅ Auto-create profile on signup
- ✅ Complete user deletion (including from auth)
- ✅ Book image storage (up to 5MB)
- ✅ Cascade deletes (deleting user removes all their data)
- ✅ RLS disabled for development

### Storage Bucket:
- **book-images** - Public bucket for book cover images
- Allowed formats: JPEG, PNG, WEBP
- Max size: 5MB

## Troubleshooting

### "User already exists" error on signup:
```sql
-- Delete the orphaned user completely
SELECT delete_user_completely('USER_UUID_HERE');
```

### Find user's UUID:
```sql
SELECT id, email, full_name FROM profiles WHERE email = 'user@email.com';
```

### Make yourself admin:
```sql
UPDATE profiles SET role = 'admin', status = 'approved'
WHERE email = 'your-email@college.edu';
```

## Environment Variables

Make sure your `.env` file has:
```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```
