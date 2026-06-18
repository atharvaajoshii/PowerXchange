# Admin Dashboard Setup Guide

## Overview

This document explains how to set up and use the Admin Dashboard for PowerXchange.

## Features

### Admin Dashboard (`/admin`)
- View site statistics (total users, books, verifications pending)
- Quick access to all admin sections
- Recent users and pending verifications overview

### User Management (`/admin/users`)
- View all registered users
- Filter by: All, Verified, Pending
- Search by name, email, or college
- **Verify/Unverify** users
- **Block/Unblock** users
- **Delete** users

### Book Management (`/admin/books`)
- View all books listed on the platform
- Filter by: All, Approved, Pending
- Search by title, author, or seller
- **Approve/Unapprove** books (new books require admin approval)
- **Delete** books

### Transaction Management (`/admin/transactions`)
- View all transactions
- Filter by: All, Pending, Completed, Cancelled
- **Complete** or **Cancel** pending transactions
- View buyer and seller details

## Database Setup

### Step 1: Run the SQL Schema

1. Go to your Supabase project: https://brpdhqdiwnrexygsxulx.supabase.co
2. Navigate to **SQL Editor**
3. Copy the contents of `client/src/supabase_schema.sql`
4. Paste and run the SQL script

This will create:
- `profiles` table - user profiles
- `books` table - book listings
- `transactions` table - buy/sell transactions
- `admin_roles` table - admin user roles
- `wishlist` table - user wishlists
- `reviews` table - user reviews (optional)
- Triggers for auto-updating timestamps
- Row Level Security (RLS) policies
- Helper function for new user signup

### Step 2: Register an Admin User

#### Option A: Via Signup Page (Recommended)

1. Go to the app and sign up with your admin email:
   - Email: `admin@yourcollege.edu`
   - Name: `Admin Name`
   - College: `Your College`

2. After signing up, go to Supabase SQL Editor and run:

```sql
-- Replace with your admin email
INSERT INTO admin_roles (user_id, name, email)
SELECT id, name, email FROM profiles
WHERE email = 'admin@yourcollege.edu';
```

#### Option B: Direct SQL (if you know the user ID)

```sql
INSERT INTO admin_roles (user_id, name, email)
VALUES ('your-user-uuid-here', 'Admin Name', 'admin@yourcollege.edu');
```

### Step 3: Login as Admin

1. Login with the admin credentials you just created
2. You will be automatically redirected to `/admin` instead of `/home`

## How It Works

### Authentication Flow

1. **Regular User Login**: Redirects to `/home`
2. **Admin Login**: Checks `admin_roles` table, redirects to `/admin`

### Book Listing Flow

1. User submits a book via `/sellbook`
2. Book is saved with `is_approved: false`
3. Admin sees pending book in `/admin/books`
4. Admin approves/rejects the book
5. Approved books appear on the home page

### User Verification Flow

1. New user signs up, `is_verified: false` by default
2. Admin sees pending user in `/admin/users`
3. Admin verifies the user
4. Verified users get a badge and full access

## File Structure

```
client/src/
├── pages/
│   ├── AdminDashboard.jsx    # Main admin dashboard
│   ├── AdminUsers.jsx        # User management
│   ├── AdminBooks.jsx        # Book management
│   └── AdminTransactions.jsx # Transaction management
├── App.jsx                   # Added admin routes
├── pages/Login.jsx           # Updated with admin redirect
├── pages/HomePage.jsx        # Fetches books from database
├── pages/BookDetail.jsx      # Fetches book from database
├── pages/Sellbook.jsx        # Saves books to database
├── supabase_schema.sql       # Database schema
└── supabase.js               # Supabase client
```

## Routes

| Route | Description | Access |
|-------|-------------|--------|
| `/admin` | Admin Dashboard | Admin only |
| `/admin/users` | User Management | Admin only |
| `/admin/books` | Book Management | Admin only |
| `/admin/transactions` | Transaction Management | Admin only |
| `/home` | Home Page (books) | All users |
| `/sellbook` | Sell a book | Logged in users |

## Testing

### Test Admin Login

1. Create admin user in database
2. Login with admin credentials
3. Should redirect to `/admin`

### Test Book Approval

1. Login as regular user
2. Go to `/sellbook` and submit a book
3. Logout
4. Login as admin
5. Go to `/admin/books`
6. Approve the book
7. Book should now appear on home page

### Test User Verification

1. Sign up a new user
2. Login as admin
3. Go to `/admin/users`
4. Click "Verify" on the new user
5. User should now show as verified

## Troubleshooting

### Admin login redirects to home instead of admin dashboard

- Check if user exists in `admin_roles` table
- Run: `SELECT * FROM admin_roles WHERE email = 'your-email';`

### Books not appearing on home page

- Check if books are approved: `SELECT * FROM books WHERE is_approved = true;`
- Check RLS policies in Supabase

### "Permission denied" errors

- Ensure RLS policies are set up correctly
- Admin policies should check `admin_roles` table

## Security Notes

- Admin users are stored in `admin_roles` table
- Row Level Security (RLS) policies protect data
- Only admins can view unapproved books and pending users
- Admin authentication is checked on both frontend and database level

## Future Enhancements

- [ ] Admin analytics dashboard with charts
- [ ] Bulk actions (verify multiple users, approve multiple books)
- [ ] Email notifications for pending verifications
- [ ] Admin activity logs
- [ ] Role-based permissions (super admin, moderator)
- [ ] Export data to CSV
