-- ═══════════════════════════════════════════════════════════════
-- EXPORT USERS FROM NEON TO SUPABASE
-- ═══════════════════════════════════════════════════════════════
-- Purpose: Export 12 users from Neon and merge into Supabase
-- Direction: NEON → SUPABASE (reversed from original plan)
-- Duplicate Strategy: Keep highest balances and best account info
-- ═══════════════════════════════════════════════════════════════

-- STEP 1: RUN THIS IN NEON SQL EDITOR
-- This generates INSERT statements with smart duplicate handling

SELECT 
    'INSERT INTO accounts_customuser (
        email, username, password, first_name, last_name, phone, country,
        balance, invested_amount, total_profit, referral_bonus, referral_code,
        account_type, kyc_status, kyc_document, is_active, is_staff, is_superuser,
        date_joined, last_login, last_activity, referred_by_id, profile_image,
        two_factor_enabled, two_factor_secret
    ) VALUES (' ||
    quote_literal(email) || ', ' ||
    quote_literal(username) || ', ' ||
    quote_literal(password) || ', ' ||
    quote_literal(first_name) || ', ' ||
    quote_literal(last_name) || ', ' ||
    quote_literal(phone) || ', ' ||
    quote_literal(country) || ', ' ||
    balance || ', ' ||
    invested_amount || ', ' ||
    total_profit || ', ' ||
    referral_bonus || ', ' ||
    quote_literal(referral_code) || ', ' ||
    quote_literal(account_type) || ', ' ||
    quote_literal(kyc_status) || ', ' ||
    COALESCE(quote_literal(kyc_document), 'NULL') || ', ' ||
    is_active || ', ' ||
    is_staff || ', ' ||
    is_superuser || ', ' ||
    quote_literal(date_joined::text) || ', ' ||
    COALESCE(quote_literal(last_login::text), 'NULL') || ', ' ||
    COALESCE(quote_literal(last_activity::text), 'NULL') || ', ' ||
    COALESCE(referred_by_id::text, 'NULL') || ', ' ||
    COALESCE(quote_literal(profile_image), 'NULL') || ', ' ||
    COALESCE(two_factor_enabled, false) || ', ' ||
    COALESCE(quote_literal(two_factor_secret), 'NULL') ||
    ')
ON CONFLICT (email) DO UPDATE SET
    -- Financial: Keep HIGHEST values (protect user money)
    balance = GREATEST(EXCLUDED.balance, accounts_customuser.balance),
    invested_amount = GREATEST(EXCLUDED.invested_amount, accounts_customuser.invested_amount),
    total_profit = GREATEST(EXCLUDED.total_profit, accounts_customuser.total_profit),
    referral_bonus = GREATEST(EXCLUDED.referral_bonus, accounts_customuser.referral_bonus),
    
    -- Account Type: Keep BEST tier (premium > standard > basic)
    account_type = CASE
        WHEN EXCLUDED.account_type = ''premium'' OR accounts_customuser.account_type = ''premium'' THEN ''premium''
        WHEN EXCLUDED.account_type = ''standard'' OR accounts_customuser.account_type = ''standard'' THEN ''standard''
        ELSE ''basic''
    END,
    
    -- KYC: Keep VERIFIED status (once verified, always verified)
    kyc_status = CASE
        WHEN EXCLUDED.kyc_status = ''verified'' OR accounts_customuser.kyc_status = ''verified'' THEN ''verified''
        WHEN EXCLUDED.kyc_status = ''pending'' OR accounts_customuser.kyc_status = ''pending'' THEN ''pending''
        ELSE ''not_submitted''
    END,
    kyc_document = COALESCE(EXCLUDED.kyc_document, accounts_customuser.kyc_document),
    
    -- Activity: Keep most RECENT activity
    last_login = CASE
        WHEN EXCLUDED.last_login IS NULL THEN accounts_customuser.last_login
        WHEN accounts_customuser.last_login IS NULL THEN EXCLUDED.last_login
        ELSE GREATEST(EXCLUDED.last_login, accounts_customuser.last_login)
    END,
    last_activity = CASE
        WHEN EXCLUDED.last_activity IS NULL THEN accounts_customuser.last_activity
        WHEN accounts_customuser.last_activity IS NULL THEN EXCLUDED.last_activity
        ELSE GREATEST(EXCLUDED.last_activity, accounts_customuser.last_activity)
    END,
    
    -- Profile: Update if new value provided
    first_name = COALESCE(NULLIF(EXCLUDED.first_name, ''''), accounts_customuser.first_name),
    last_name = COALESCE(NULLIF(EXCLUDED.last_name, ''''), accounts_customuser.last_name),
    phone = COALESCE(NULLIF(EXCLUDED.phone, ''''), accounts_customuser.phone),
    country = COALESCE(NULLIF(EXCLUDED.country, ''''), accounts_customuser.country),
    profile_image = COALESCE(NULLIF(EXCLUDED.profile_image, ''''), accounts_customuser.profile_image),
    
    -- Security: NEVER overwrite password or 2FA from Supabase
    -- password stays as is in Supabase
    -- two_factor settings stay as is in Supabase
    
    -- Referral: Keep existing if set
    referred_by_id = COALESCE(accounts_customuser.referred_by_id, EXCLUDED.referred_by_id),
    
    -- Admin flags: Keep TRUE if either is true
    is_active = EXCLUDED.is_active OR accounts_customuser.is_active,
    is_staff = EXCLUDED.is_staff OR accounts_customuser.is_staff,
    is_superuser = EXCLUDED.is_superuser OR accounts_customuser.is_superuser;'
    AS migration_sql
FROM accounts_customuser
ORDER BY date_joined;

-- ═══════════════════════════════════════════════════════════════
-- INSTRUCTIONS:
-- ═══════════════════════════════════════════════════════════════
-- 1. Open Neon dashboard: https://console.neon.tech
-- 2. Navigate to SQL Editor
-- 3. Copy and paste this entire query
-- 4. Click "Run" - you'll see 12 rows of INSERT statements
-- 5. Copy ALL the generated INSERT statements
-- 6. Open Supabase dashboard: https://supabase.com/dashboard
-- 7. Go to SQL Editor
-- 8. Paste all INSERT statements
-- 9. Click "Run" to merge users into Supabase
-- 10. Verify: SELECT COUNT(*) FROM accounts_customuser;
--
-- RESULT: All Neon users merged into Supabase with smart duplicate handling
-- ═══════════════════════════════════════════════════════════════

-- VERIFICATION QUERY (run in Supabase AFTER migration):
-- SELECT email, balance, invested_amount, total_profit, account_type, kyc_status
-- FROM accounts_customuser
-- ORDER BY date_joined DESC;
