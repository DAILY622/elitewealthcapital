# 🔄 NEON → SUPABASE DATABASE MIGRATION GUIDE

## 📋 Overview
**Direction:** NEON (12 users) → SUPABASE (ALL users)  
**Purpose:** Merge 12 Neon users into primary Supabase database  
**Time Required:** 10 minutes  
**Difficulty:** Easy (copy-paste SQL)

---

## 🎯 Migration Strategy

### What We're Doing:
- **Source:** Neon PostgreSQL (12 users only)
- **Target:** Supabase PostgreSQL (PRIMARY database with all users)
- **Method:** Export from Neon, merge into Supabase

### Duplicate Handling:
If a user exists in both databases (same email), we keep:
- **Highest balance** (protect user money)
- **Highest invested amounts**
- **Best account type** (premium > standard > basic)
- **Verified KYC status** (once verified, always verified)
- **Most recent activity** timestamps
- **Supabase password** (NEVER overwrite existing passwords)

---

## ⚙️ STEP-BY-STEP MIGRATION

### **STEP 1: Export from Neon** ⬇️

1. Open Neon Console: https://console.neon.tech
2. Login with your credentials
3. Navigate to: **SQL Editor**
4. Open file: `export_from_neon_to_supabase.sql`
5. Copy the entire contents
6. Paste into Neon SQL Editor
7. Click **"Run"**
8. Wait 2-3 seconds for results
9. You'll see **12 rows** of INSERT statements in the output

**Example Output:**
```sql
INSERT INTO accounts_customuser (...) VALUES (...) ON CONFLICT (email) DO UPDATE SET ...;
INSERT INTO accounts_customuser (...) VALUES (...) ON CONFLICT (email) DO UPDATE SET ...;
... (10 more rows)
```

10. **SELECT ALL** generated INSERT statements (Ctrl+A in results pane)
11. **COPY** them (Ctrl+C)

---

### **STEP 2: Import into Supabase** ⬆️

1. Open Supabase Dashboard: https://supabase.com/dashboard
2. Login with your credentials
3. Select your project
4. Navigate to: **SQL Editor** (left sidebar)
5. Click **"New Query"**
6. **PASTE** all 12 INSERT statements (Ctrl+V)
7. Review the statements (should have ON CONFLICT clauses)
8. Click **"Run"** or press **Ctrl+Enter**
9. Wait 5-10 seconds for completion

**Expected Result:**
```
12 rows affected
```

If you see errors about duplicate keys, that's OK! The ON CONFLICT clause handles them.

---

### **STEP 3: Verify Migration** ✅

Run this query in **Supabase SQL Editor**:

```sql
-- Check total user count
SELECT COUNT(*) AS total_users FROM accounts_customuser;

-- View recent users
SELECT 
    email, 
    balance, 
    invested_amount, 
    total_profit, 
    account_type,
    kyc_status,
    date_joined
FROM accounts_customuser
ORDER BY date_joined DESC
LIMIT 20;

-- Check for duplicates (should return 0)
SELECT email, COUNT(*) 
FROM accounts_customuser 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Verify financial data integrity
SELECT 
    SUM(balance) AS total_balance,
    SUM(invested_amount) AS total_invested,
    SUM(total_profit) AS total_profit,
    COUNT(*) AS user_count
FROM accounts_customuser;
```

**Expected Results:**
- Total users should be **≥ 12** (original Supabase users + 12 from Neon)
- Zero duplicate emails
- All balances should be positive or zero
- Financial totals should make sense

---

## 🔍 Troubleshooting

### Problem: "Relation does not exist"
**Solution:** You're in the wrong database. Make sure you're connected to the correct Supabase project.

### Problem: Foreign key constraint errors
**Solution:** 
1. Check if `referred_by_id` references exist
2. Run this first:
```sql
-- Temporarily disable foreign key check (if needed)
ALTER TABLE accounts_customuser DISABLE TRIGGER ALL;
-- Then run your INSERT statements
ALTER TABLE accounts_customuser ENABLE TRIGGER ALL;
```

### Problem: "Duplicate key value violates unique constraint"
**Solution:** This shouldn't happen because of ON CONFLICT clause. If it does, the SQL query is missing the ON CONFLICT part. Re-copy from `export_from_neon_to_supabase.sql`.

### Problem: Wrong password after migration
**Solution:** The ON CONFLICT clause DOES NOT update passwords. Existing Supabase passwords are preserved. Only new users get Neon passwords.

---

## 📊 Example Migration Results

### Before Migration:
- **Supabase:** Unknown user count (primary database)
- **Neon:** 12 users, $1,600,645 total balance

### After Migration:
- **Supabase:** Original users + 12 from Neon (merged intelligently)
- **Neon:** Still has 12 users (unchanged, can be deprecated)
- **No duplicates:** Smart merging kept highest values

---

## 🔐 Security Notes

### What Gets Preserved in Supabase:
- ✅ **Passwords** - NEVER overwritten from Neon
- ✅ **2FA settings** - Kept from Supabase
- ✅ **Existing balances** - Only increased if Neon has higher
- ✅ **Referral relationships** - Preserved

### What Gets Updated from Neon:
- ✅ **Higher balances** - If Neon user has more money
- ✅ **Better account type** - If Neon user is premium
- ✅ **Verified KYC** - If Neon user is verified
- ✅ **Recent activity** - If Neon has newer timestamps
- ✅ **Profile info** - If Neon has data and Supabase doesn't

---

## 🚀 Next Steps After Migration

### 1. Update Local Configuration
Update `render.yaml` to use Supabase database:

```yaml
- key: DATABASE_URL
  value: postgresql://postgres.fykzoburtipislgjrcjm:gTpjdkGJBLBjdFGT@aws-1-ap-northeast-1.pooler.supabase.com:5432/postgres
```

### 2. Push to GitHub
```bash
cd "C:\Users\HP PC\Documents\MY-SITE"
git add render.yaml
git commit -m "Switch to Supabase database (primary)"
git push origin main
```

### 3. Update All Repos
- Update `KINGSACCOUNT1/MY-SITE` (already uses Supabase ✅)
- Update `DAILY622/my-dg-site` (needs update)

### 4. Redeploy on Render
- Go to https://dashboard.render.com
- Find your service
- Click **"Manual Deploy"** → **"Deploy latest commit"**
- Wait 5-10 minutes for deployment
- Test login with existing users

### 5. Verify Production
```bash
# Test user login
curl -X POST https://elitewealthcapita.uk/accounts/login/ \
  -d "email=test@example.com&password=testpass123"

# Should return successful login or redirect to dashboard
```

### 6. Deprecate Neon (Optional)
Once everything works with Supabase:
- Keep Neon as backup for 1 week
- Download final backup
- Delete Neon database to save costs

---

## ✅ Migration Checklist

- [ ] Export SQL from Neon database
- [ ] Import SQL into Supabase database
- [ ] Verify user count (should include all users)
- [ ] Check for duplicate emails (should be 0)
- [ ] Verify financial data totals
- [ ] Test login with existing user
- [ ] Update render.yaml with Supabase URL
- [ ] Commit and push to GitHub
- [ ] Redeploy on Render.com
- [ ] Verify production site works
- [ ] Backup Supabase database
- [ ] Schedule Neon deprecation

---

## 📞 Support

If you encounter issues:
1. Check verification queries above
2. Review troubleshooting section
3. Check Supabase logs: Dashboard → Logs
4. Check Neon logs: Console → Query History

---

## 🎯 Expected Final State

After successful migration:
- ✅ All users in single Supabase database
- ✅ No data loss (highest values kept)
- ✅ No duplicate accounts
- ✅ All passwords work correctly
- ✅ Financial data integrity maintained
- ✅ Production site uses Supabase
- ✅ GitHub repos updated
- ✅ Neon can be deprecated

**Result:** One unified database on Supabase! 🚀
