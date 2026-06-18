-- ============================================
-- PowerXchange - Complete Database Setup
-- Run this ENTIRE script in Supabase SQL Editor
-- ============================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  email TEXT,
  usn TEXT,
  college TEXT,
  id_card_url TEXT,
  role TEXT DEFAULT 'user',
  status TEXT DEFAULT 'pending',
  rejection_reason TEXT,
  approved_at TIMESTAMP,
  is_blocked BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 2. BOOKS TABLE
CREATE TABLE IF NOT EXISTS books (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  seller_name TEXT,
  seller_phone TEXT,
  seller_email TEXT,
  seller_address TEXT,
  seller_city TEXT,
  seller_pincode TEXT,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  genre TEXT,
  category TEXT,
  condition TEXT,
  price NUMERIC DEFAULT 0,
  description TEXT,
  image_url TEXT,
  is_approved BOOLEAN DEFAULT false,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 3. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  price NUMERIC NOT NULL,
  status TEXT CHECK (status IN ('pending', 'completed', 'cancelled')) DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. WISHLIST TABLE
CREATE TABLE IF NOT EXISTS wishlist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

-- 5. ADMIN_ROLES TABLE
CREATE TABLE IF NOT EXISTS admin_roles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  permissions JSONB DEFAULT '{"users": true, "books": true, "transactions": true}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. CREATE PROFILE ON USER SIGNUP
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, college, role, status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'college', ''),
    'user',
    'pending'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 7. DELETE USER FUNCTION (for admin)
CREATE OR REPLACE FUNCTION delete_user_completely(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  DELETE FROM profiles WHERE id = user_uuid;
  DELETE FROM auth.users WHERE id = user_uuid;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. DISABLE ROW LEVEL SECURITY
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE books DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_roles DISABLE ROW LEVEL SECURITY;

-- 9. CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_books_seller ON books(seller_id);
CREATE INDEX IF NOT EXISTS idx_books_approved ON books(is_approved);
CREATE INDEX IF NOT EXISTS idx_books_available ON books(is_available);
CREATE INDEX IF NOT EXISTS idx_books_genre ON books(genre);
CREATE INDEX IF NOT EXISTS idx_transactions_book ON transactions(book_id);
CREATE INDEX IF NOT EXISTS idx_transactions_buyer ON transactions(buyer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_seller ON transactions(seller_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_user ON wishlist(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_user_id ON admin_roles(user_id);

-- 10. SETUP STORAGE BUCKET FOR BOOK IMAGES
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('book-images', 'book-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public images are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'book-images');

CREATE POLICY "Users can upload book images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'book-images' AND auth.role() = 'authenticated');

CREATE POLICY "Users can delete own images"
ON storage.objects FOR DELETE
USING (bucket_id = 'book-images' AND auth.uid() = owner);

-- ============================================
-- MAKE YOURSELF ADMIN
-- Replace with your actual email addresses
-- ============================================
-- Run this AFTER signing up:
-- UPDATE profiles SET role = 'admin', status = 'approved'
-- WHERE email IN ('your-email@college.edu', 'another-admin@college.edu');

-- ============================================
-- VERIFICATION QUERY
-- ============================================
SELECT 'profiles' as table_name, COUNT(*) as row_count FROM profiles
UNION ALL SELECT 'books', COUNT(*) FROM books
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'wishlist', COUNT(*) FROM wishlist
UNION ALL SELECT 'admin_roles', COUNT(*) FROM admin_roles;
