-- ============================================================
-- Migration: Add updated_at columns to tables
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Add updated_at to CONTACTS table
ALTER TABLE public.contacts 
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 2. Add updated_at to PRODUCTS table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 3. Add updated_at to TRANSACTIONS table
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 4. Add created_at and updated_at to TRANSACTION_ITEMS table
ALTER TABLE public.transaction_items 
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now();

ALTER TABLE public.transaction_items 
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- 5. Add updated_at to USERS table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- ============================================================
-- Create trigger function for auto-updating updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================================
-- Create triggers for each table
-- ============================================================

-- Contacts trigger
DROP TRIGGER IF EXISTS update_contacts_updated_at ON public.contacts;
CREATE TRIGGER update_contacts_updated_at
    BEFORE UPDATE ON public.contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Products trigger
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Transactions trigger
DROP TRIGGER IF EXISTS update_transactions_updated_at ON public.transactions;
CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Transaction Items trigger
DROP TRIGGER IF EXISTS update_transaction_items_updated_at ON public.transaction_items;
CREATE TRIGGER update_transaction_items_updated_at
    BEFORE UPDATE ON public.transaction_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Users trigger
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- Done! 
-- ============================================================
SELECT 'Migration completed successfully!' as status;
