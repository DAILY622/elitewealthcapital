-- Export all users from Supabase database
-- Run this in Supabase SQL Editor

-- First, check total users
SELECT COUNT(*) as total_users FROM accounts_customuser;

-- Export all users to JSON format
SELECT json_agg(row_to_json(t)) 
FROM (
    SELECT * FROM accounts_customuser ORDER BY date_joined
) t;

-- OR Export as INSERT statements for direct import
SELECT 
    'INSERT INTO accounts_customuser (id, email, password, last_login, is_superuser, is_staff, is_active, full_name, phone, country, profile_image, balance, invested_amount, total_profit, total_withdrawn, referral_bonus, referral_code, referred_by_id, account_type, kyc_status, two_fa_enabled, two_fa_secret, email_verified, email_verification_token, email_verification_sent_at, password_reset_token, password_reset_sent_at, failed_login_attempts, locked_until, has_virtual_card, card_status, card_type, card_number, card_expiry, card_cvv, card_pin, card_limit, card_balance, card_issued_at, card_activated_at, date_joined, last_activity) VALUES (' ||
    quote_literal(id::text) || ', ' ||
    quote_literal(email) || ', ' ||
    quote_literal(password) || ', ' ||
    COALESCE(quote_literal(last_login::text), 'NULL') || ', ' ||
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
    COALESCE(quote_literal(referred_by_id::text), 'NULL') || ', ' ||
    quote_literal(account_type) || ', ' ||
    quote_literal(kyc_status) || ', ' ||
    two_fa_enabled || ', ' ||
    quote_literal(COALESCE(two_fa_secret, '')) || ', ' ||
    email_verified || ', ' ||
    quote_literal(COALESCE(email_verification_token, '')) || ', ' ||
    COALESCE(quote_literal(email_verification_sent_at::text), 'NULL') || ', ' ||
    quote_literal(COALESCE(password_reset_token, '')) || ', ' ||
    COALESCE(quote_literal(password_reset_sent_at::text), 'NULL') || ', ' ||
    failed_login_attempts || ', ' ||
    COALESCE(quote_literal(locked_until::text), 'NULL') || ', ' ||
    has_virtual_card || ', ' ||
    quote_literal(COALESCE(card_status, '')) || ', ' ||
    quote_literal(COALESCE(card_type, '')) || ', ' ||
    quote_literal(COALESCE(card_number, '')) || ', ' ||
    quote_literal(COALESCE(card_expiry, '')) || ', ' ||
    quote_literal(COALESCE(card_cvv, '')) || ', ' ||
    quote_literal(COALESCE(card_pin, '')) || ', ' ||
    COALESCE(card_limit::text, '0') || ', ' ||
    COALESCE(card_balance::text, '0') || ', ' ||
    COALESCE(quote_literal(card_issued_at::text), 'NULL') || ', ' ||
    COALESCE(quote_literal(card_activated_at::text), 'NULL') || ', ' ||
    quote_literal(date_joined::text) || ', ' ||
    COALESCE(quote_literal(last_activity::text), 'NULL') ||
    ') ON CONFLICT (email) DO NOTHING;' as insert_statement
FROM accounts_customuser
ORDER BY date_joined;
