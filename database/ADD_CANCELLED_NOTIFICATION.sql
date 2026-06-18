-- ============================================
-- ADD ORDER_CANCELLED NOTIFICATION TYPE
-- Run this in Supabase SQL Editor to add support for order cancellation notifications
-- ============================================

-- Drop the existing CHECK constraint and recreate it with the new type
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications
ADD CONSTRAINT notifications_type_check
CHECK (type IN (
  'purchase_request',    -- Buyer requests to buy a book
  'request_accepted',    -- Seller accepts the buyer's request (BILL IS READY)
  'request_declined',    -- Seller declines the request
  'request_cancelled',   -- Buyer cancels their order
  'exchange_request',    -- Buyer requests to exchange a book
  'order_cancelled'      -- Buyer cancels order (notifies seller)
));

-- Verify the constraint was added
SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint
WHERE conrelid = 'notifications'::regclass
AND contype = 'c';
