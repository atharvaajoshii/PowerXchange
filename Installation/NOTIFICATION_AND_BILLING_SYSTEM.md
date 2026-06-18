# PowerXchange Notification & Billing System

## Overview

This document explains the notification and billing system implemented for PowerXchange, a college book exchange platform.

## Features Implemented

### 1. Notification System

#### When Notifications Are Sent

1. **Purchase Request** (`purchase_request`)
   - **Triggered when:** A buyer requests to buy a book
   - **Recipient:** Seller
   - **Contains:** Buyer name, book title, and a message
   - **Action:** Seller can view the request in their Orders page

2. **Exchange Request** (`exchange_request`)
   - **Triggered when:** A buyer proposes to exchange a book
   - **Recipient:** Seller
   - **Contains:** Buyer name, book title, exchange book details
   - **Action:** Seller can view the exchange proposal

3. **Request Accepted** (`request_accepted`)
   - **Triggered when:** A seller accepts a buyer's request
   - **Recipient:** Buyer
   - **Contains:** Seller name, book title, notification that bill is ready
   - **Action:** Click to view the bill/transaction details

4. **Request Cancelled** (`request_cancelled`)
   - **Triggered when:** A seller declines a request
   - **Recipient:** Buyer
   - **Contains:** Information that the request was declined

#### Notification Bell Icon

- Located in the navbar (top right)
- Shows unread notification count with a red badge
- Updates every 30 seconds automatically
- Clicking opens the notifications page

#### Notifications Page

- Displays all notifications in chronological order
- Unread notifications have a blue border
- Clicking on a notification navigates to the transaction/bill details
- Users can delete individual notifications or clear all

### 2. Billing System

#### Bill/Invoice Details

When a seller accepts a request, a bill is automatically generated and accessible to both buyer and seller.

**Bill Contains:**
- Transaction ID (unique identifier)
- Book details (title, author, genre, condition, image)
- Buyer details (name, email, college, phone)
- Seller details (name, email, college, phone, address)
- Price summary (book price, platform fee, total amount)
- Payment instructions
- Date and time of transaction

#### Accessing the Bill

1. **From Notifications:**
   - Click on "Your request has been accepted! 🎉" notification
   - Directly opens the transaction detail page

2. **From Orders Page:**
   - Go to "My Orders" → "My Purchases" or "Incoming Orders"
   - Click "View Details" on any completed transaction

3. **From Transaction URL:**
   - Direct URL: `/transaction/{transaction_id}`
   - Only accessible by buyer or seller of that transaction

#### Payment Instructions

The platform does NOT handle payments directly. The bill includes clear instructions:

- **For Buyers:** Contact the seller to arrange payment using preferred method (UPI, Cash, Bank Transfer, etc.)
- **For Sellers:** Coordinate with the buyer to receive payment
- Keep the transaction ID for reference

## Database Schema

### Notifications Table

```sql
CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id),
  type TEXT NOT NULL CHECK (type IN (
    'purchase_request',
    'request_accepted',
    'request_cancelled',
    'exchange_request'
  )),
  title TEXT NOT NULL,
  message TEXT,
  transaction_id UUID REFERENCES transactions(id),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Transactions Table

```sql
CREATE TABLE transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  book_id UUID REFERENCES books(id),
  buyer_id UUID REFERENCES profiles(id),
  seller_id UUID REFERENCES profiles(id),
  price NUMERIC NOT NULL,
  status TEXT CHECK (status IN ('pending', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Setup Instructions

### 1. Run the Database Setup

**IMPORTANT: If you already have the transactions table with RLS disabled, run the FIX script first:**

Execute `FIX_TRANSACTIONS_RLS.sql` in your Supabase SQL Editor:

```bash
# Copy the contents of FIX_TRANSACTIONS_RLS.sql
# Paste into Supabase SQL Editor and run
```

This will:
- Fix RLS policies for both notifications and transactions tables
- Ensure sellers can accept requests
- Ensure buyers can see their order history
- Set up proper access controls

**If starting fresh**, you can use `ENHANCED_NOTIFICATIONS_SETUP.sql` instead.

### 2. Verify Setup

After running the SQL script, verify:

```sql
-- Check tables exist and RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename IN ('notifications', 'transactions');

-- Check RLS policies
SELECT policyname FROM pg_policies WHERE tablename IN ('notifications', 'transactions');

-- Test the setup
SELECT 'notifications' as table_name, COUNT(*) as row_count FROM notifications
UNION ALL
SELECT 'transactions' as table_name, COUNT(*) as row_count FROM transactions;
```

### 3. Test the System

Use `TEST_NOTIFICATIONS_AND_ORDERS.sql` to verify everything is working:

```bash
# Copy the contents of TEST_NOTIFICATIONS_AND_ORDERS.sql
# Paste into Supabase SQL Editor and run
```

### 2. Verify Setup

After running the SQL script, verify:

```sql
-- Check notifications table exists
SELECT COUNT(*) FROM notifications;

-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'notifications';

-- Check policies
SELECT policyname FROM pg_policies WHERE tablename = 'notifications';
```

## User Flow

### Buyer's Perspective

1. Browse books on the platform
2. Click "Buy Now" or "Exchange" on a book listing
3. Write a message to the seller
4. Submit the request
5. **Seller receives a notification** about the request
6. Wait for seller's response
7. **When seller accepts:**
   - Buyer receives a notification: "Your request has been accepted! 🎉"
   - Click notification to view the bill
8. View bill with seller contact details
9. Contact seller to arrange payment (UPI, cash, etc.)
10. Complete the transaction offline

### Seller's Perspective

1. List books for sale
2. **When buyer requests a book:**
   - Seller receives a notification: "New Purchase Request! 🛒"
   - Bell icon shows unread count
3. Go to "Orders" → "Incoming Orders"
4. Review the request and buyer's message
5. Click "Accept" or "Decline"
6. **When accepting:**
   - Transaction status changes to "completed"
   - **Buyer receives notification** with bill details
   - Bill is accessible to both parties
7. Coordinate with buyer for payment and book delivery

## Key Files

- `client/src/pages/OrdersPage.jsx` - Orders management with accept/decline
- `client/src/pages/TransactionDetail.jsx` - Bill/invoice display
- `client/src/pages/NotificationsPage.jsx` - Notifications list
- `client/src/pages/Navbar.jsx` - Bell icon with unread count
- `client/src/pages/Buybook.jsx` - Request submission with notification
- `ENHANCED_NOTIFICATIONS_SETUP.sql` - Database setup script

## Testing the System

### Test Scenario 1: Purchase Request

1. Login as Buyer
2. Browse books and select one
3. Click "Buy Now" and send a message
4. Logout

5. Login as Seller (owner of the book)
6. Check notification bell (should show 1 unread)
7. Click bell → see notification
8. Go to Orders → Incoming Orders
9. See the pending request

### Test Scenario 2: Accept Request & View Bill

1. As Seller, click "Accept" on the pending request
2. Logout

3. Login as Buyer
4. Check notification bell (should show 1 unread)
5. Click bell → see "Your request has been accepted! 🎉"
6. Click notification → view bill
7. See all transaction details, seller contact info, and payment instructions

### Test Scenario 3: Access Bill from Orders

1. As Buyer, go to Orders → My Purchases
2. Find the completed transaction
3. Click "View Details"
4. See the complete bill

## Security

- **Row Level Security (RLS)** ensures users can only:
  - View their own notifications
  - View transactions where they are buyer or seller
  - Update their own notifications (mark as read)
  - Delete their own notifications

- **Transaction Access Control:**
  - Only buyer and seller can view transaction details
  - Sellers can update status of their own transactions
  - Buyers can view their own transactions

## Future Enhancements

Potential improvements for the future:

1. **Real-time Notifications:** Use Supabase Realtime for instant notifications
2. **Email Notifications:** Send email alerts for important updates
3. **Push Notifications:** Mobile push notifications
4. **Payment Integration:** Integrate with payment gateways (if needed)
5. **Rating System:** Allow buyers and sellers to rate each other after transaction
6. **Chat System:** In-app messaging between buyer and seller
7. **Transaction History:** Export transaction history as PDF/CSV

## Support

For issues or questions:
- Check the Supabase logs for database errors
- Verify RLS policies are correctly configured
- Ensure all required tables exist
- Check browser console for frontend errors

---

**Last Updated:** 2026-04-16
**Version:** 1.0.0