# SUPABASE DIRECT MIGRATION EXECUTOR
# This script will help you execute the migration

Write-Host "`n╔═══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   SUPABASE DATABASE MIGRATION EXECUTOR        ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📋 MIGRATION INSTRUCTIONS:`n" -ForegroundColor Yellow

Write-Host "OPTION 1: Via Supabase Dashboard (EASIEST)" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────`n" -ForegroundColor Gray

Write-Host "1. Open Supabase Dashboard:" -ForegroundColor White
Write-Host "   https://supabase.com/dashboard`n" -ForegroundColor Cyan

Write-Host "2. Select your project" -ForegroundColor White
Write-Host "   (The one with database: postgres)`n" -ForegroundColor Gray

Write-Host "3. Go to SQL Editor (left sidebar)" -ForegroundColor White
Write-Host "   Click the '+' to create new query`n" -ForegroundColor Gray

Write-Host "4. Open this file in Notepad:" -ForegroundColor White
Write-Host "   neon_users_import.sql" -ForegroundColor Cyan
Write-Host "   (Located in: C:\Users\HP PC\Documents\MY-SITE)`n" -ForegroundColor Gray

Write-Host "5. Select ALL content (Ctrl+A)" -ForegroundColor White
Write-Host "   Copy it (Ctrl+C)`n" -ForegroundColor Gray

Write-Host "6. Paste into Supabase SQL Editor (Ctrl+V)" -ForegroundColor White
Write-Host "7. Click 'Run' or press Ctrl+Enter" -ForegroundColor Green
Write-Host "8. Wait 5-10 seconds for completion`n" -ForegroundColor Gray

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "OPTION 2: Manual Copy-Paste (BACKUP)" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────`n" -ForegroundColor Gray

Write-Host "If Option 1 doesn't work, copy each statement one by one." -ForegroundColor White
Write-Host "There are 12 statements total in the file.`n" -ForegroundColor Gray

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "✅ VERIFICATION (Run after migration):" -ForegroundColor Green
Write-Host "─────────────────────────────────────────────`n" -ForegroundColor Gray

Write-Host "In Supabase SQL Editor, run these queries:`n" -ForegroundColor White

$verifySQL = @"
-- Count total users
SELECT COUNT(*) AS total_users FROM accounts_customuser;

-- Check for duplicates (should be 0)
SELECT email, COUNT(*) 
FROM accounts_customuser 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Sum financial data
SELECT 
    SUM(balance) AS total_balance,
    SUM(invested_amount) AS total_invested,
    SUM(total_profit) AS total_profit,
    COUNT(*) AS user_count
FROM accounts_customuser;

-- View recent users
SELECT email, balance, invested_amount, account_type, date_joined
FROM accounts_customuser
ORDER BY date_joined DESC
LIMIT 20;
"@

Write-Host $verifySQL -ForegroundColor Cyan

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "🎯 EXPECTED RESULTS:" -ForegroundColor Yellow
Write-Host "  • Total users: 12 or more (if Supabase had existing users)" -ForegroundColor White
Write-Host "  • Duplicates: 0" -ForegroundColor White
Write-Host "  • Total balance: At least $1,600,645" -ForegroundColor White
Write-Host "  • No errors`n" -ForegroundColor White

Write-Host "🚀 AFTER MIGRATION:" -ForegroundColor Magenta
Write-Host "  ✅ All users in ONE Supabase database" -ForegroundColor Green
Write-Host "  ✅ render.yaml already updated" -ForegroundColor Green
Write-Host "  ✅ Ready to deploy on Render.com" -ForegroundColor Green
Write-Host "  ✅ Production ready!`n" -ForegroundColor Green

Write-Host "Press any key to open the SQL file in Notepad..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Open the SQL file
notepad "C:\Users\HP PC\Documents\MY-SITE\neon_users_import.sql"

# Open Supabase dashboard
Start-Process "https://supabase.com/dashboard"

Write-Host "`n✅ Opened SQL file and Supabase dashboard!" -ForegroundColor Green
Write-Host "Follow the instructions above to complete migration.`n" -ForegroundColor White
