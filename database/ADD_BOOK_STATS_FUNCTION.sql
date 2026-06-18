-- ============================================
-- Add book statistics summary function for admin dashboard
-- Run this in Supabase SQL Editor
-- ============================================

CREATE OR REPLACE FUNCTION get_book_statistics_summary()
RETURNS TABLE (
  total_views BIGINT,
  total_sales BIGINT,
  total_books_with_stats BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(bs.views_count), 0)::BIGINT as total_views,
    COALESCE(SUM(bs.sales_count), 0)::BIGINT as total_sales,
    COUNT(DISTINCT bs.book_id)::BIGINT as total_books_with_stats
  FROM book_statistics bs;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function
SELECT * FROM get_book_statistics_summary();

-- Show top 5 trending books
SELECT
  bs.book_id,
  b.title,
  bs.views_count,
  bs.sales_count,
  bs.trending_score
FROM book_statistics bs
JOIN books b ON bs.book_id = b.id
ORDER BY bs.trending_score DESC
LIMIT 5;
