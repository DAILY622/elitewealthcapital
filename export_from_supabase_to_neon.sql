-- ============================================
-- SUPABASE → NEON MIGRATION SCRIPT
-- Export from Supabase, Import to Neon
-- Handles duplicates intelligently
-- ============================================

-- RUN THIS IN SUPABASE SQL EDITOR FIRST
-- ============================================

-- Step 1: Check how many users you have
SELECT 
    COUNT(*) as total_users,
    SUM(balance) as total_balance,
    SUM(invested_amount) as total_invested
FROM accounts_customuser;

-- Step 2: Export all users as INSERT statements for Neon
-- Copy ALL the output from this query
SELECT 
    'INSERT INTO accounts_customuser (
        id, email, password, last_login, is_superuser, is_staff, is_active,
        full_name, phone, country, profile_image,
        balance, invested_amount, total_profit, total_withdrawn, referral_bonus,
        referral_code, referred_by_id, account_type, kyc_status,
        two_fa_enabled, two_fa_secret, email_verified,
        email_verification_token, email_verification_sent_at,
        password_reset_token, password_reset_sent_at,
        failed_login_attempts, locked_until,
        has_virtual_card, card_status, card_type, card_number, card_expiry, card_cvv,
        card_pin, card_limit, card_balance, card_issued_at, card_activated_at,
        date_joined, last_activity
    ) VALUES (' ||
    quote_literal(id::text) || '::uuid, ' ||
    quote_literal(email) || ', ' ||
    quote_literal(password) || ', ' ||
    COALESCE(quote_literal(last_login::text), 'NULL') || CASE WHEN last_login IS NULL THEN '' ELSE '::timestamp' END || ', ' ||
    is_superuser || ', ' ||
    is_staff || ', ' ||
    is_active || ', ' ||
    quote_literal(full_name) || ', ' ||
    quote_literal(COALESCE(phone, '')) || ', ' ||
    quote_literal(COALESCE(country, '')) || ', ' ||
    quote_literal(COALESCE(profile_image, '')) || ', ' ||
    balance || ', ' ||
    invested_amount || ', ' ||
    total_profit || ', ' ||
    total_withdrawn || ', ' ||
    referral_bonus || ', ' ||
    quote_literal(referral_code) || ', ' ||
    COALESCE(quote_literal(referred_by_id::text), 'NULL') || CASE WHEN referred_by_id IS NULL THEN '' ELSE '::uuid' END || ', ' ||
    quote_literal(account_type) || ', ' ||
    quote_literal(kyc_status) || ', ' ||
    two_fa_enabled || ', ' ||
    quote_literal(COALESCE(two_fa_secret, '')) || ', ' ||
    email_verified || ', ' ||
    quote_literal(COALESCE(email_verification_token, '')) || ', ' ||
    COALESCE(quote_literal(email_verification_sent_at::text), 'NULL') || CASE WHEN email_verification_sent_at IS NULL THEN '' ELSE '::timestamp' END || ', ' ||
    quote_literal(COALESCE(password_reset_token, '')) || ', ' ||
    COALESCE(quote_literal(password_reset_sent_at::text), 'NULL') || CASE WHEN password_reset_sent_at IS NULL THEN '' ELSE '::timestamp' END || ', ' ||
    failed_login_attempts || ', ' ||
    COALESCE(quote_literal(locked_until::text), 'NULL') || CASE WHEN locked_until IS NULL THEN '' ELSE '::timestamp' END || ', ' ||
    has_virtual_card || ', ' ||
    quote_literal(COALESCE(card_status, '')) || ', ' ||
    quote_literal(COALESCE(card_type, '')) || ', ' ||
    quote_literal(COALESCE(card_number, '')) || ', ' ||
    quote_literal(COALESCE(card_expiry, '')) || ', ' ||
    quote_literal(COALESCE(card_cvv, '')) || ', ' ||
    quote_literal(COALESCE(card_pin, '')) || ', ' ||
    COALESCE(card_limit, 0) || ', ' ||
    COALESCE(card_balance, 0) || ', ' ||
    COALESCE(quote_literal(card_issued_at::text), 'NULL') || CASE WHEN card_issued_at IS NULL THEN '' ELSE '::timestamp' END || ', ' ||
    COALESCE(quote_literal(card_activated_at::text), 'NULL') || CASE WHEN card_activated_at IS NULL THEN '' ELSE '::timestamp' END || ', ' ||
    quote_literal(date_joined::text) || '::timestamp, ' ||
    COALESCE(quote_literal(last_activity::text), 'NULL') || CASE WHEN last_activity IS NULL THEN '' ELSE '::timestamp' END ||
    ') ON CONFLICT (email) DO UPDATE SET
        balance = GREATEST(accounts_customuser.balance, EXCLUDED.balance),
        invested_amount = GREATEST(accounts_customuser.invested_amount, EXCLUDED.invested_amount),
        total_profit = GREATEST(accounts_customuser.total_profit, EXCLUDED.total_profit),
        total_withdrawn = GREATEST(accounts_customuser.total_withdrawn, EXCLUDED.total_withdrawn),
        referral_bonus = GREATEST(accounts_customuser.referral_bonus, EXCLUDED.referral_bonus),
        last_activity = GREATEST(accounts_customuser.last_activity, EXCLUDED.last_activity),
        phone = COALESCE(NULLIF(accounts_customuser.phone, ''''), EXCLUDED.phone),
        country = COALESCE(NULLIF(accounts_customuser.country, ''''), EXCLUDED.country),
        profile_image = COALESCE(NULLIF(accounts_customuser.profile_image, ''''), EXCLUDED.profile_image);' 
    as migration_statement
FROM accounts_customuser
ORDER BY date_joined;

-- Step 3: Export investments, deposits, withdrawals (if needed)
SELECT COUNT(*) as total_investments FROM investments_investment;
SELECT COUNT(*) as total_deposits FROM investments_deposit;
SELECT COUNT(*) as total_withdrawals FROM investments_withdrawal;
