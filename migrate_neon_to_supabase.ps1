# PowerShell Database Migration Script
# Migrates 12 users from Neon to Supabase using REST API approach

param(
    [switch]$DryRun = $false
)

Write-Host "`n╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   NEON → SUPABASE DATABASE MIGRATION          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Database connection strings
$neonUrl = "postgresql://neondb_owner:npg_Pc4mXQWbVvH5@ep-holy-sea-a4989cmp-pooler.us-east-1.aws.neon.tech/my-elite-db"
$supabaseUrl = "postgresql://postgres.fykzoburtipislgjrcjm:gTpjdkGJBLBjdFGT@aws-1-ap-northeast-1.pooler.supabase.com:5432/postgres"

Write-Host "📊 DATABASE CONFIGURATION:" -ForegroundColor Yellow
Write-Host "  Source (Neon):      ep-holy-sea-a4989cmp-pooler.us-east-1.aws.neon.tech" -ForegroundColor Gray
Write-Host "  Target (Supabase):  aws-1-ap-northeast-1.pooler.supabase.com`n" -ForegroundColor Gray

# Parse connection details
function Parse-PostgresUrl {
    param([string]$url)
    
    if ($url -match "postgresql://([^:]+):([^@]+)@([^:]+):?(\d+)?/(.+)") {
        return @{
            User = $matches[1]
            Password = $matches[2]
            Host = $matches[3]
            Port = if ($matches[4]) { $matches[4] } else { "5432" }
            Database = $matches[5] -replace '\?.*$', ''
        }
    }
    return $null
}

$neonConn = Parse-PostgresUrl $neonUrl
$supabaseConn = Parse-PostgresUrl $supabaseUrl

if (-not $neonConn -or -not $supabaseConn) {
    Write-Host "❌ Failed to parse database URLs" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Connection details parsed successfully`n" -ForegroundColor Green

# Since we don't have psql or Python with psycopg2, we'll create a manual SQL export
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
Write-Host "⚠️  LIMITATIONS DETECTED:" -ForegroundColor Yellow
Write-Host "   • psql (PostgreSQL client) not installed" -ForegroundColor Gray
Write-Host "   • Python/pip not available" -ForegroundColor Gray
Write-Host "   • Cannot connect directly to databases`n" -ForegroundColor Gray

Write-Host "💡 ALTERNATIVE APPROACH:" -ForegroundColor Cyan
Write-Host "   Using backup file from Neon database`n" -ForegroundColor White

# Check for backup file
$backupFile = ".\render_production_20260502_061326.json"
if (Test-Path $backupFile) {
    Write-Host "✅ Found backup file: $backupFile" -ForegroundColor Green
    
    # Read backup
    Write-Host "`nReading backup data..." -ForegroundColor Yellow
    $backup = Get-Content $backupFile -Raw | ConvertFrom-Json
    
    # Count users
    $users = $backup | Where-Object { $_.model -eq "accounts.customuser" }
    $userCount = $users.Count
    
    Write-Host "✅ Found $userCount users in backup`n" -ForegroundColor Green
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    Write-Host "📋 GENERATING SQL IMPORT SCRIPT...`n" -ForegroundColor Magenta
    
    # Generate SQL
    $sqlStatements = @()
    
    foreach ($user in $users) {
        $fields = $user.fields
        
        # Escape single quotes in strings
        function Escape-SQL {
            param([string]$value)
            if ($null -eq $value) { return "NULL" }
            return "'" + ($value -replace "'", "''") + "'"
        }
        
        $email = Escape-SQL $fields.email
        $username = Escape-SQL $fields.username
        $password = Escape-SQL $fields.password
        $firstName = Escape-SQL $fields.first_name
        $lastName = Escape-SQL $fields.last_name
        $phone = if ($fields.phone) { Escape-SQL $fields.phone } else { "NULL" }
        $country = if ($fields.country) { Escape-SQL $fields.country } else { "NULL" }
        $balance = if ($fields.balance) { $fields.balance } else { "0.00" }
        $invested = if ($fields.invested_amount) { $fields.invested_amount } else { "0.00" }
        $profit = if ($fields.total_profit) { $fields.total_profit } else { "0.00" }
        $refBonus = if ($fields.referral_bonus) { $fields.referral_bonus } else { "0.00" }
        $refCode = Escape-SQL $fields.referral_code
        $accountType = Escape-SQL $fields.account_type
        $kycStatus = Escape-SQL $fields.kyc_status
        $kycDoc = if ($fields.kyc_document) { Escape-SQL $fields.kyc_document } else { "NULL" }
        $isActive = if ($fields.is_active) { "true" } else { "false" }
        $isStaff = if ($fields.is_staff) { "true" } else { "false" }
        $isSuperuser = if ($fields.is_superuser) { "true" } else { "false" }
        $dateJoined = Escape-SQL $fields.date_joined
        $lastLogin = if ($fields.last_login) { Escape-SQL $fields.last_login } else { "NULL" }
        $lastActivity = if ($fields.last_activity) { Escape-SQL $fields.last_activity } else { "NULL" }
        $referredBy = if ($fields.referred_by) { $fields.referred_by } else { "NULL" }
        $profileImage = if ($fields.profile_image) { Escape-SQL $fields.profile_image } else { "NULL" }
        $twoFactor = if ($fields.two_factor_enabled) { "true" } else { "false" }
        $twoFactorSecret = if ($fields.two_factor_secret) { Escape-SQL $fields.two_factor_secret } else { "NULL" }
        
        $sql = @"
INSERT INTO accounts_customuser (
    email, username, password, first_name, last_name, phone, country,
    balance, invested_amount, total_profit, referral_bonus, referral_code,
    account_type, kyc_status, kyc_document, is_active, is_staff, is_superuser,
    date_joined, last_login, last_activity, referred_by_id, profile_image,
    two_factor_enabled, two_factor_secret
) VALUES (
    $email, $username, $password, $firstName, $lastName, $phone, $country,
    $balance, $invested, $profit, $refBonus, $refCode,
    $accountType, $kycStatus, $kycDoc, $isActive, $isStaff, $isSuperuser,
    $dateJoined, $lastLogin, $lastActivity, $referredBy, $profileImage,
    $twoFactor, $twoFactorSecret
)
ON CONFLICT (email) DO UPDATE SET
    balance = GREATEST(EXCLUDED.balance, accounts_customuser.balance),
    invested_amount = GREATEST(EXCLUDED.invested_amount, accounts_customuser.invested_amount),
    total_profit = GREATEST(EXCLUDED.total_profit, accounts_customuser.total_profit),
    referral_bonus = GREATEST(EXCLUDED.referral_bonus, accounts_customuser.referral_bonus),
    account_type = CASE
        WHEN EXCLUDED.account_type = 'premium' OR accounts_customuser.account_type = 'premium' THEN 'premium'
        WHEN EXCLUDED.account_type = 'standard' OR accounts_customuser.account_type = 'standard' THEN 'standard'
        ELSE 'basic'
    END,
    kyc_status = CASE
        WHEN EXCLUDED.kyc_status = 'verified' OR accounts_customuser.kyc_status = 'verified' THEN 'verified'
        WHEN EXCLUDED.kyc_status = 'pending' OR accounts_customuser.kyc_status = 'pending' THEN 'pending'
        ELSE 'not_submitted'
    END,
    last_login = GREATEST(EXCLUDED.last_login, accounts_customuser.last_login),
    last_activity = GREATEST(EXCLUDED.last_activity, accounts_customuser.last_activity),
    is_active = EXCLUDED.is_active OR accounts_customuser.is_active,
    is_staff = EXCLUDED.is_staff OR accounts_customuser.is_staff,
    is_superuser = EXCLUDED.is_superuser OR accounts_customuser.is_superuser;
"@
        
        $sqlStatements += $sql
    }
    
    # Save to file
    $outputFile = ".\neon_users_import.sql"
    $sqlStatements -join "`n`n" | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "✅ Generated SQL import script: $outputFile" -ForegroundColor Green
    Write-Host "   • $userCount INSERT statements with ON CONFLICT handling" -ForegroundColor Gray
    Write-Host "   • Ready to run in Supabase SQL Editor`n" -ForegroundColor Gray
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    Write-Host "📊 PREVIEW (First User):`n" -ForegroundColor Yellow
    Write-Host $sqlStatements[0].Substring(0, [Math]::Min(500, $sqlStatements[0].Length)) -ForegroundColor Gray
    Write-Host "...`n" -ForegroundColor Gray
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    Write-Host "⚡ NEXT STEPS:" -ForegroundColor Magenta
    Write-Host "`n1. Open Supabase Dashboard:" -ForegroundColor Yellow
    Write-Host "   https://supabase.com/dashboard" -ForegroundColor Cyan
    Write-Host "`n2. Go to SQL Editor" -ForegroundColor Yellow
    Write-Host "`n3. Open the generated file and copy all contents:" -ForegroundColor Yellow
    Write-Host "   $outputFile" -ForegroundColor Cyan
    Write-Host "`n4. Paste into Supabase SQL Editor and run" -ForegroundColor Yellow
    Write-Host "`n5. Verify with:" -ForegroundColor Yellow
    Write-Host "   SELECT COUNT(*) FROM accounts_customuser;" -ForegroundColor Cyan
    Write-Host "`n" -ForegroundColor White
    
} else {
    Write-Host "❌ Backup file not found: $backupFile" -ForegroundColor Red
    Write-Host "`nSearching for other backup files..." -ForegroundColor Yellow
    $backups = Get-ChildItem -Filter "*.json" | Where-Object { $_.Name -like "*backup*" -or $_.Name -like "*production*" }
    if ($backups) {
        Write-Host "Found:" -ForegroundColor Green
        $backups | ForEach-Object { Write-Host "  • $($_.Name)" -ForegroundColor White }
    } else {
        Write-Host "No backup files found`n" -ForegroundColor Red
    }
}
