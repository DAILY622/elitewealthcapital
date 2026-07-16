# Automated Database Migration Script
# Downloads Python, installs dependencies, merges databases

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   🚀 AUTOMATED DATABASE MERGER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$workDir = "C:\Users\HP PC\Documents\MY-SITE"
$pythonDir = "$workDir\.python-portable"
$pythonExe = "$pythonDir\python.exe"

cd $workDir

# Step 1: Download Python Embeddable
if (-not (Test-Path $pythonExe)) {
    Write-Host "📥 Downloading Python 3.11 (embeddable)..." -ForegroundColor Yellow
    
    $pythonUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
    $pythonZip = "$workDir\python-embed.zip"
    
    Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonZip
    
    Write-Host "📦 Extracting Python..." -ForegroundColor Yellow
    Expand-Archive -Path $pythonZip -DestinationPath $pythonDir -Force
    Remove-Item $pythonZip
    
    # Enable pip
    $pth38 = Get-ChildItem "$pythonDir\python*._pth" | Select-Object -First 1
    if ($pth38) {
        $content = Get-Content $pth38.FullName
        $content = $content -replace "#import site", "import site"
        Set-Content -Path $pth38.FullName -Value $content
    }
    
    # Download get-pip.py
    Write-Host "📥 Installing pip..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$pythonDir\get-pip.py"
    & $pythonExe "$pythonDir\get-pip.py" --no-warn-script-location
    
    Write-Host "✅ Python installed successfully!" -ForegroundColor Green
} else {
    Write-Host "✅ Python already available" -ForegroundColor Green
}

# Step 2: Install psycopg2-binary
Write-Host "`n📦 Installing PostgreSQL library..." -ForegroundColor Yellow
& $pythonExe -m pip install psycopg2-binary --quiet --no-warn-script-location

Write-Host "✅ Dependencies installed" -ForegroundColor Green

# Step 3: Run migration script
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   🔄 STARTING DATABASE MIGRATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📡 Connecting to Supabase and Neon databases..." -ForegroundColor Yellow
Write-Host "⚠️  This may take several minutes...`n" -ForegroundColor Yellow

& $pythonExe "$workDir\auto_merge_databases.py"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   ✅ SCRIPT COMPLETE!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
