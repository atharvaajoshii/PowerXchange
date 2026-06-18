-- ============================================
-- SUPABASE STORAGE SETUP FOR BOOK IMAGES
-- ============================================
-- Copy ONLY the code below and run it in Supabase SQL Editor

-- 1. Create the storage bucket (public)
INSERT INTO storage.buckets (id, name, public)
VALUES ('book-images', 'book-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy: Anyone can view images
CREATE POLICY "Public Access - View Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'book-images');

-- 3. Policy: Logged in users can upload images
CREATE POLICY "Authenticated Users - Upload Images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'book-images'
  AND auth.role() = 'authenticated'
);

-- 4. Policy: Users can delete their own uploads
CREATE POLICY "Users - Delete Own Images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'book-images'
  AND auth.uid() = owner
);

-- Done! The bucket is now ready for image uploads.
