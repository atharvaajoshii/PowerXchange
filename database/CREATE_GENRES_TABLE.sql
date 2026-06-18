-- ============================================
-- GENRES TABLE (for dynamic genre management)
-- ============================================
CREATE TABLE IF NOT EXISTS genres (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  image_url TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_genres_name ON genres(name);

-- ============================================
-- FUNCTION: Auto-create genre when book is added
-- ============================================
CREATE OR REPLACE FUNCTION auto_create_genre()
RETURNS TRIGGER AS $$
DECLARE
  v_genre_name TEXT;
BEGIN
  -- Get the genre from the new book
  v_genre_name := NEW.genre;

  -- If genre is provided and not empty
  IF v_genre_name IS NOT NULL AND v_genre_name != '' THEN
    -- Try to insert the genre if it doesn't exist
    INSERT INTO genres (name, image_url, description)
    VALUES (
      v_genre_name,
      -- Generate avatar URL with genre name
      'https://ui-avatars.com/api/?name=' || encode(convert_to(v_genre_name, 'UTF8'), 'base64') || '&size=200&background=random&color=fff&bold=true',
      'Books in the ' || v_genre_name || ' category'
    )
    ON CONFLICT (name) DO NOTHING; -- Genre already exists, skip
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGER: Auto-create genre on book insert
-- ============================================
DROP TRIGGER IF EXISTS trg_auto_create_genre ON books;
CREATE TRIGGER trg_auto_create_genre
  AFTER INSERT ON books
  FOR EACH ROW
  WHEN (NEW.genre IS NOT NULL AND NEW.genre != '')
  EXECUTE FUNCTION auto_create_genre();

-- ============================================
-- Backfill: Create genres from existing books
-- ============================================
INSERT INTO genres (name, image_url, description)
SELECT DISTINCT
  genre,
  'https://ui-avatars.com/api/?name=' || encode(convert_to(genre, 'UTF8'), 'base64') || '&size=200&background=random&color=fff&bold=true',
  'Books in the ' || genre || ' category'
FROM books
WHERE genre IS NOT NULL AND genre != ''
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- RLS Policies (if needed)
-- ============================================
ALTER TABLE genres ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Genres are viewable by everyone"
  ON genres FOR SELECT
  USING (true);

-- Admins can manage genres
CREATE POLICY "Admins can insert genres"
  ON genres FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update genres"
  ON genres FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can delete genres"
  ON genres FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );
