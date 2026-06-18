-- ============================================
-- AUTHORS TABLE
-- ============================================
-- Stores unique authors to avoid duplication
-- Books are linked to authors via author_id foreign key
-- Admin approval required before books from new authors go live

CREATE TABLE IF NOT EXISTS authors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  photo_url TEXT,
  description TEXT,
  genre TEXT,
  is_approved BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups by name
CREATE INDEX IF NOT EXISTS idx_authors_name ON authors(name);
CREATE INDEX IF NOT EXISTS idx_authors_approved ON authors(is_approved);

-- ============================================
-- UPDATE BOOKS TABLE
-- ============================================
-- Add author_id column to books table (if not exists)
ALTER TABLE books ADD COLUMN IF NOT EXISTS author_id UUID REFERENCES authors(id) ON DELETE SET NULL;

-- Keep the old author TEXT column for backwards compatibility
-- but new books will use author_id

-- Index for author lookup in books
CREATE INDEX IF NOT EXISTS idx_books_author ON books(author_id);
