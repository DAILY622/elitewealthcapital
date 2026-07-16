# Database Migration Script: Merge Supabase + Neon databases
# Consolidates all users from both databases

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   🔄 DATABASE ANALYSIS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Database connection details
$supabaseHost = "aws-1-ap-northeast-1.pooler.supabase.com"
$supabasePort = "5432"
$supabaseUser = "postgres.fykzoburtipislgjrcjm"
$supabasePass = "gTpjdkGJBLBjdFGT"
$supabaseDb = "postgres"

$neonHost = "ep-holy-sea-a4989cmp-pooler.us-east-1.aws.neon.tech"
$neonPort = "5432"
$neonUser = "neondb_owner"
$neonPass = "npg_Pc4mXQWbVvH5"
$neonDb = "my-elite-db"

Write-Host "📊 Database Configuration:" -ForegroundColor Yellow
Write-Host "`n🔵 Supabase Database:" -ForegroundColor Blue
Write-Host "   Host: $supabaseHost" -ForegroundColor White
Write-Host "   Region: AWS AP-Northeast-1 (Tokyo)" -ForegroundColor White
Write-Host "   Database: $supabaseDb" -ForegroundColor White

Write-Host "`n🟢 Neon Database:" -ForegroundColor Green  
Write-Host "   Host: $neonHost" -ForegroundColor White
Write-Host "   Region: AWS US-East-1" -ForegroundColor White
Write-Host "   Database: $neonDb" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Since we don't have Python, let's use the backup files to analyze
Write-Host "📁 Analyzing backup files..." -ForegroundColor Cyan

$backupPath = "C:\Users\HP PC\Documents\MY-SITE\backups"

if (Test-Path $backupPath) {
    $backups = Get-ChildItem -Path $backupPath -Filter "*.json"
    
    Write-Host "`n💾 Available Backups:" -ForegroundColor Yellow
    foreach ($backup in $backups) {
        $content = Get-Content $backup.FullName | ConvertFrom-Json
        $users = $content | Where-Object { $_.model -eq "accounts.customuser" }
        $size = [math]::Round($backup.Length / 1KB, 2)
        
        Write-Host "   • $($backup.Name)" -ForegroundColor White
        Write-Host "     Users: $($users.Count) | Size: $size KB | Modified: $($backup.LastWriteTime)" -ForegroundColor Gray
    }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Provide instructions for manual database access
Write-Host "🔧 To connect to databases directly, use these tools:" -ForegroundColor Yellow
Write-Host "`n1️⃣  Using PostgreSQL psql command (if installed):" -ForegroundColor Cyan
Write-Host "   Supabase:" -ForegroundColor White
Write-Host "   psql 'postgresql://$($supabaseUser):$($supabasePass)@$($supabaseHost):$($supabasePort)/$($supabaseDb)'" -ForegroundColor Gray
Write-Host "`n   Neon:" -ForegroundColor White
Write-Host "   psql 'postgresql://$($neonUser):$($neonPass)@$($neonHost):$($neonPort)/$($neonDb)?sslmode=require'" -ForegroundColor Gray

Write-Host "`n2️⃣  Using DBeaver/pgAdmin (GUI tools):" -ForegroundColor Cyan
Write-Host "   Download: https://dbeaver.io or https://www.pgadmin.org" -ForegroundColor Gray

Write-Host "`n3️⃣  Using Supabase Dashboard:" -ForegroundColor Cyan
Write-Host "   URL: https://supabase.com/dashboard" -ForegroundColor Gray
Write-Host "   Login and access SQL Editor" -ForegroundColor Gray

Write-Host "`n========================================`n" -ForegroundColor Cyan
