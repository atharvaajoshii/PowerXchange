-- ============================================
-- SETUP PROFILE IMAGES STORAGE
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Create the storage bucket for profile images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('profile-images', 'profile-images', true, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- 2. Allow public read access to all files
CREATE POLICY "Public profile images are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-images');

-- 3. Allow authenticated users to upload images
CREATE POLICY "Users can upload profile images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-images'
  AND auth.role() = 'authenticated'
);

-- 4. Allow users to update their own uploaded images
CREATE POLICY "Users can update own profile images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile-images'
  AND auth.uid() = owner
);

-- 5. Allow users to delete their own uploaded images
CREATE POLICY "Users can delete own profile images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile-images'
  AND auth.uid() = owner
);

-- ============================================
-- ADD IMAGE COLUMNS TO PROFILES TABLE
-- ============================================

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS photo_url TEXT,
ADD COLUMN IF NOT EXISTS id_card_url TEXT;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_photo ON profiles(photo_url);
CREATE INDEX IF NOT EXISTS idx_profiles_id_card ON profiles(id_card_url);
