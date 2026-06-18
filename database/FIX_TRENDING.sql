-- ============================================
-- FIX TRENDING BOOKS FEATURE
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Create book_statistics table if it doesn't exist
CREATE TABLE IF NOT EXISTS book_statistics (
  book_id UUID PRIMARY KEY REFERENCES books(id) ON DELETE CASCADE,
  views_count BIGINT DEFAULT 0,
  sales_count BIGINT DEFAULT 0,
  rating_avg NUMERIC(3,2) DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  trending_score NUMERIC(10,2) DEFAULT 0,
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create index for trending score
CREATE INDEX IF NOT EXISTS idx_book_stats_trending ON book_statistics(trending_score DESC);

-- 3. Enable RLS
ALTER TABLE book_statistics ENABLE ROW LEVEL SECURITY;

-- 4. Create policies (public read, authenticated can increment)
DROP POLICY IF EXISTS "Anyone can view book statistics" ON book_statistics;
CREATE POLICY "Anyone can view book statistics"
  ON book_statistics FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can update statistics" ON book_statistics;
CREATE POLICY "Authenticated users can update statistics"
  ON book_statistics FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- 5. Create function to increment view count
CREATE OR REPLACE FUNCTION increment_book_view(p_book_id UUID)
RETURNS void AS $$
DECLARE
  new_views BIGINT;
  new_score NUMERIC(10,2);
BEGIN
  -- Insert or update the view count
  INSERT INTO book_statistics (book_id, views_count, last_updated)
  VALUES (p_book_id, 1, NOW())
  ON CONFLICT (book_id) DO UPDATE
  SET
    views_count = book_statistics.views_count + 1,
    last_updated = NOW();

  -- Recalculate trending score
  UPDATE book_statistics
  SET trending_score = (views_count * 0.4 + COALESCE(sales_count, 0) * 0.6 + COALESCE(rating_avg, 0) * 10)
  WHERE book_id = p_book_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create function to increment sales count (called when transaction is created)
CREATE OR REPLACE FUNCTION increment_book_sales(p_book_id UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO book_statistics (book_id, sales_count, last_updated)
  VALUES (p_book_id, 1, NOW())
  ON CONFLICT (book_id) DO UPDATE
  SET
    sales_count = book_statistics.sales_count + 1,
    last_updated = NOW();

  -- Recalculate trending score
  UPDATE book_statistics
  SET trending_score = (views_count * 0.4 + sales_count * 0.6 + COALESCE(rating_avg, 0) * 10)
  WHERE book_id = p_book_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Initialize statistics for existing books
INSERT INTO book_statistics (book_id, views_count, sales_count, trending_score, last_updated)
SELECT
  id,
  0,
  0,
  0,
  NOW()
FROM books
WHERE id NOT IN (SELECT book_id FROM book_statistics);

-- 8. Verify setup
SELECT 'book_statistics table created' as status;
SELECT COUNT(*) as book_count FROM book_statistics;
