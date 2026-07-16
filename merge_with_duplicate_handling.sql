-- COMPLETE DATABASE MERGER WITH DUPLICATE HANDLING
-- This script merges Supabase + Neon users into ONE database
-- Duplicates are merged intelligently (keeps highest balance)

-- Run this in NEON SQL Editor after getting Supabase data

-- ========================================
-- STEP 1: Create temporary table for Supabase users
-- ========================================
CREATE TEMPORARY TABLE supabase_users_temp (LIKE accounts_customuser INCLUDING ALL);

-- ========================================
-- STEP 2: Insert Supabase users here
-- ========================================
-- (Paste INSERT statements from Supabase export here)
-- Example:
-- INSERT INTO supabase_users_temp VALUES (...);


-- ========================================
-- STEP 3: Merge with intelligent duplicate handling
-- ========================================

-- For users that exist in BOTH databases:
-- Keep the one with HIGHER BALANCE and MORE RECENT ACTIVITY
UPDATE accounts_customuser AS neon
SET 
    balance = GREATEST(neon.balance, sup.balance),
    invested_amount = GREATEST(neon.invested_amount, sup.invested_amount),
    total_profit = GREATEST(neon.total_profit, sup.total_profit),
    total_withdrawn = GREATEST(neon.total_withdrawn, sup.total_withdrawn),
    referral_bonus = GREATEST(neon.referral_bonus, sup.referral_bonus),
    last_activity = GREATEST(neon.last_activity, sup.last_activity),
    last_login = GREATEST(neon.last_login, sup.last_login),
    -- Keep phone, country if missing
    phone = COALESCE(neon.phone, sup.phone),
    country = COALESCE(neon.country, sup.country),
    -- Update profile if Supabase has one and Neon doesn't
    profile_image = COALESCE(neon.profile_image, sup.profile_image),
    -- Keep KYC verified status if either is verified
    kyc_status = CASE 
        WHEN neon.kyc_status = 'verified' OR sup.kyc_status = 'verified' THEN 'verified'
        ELSE GREATEST(neon.kyc_status, sup.kyc_status)
    END,
    -- Upgrade account type if Supabase has better type
    account_type = CASE
        WHEN sup.account_type IN ('diamond', 'platinum') THEN sup.account_type
        WHEN neon.account_type IN ('diamond', 'platinum') THEN neon.account_type
        WHEN sup.account_type IN ('elite', 'executive') THEN sup.account_type
        WHEN neon.account_type IN ('elite', 'executive') THEN neon.account_type
        ELSE GREATEST(neon.account_type, sup.account_type)
    END
FROM supabase_users_temp AS sup
WHERE neon.email = sup.email;

-- ========================================
-- STEP 4: Insert NEW users from Supabase (no duplicates)
-- ========================================
INSERT INTO accounts_customuser
SELECT * FROM supabase_users_temp
WHERE email NOT IN (SELECT email FROM accounts_customuser);

-- ========================================
-- STEP 5: Verification queries
-- ========================================

-- Total users after merge
SELECT COUNT(*) as total_users FROM accounts_customuser;

-- Total balance after merge
SELECT SUM(balance) as total_balance FROM accounts_customuser;

-- Show top 10 users by balance
SELECT full_name, email, balance, account_type, date_joined
FROM accounts_customuser
ORDER BY balance DESC
LIMIT 10;

-- Count by account type
SELECT account_type, COUNT(*) as user_count, SUM(balance) as total_balance
FROM accounts_customuser
GROUP BY account_type
ORDER BY user_count DESC;

-- Show recently active users
SELECT full_name, email, last_activity
FROM accounts_customuser
WHERE last_activity IS NOT NULL
ORDER BY last_activity DESC
LIMIT 10;

-- ========================================
-- CLEANUP
-- ========================================
DROP TABLE IF EXISTS supabase_users_temp;

-- ========================================
-- SUMMARY
-- ========================================
SELECT 
    'MERGE COMPLETE!' as status,
    COUNT(*) as total_users,
    SUM(balance) as total_balance,
    SUM(invested_amount) as total_invested,
    SUM(referral_bonus) as total_referral_bonus
FROM accounts_customuser;
