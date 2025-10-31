# ==============================
# Encrypt all 997 ACK files for TECO
# Source:  Ack\Decryption  →  Output: Ack\Encryption
# Uses vendor public key: 0xFC0BA6B4-pub.asc
# ==============================

# --- Paths ---
$SourceFolder = "C:\Users\RPAdmin\Desktop\EDI-TECO\Ack\Decryption"
$TargetFolder = "C:\Users\RPAdmin\Desktop\EDI-TECO\Ack\Encryption"
$KeysFolder   = "C:\Users\RPAdmin\Desktop\EDI-TECO\Key"
$LogFolder    = "C:\Users\RPAdmin\Desktop\EDI-TECO\Incoming\Logs"

# Public key and passphrase
$PublicKeyFile = Join-Path $KeysFolder "0xFC0BA6B4-pub.asc"
$Passphrase = "x3XusS%RB?8ZbnCY."

# GPG executable
$gpgPath = "C:\Program Files\GnuPG\bin\gpg.exe"
if (-not (Test-Path $gpgPath)) { $gpgPath = "C:\Program Files (x86)\GnuPG\bin\gpg.exe" }

# --- Ensure folders exist ---
foreach ($p in @($TargetFolder, $LogFolder)) {
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

# --- Logging ---
$LogFile = Join-Path $LogFolder ("encrypt_997_teco_" + (Get-Date -Format "yyyyMMdd") + ".log")
function Log($m) {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$ts  $m" | Out-File -FilePath $LogFile -Append -Encoding utf8
    Write-Host $m
}

# --- Validate source folder ---
if (-not (Test-Path $SourceFolder)) {
    Log "ERROR: Source folder not found: $SourceFolder"
    exit 1
}

# --- Import public key if missing ---
$keyImported = $false
$keyID = "0xFC0BA6B4"
$existingKeys = & $gpgPath --list-keys $keyID 2>$null
if (-not $existingKeys) {
    if (Test-Path $PublicKeyFile) {
        Log "Importing TECO public key: $PublicKeyFile"
        & $gpgPath --import "$PublicKeyFile" 2>&1 | Out-Null
        $keyImported = $true
    } else {
        Log "ERROR: Public key file not found: $PublicKeyFile"
        exit 2
    }
}

Log "Using public key ID: $keyID"
if ($keyImported) { Log "Public key imported successfully." }

# --- Collect files to encrypt (skip existing .pgp/.gpg) ---
$files = Get-ChildItem -Path $SourceFolder -File | Where-Object { $_.Extension -notin @(".pgp", ".gpg") }
if (-not $files -or $files.Count -eq 0) {
    Log "No files to encrypt in $SourceFolder."
    exit 0
}

# --- Encrypt each file ---
foreach ($f in $files) {
    $inFile  = $f.FullName
    $outFile = Join-Path $TargetFolder ($f.BaseName + ".pgp")

    Log "Encrypting: $($f.Name) → $(Split-Path $outFile -Leaf)"

    & $gpgPath --batch --yes --trust-model always --recipient $keyID `
        --pinentry-mode loopback --passphrase "$Passphrase" `
        --output "$outFile" --encrypt "$inFile"

    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: gpg failed with exit code $LASTEXITCODE for $($f.Name)."
        continue
    }

    Log "Encrypted successfully: $($f.Name) → $(Split-Path $outFile -Leaf)"
}

Log "Encryption run complete."
