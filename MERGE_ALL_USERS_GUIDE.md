# 🔄 COMPLETE DATABASE MERGER - ALL USERS + DUPLICATE HANDLING

## 🎯 GOAL
Merge Supabase + Neon databases into **ONE** database with intelligent duplicate handling.

---

## 📋 DUPLICATE HANDLING STRATEGY

When a user exists in BOTH databases, we **MERGE** their data:

### **Financial Data** - Keep HIGHEST values:
- ✅ Balance → Keep highest
- ✅ Invested Amount → Keep highest  
- ✅ Total Profit → Keep highest
- ✅ Total Withdrawn → Keep highest
- ✅ Referral Bonus → Keep highest

### **Account Info** - Keep BEST values:
- ✅ Account Type → Keep premium type (diamond > platinum > elite > etc.)
- ✅ KYC Status → Keep 'verified' if either is verified
- ✅ Last Activity → Keep most recent
- ✅ Profile Image → Keep if exists
- ✅ Phone/Country → Fill if missing

### **Authentication** - Keep NEON version:
- Password hash (from Neon - don't overwrite)
- Email verification status
- 2FA settings

---

## 🚀 STEP-BY-STEP MERGE PROCESS

### **STEP 1: Export from Supabase**

1. Go to: https://supabase.com/dashboard
2. Open **SQL Editor**
3. Run this query:

```sql
-- Count users first
SELECT COUNT(*) FROM accounts_customuser;

-- Export all users with INSERT format
SELECT 
    'INSERT INTO supabase_users_temp VALUES (' ||
    quote_literal(id::text) || '::uuid, ' ||
    quote_literal(email) || ', ' ||
    quote_literal(password) || ', ' ||
    COALESCE(quote_literal(last_login::text), 'NULL') || '::timestamp, ' ||
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
    COALESCE(quote_literal(referred_by_id::text), 'NULL') || '::uuid, ' ||
    quote_literal(account_type) || ', ' ||
    quote_literal(kyc_status) || ', ' ||
    two_fa_enabled || ', ' ||
    quote_literal(COALESCE(two_fa_secret, '')) || ', ' ||
    email_verified || ', ' ||
    quote_literal(COALESCE(email_verification_token, '')) || ', ' ||
    COALESCE(quote_literal(email_verification_sent_at::text), 'NULL') || '::timestamp, ' ||
    quote_literal(COALESCE(password_reset_token, '')) || ', ' ||
    COALESCE(quote_literal(password_reset_sent_at::text), 'NULL') || '::timestamp, ' ||
    failed_login_attempts || ', ' ||
    COALESCE(quote_literal(locked_until::text), 'NULL') || '::timestamp, ' ||
    has_virtual_card || ', ' ||
    quote_literal(COALESCE(card_status, '')) || ', ' ||
    quote_literal(COALESCE(card_type, '')) || ', ' ||
    quote_literal(COALESCE(card_number, '')) || ', ' ||
    quote_literal(COALESCE(card_expiry, '')) || ', ' ||
    quote_literal(COALESCE(card_cvv, '')) || ', ' ||
    quote_literal(COALESCE(card_pin, '')) || ', ' ||
    COALESCE(card_limit, 0) || ', ' ||
    COALESCE(card_balance, 0) || ', ' ||
    COALESCE(quote_literal(card_issued_at::text), 'NULL') || '::timestamp, ' ||
    COALESCE(quote_literal(card_activated_at::text), 'NULL') || '::timestamp, ' ||
    quote_literal(date_joined::text) || '::timestamp, ' ||
    COALESCE(quote_literal(last_activity::text), 'NULL') || '::timestamp' ||
    ');' as insert_statement
FROM accounts_customuser
ORDER BY date_joined;
```

4. **Copy ALL the INSERT statements**
5. Save to a text file (supabase_export.txt)

---

### **STEP 2: Import to Neon with Merge**

1. Go to: https://console.neon.tech
2. Open **SQL Editor**
3. Run the complete script: `merge_with_duplicate_handling.sql`
4. In STEP 2 section, **paste the INSERT statements** from Supabase
5. Execute the entire script

---

## 📊 WHAT HAPPENS

### **Before Merge:**
```
Supabase: X users
Neon:     12 users
Total:    X + 12 users (may have duplicates)
```

### **After Merge:**
```
Neon:     Y unique users (duplicates merged intelligently)
Total Balance: Combined from both DBs
Total Invested: Combined from both DBs
```

### **Example Duplicate Merge:**

**User: john@example.com**

| Field | Supabase | Neon | **Result** |
|-------|----------|------|------------|
| Balance | $5,000 | $3,000 | **$5,000** (higher) |
| Invested | $2,000 | $1,000 | **$2,000** (higher) |
| Account Type | premium | starter | **premium** (better) |
| KYC Status | pending | verified | **verified** (better) |
| Last Activity | Jan 1 | Jan 15 | **Jan 15** (recent) |

---

## ✅ VERIFICATION

After merge, the script shows:

```sql
-- Total users
-- Total balance
-- Top 10 users by balance
-- Users by account type
-- Recent activity
```

---

## 🎉 EXPECTED RESULTS

You should see:
- ✅ **All unique users** from both databases
- ✅ **Duplicates merged** with best data from each
- ✅ **No data loss** - always keep highest values
- ✅ **Single source of truth** - everything in Neon

---

## ⚠️ IMPORTANT NOTES

1. **Backup First**: The script is safe, but always backup!
2. **Read-Only on Supabase**: We only READ from Supabase, never modify
3. **All Changes in Neon**: All merging happens in Neon database
4. **Reversible**: Neon has automatic backups if needed

---

## 🆘 IF YOU NEED HELP

Just tell me:
- How many users in Supabase?
- Any errors when running the script?
- Need help with any step?

---

## 📞 AFTER SUCCESSFUL MERGE

Reply with:
1. Total users after merge
2. Total balance after merge
3. Any duplicate users found

Then I'll:
1. Update GitHub repos to use Neon only
2. Remove Supabase from configuration
3. Help you redeploy with single database!

---

**Ready? Let's merge all your users into one database!** 🚀
