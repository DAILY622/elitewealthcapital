# Quick Database Migration Guide

## 🚀 FASTEST METHOD: Manual Copy via Dashboards

### Step 1: Access Supabase Dashboard
1. Go to: **https://supabase.com/dashboard**
2. Login with your credentials
3. Select your project (should be the one with `aws-1-ap-northeast-1` region)
4. Click **SQL Editor** in the left sidebar

### Step 2: Check User Count
Run this query in Supabase SQL Editor:
```sql
SELECT COUNT(*) FROM accounts_customuser;
```
**Note down the number!**

### Step 3: Export Users
Option A - Get INSERT statements (Recommended):
```sql
-- Copy the entire output and save to a text file
SELECT 
    'INSERT INTO accounts_customuser (...) VALUES (...) ON CONFLICT (email) DO NOTHING;'
FROM accounts_customuser
ORDER BY date_joined;
```

Option B - Use the export script:
1. Open `export_supabase_users.sql` in Supabase SQL Editor
2. Run the export query
3. Copy all results
4. Save to `supabase_users_export.sql`

### Step 4: Access Neon Dashboard
1. Go to: **https://console.neon.tech**
2. Login with your credentials
3. Find project with `ep-holy-sea-a4989cmp` in the connection string
4. Click **SQL Editor**

### Step 5: Import to Neon
1. Paste the INSERT statements from Step 3
2. Run the query
3. Verify user count:
```sql
SELECT COUNT(*) FROM accounts_customuser;
```

Expected: **12 (Neon) + X (Supabase) = Total Users**

---

## 📞 ALTERNATIVE: Tell Me User Counts

If you just want me to know the numbers:

1. Check Supabase user count (Step 2 above)
2. Reply with: "Supabase has X users"
3. I'll create a detailed merge strategy

---

## 🎯 AFTER MIGRATION

Once all users are in Neon:

1. Update `render.yaml` in both GitHub repos to use Neon
2. Push changes
3. Redeploy application
4. All users will be in one database!

---

## 🆘 NEED HELP?

Just tell me:
- How many users are in Supabase?
- Any errors you're seeing?
- Which method you prefer?
