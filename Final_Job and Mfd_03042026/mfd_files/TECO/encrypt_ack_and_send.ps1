# ==============================
# Encrypt all 997 ACK files for PacifiCorp
# Source:  Ack\Decryption  →  Output: Ack\Encryption
# Uses vendor public key identified by UID text "PacifiCorp"
# ==============================

# --- Paths ---
$SourceFolder = "C:\Users\RPAdmin\Desktop\EDI-ROCKYMOUNTAIN\Ack\Decryption"
$TargetFolder = "C:\Users\RPAdmin\Desktop\EDI-ROCKYMOUNTAIN\Ack\Encryption"
$KeysFolder   = "C:\Users\RPAdmin\Desktop\EDI-ROCKYMOUNTAIN\Vendor_Publickey"
$LogFolder    = "C:\Users\RPAdmin\Desktop\EDI-ROCKYMOUNTAIN\Logs"

# Optional: set to the exact public key file if you want the script to import automatically when missing
$PublicKeyFile = Join-Path $KeysFolder "PacifiCorp_PGP_July2024-Aug2026_public.asc"  # adjust extension/name if needed

# How to locate the vendor key inside your keyring
$VendorUidMatch = "PacifiCorp"     # the UID text to search for (safe and readable)

# gpg.exe
$gpgPath = "C:\Program Files\GnuPG\bin\gpg.exe"
if (-not (Test-Path $gpgPath)) { $gpgPath = "C:\Program Files (x86)\GnuPG\bin\gpg.exe" }

# --- Prep ---
foreach ($p in @($TargetFolder, $LogFolder)) {
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}
$LogFile = Join-Path $LogFolder ("encrypt_997_pacificorp_" + (Get-Date -Format "yyyyMMdd") + ".log")
function Log($m){ $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); "$ts  $m" | Out-File -FilePath $LogFile -Append -Encoding utf8; Write-Host $m }

if (-not (Test-Path $SourceFolder)) { Log "ERROR: Source folder not found: $SourceFolder"; exit 1 }

# --- Helper: find fingerprint of the pub key whose UID contains $VendorUidMatch ---
function Get-PubKeyFingerprintByUid([string]$uidMatch){
    $lines = & $gpgPath --list-keys --with-colons 2>$null
    if (-not $lines) { return $null }

    $currentPubFpr = $null
    $inPubBlock    = $false

    foreach($line in $lines){
        if ($line -like "pub:*") {
            $inPubBlock = $true
            $currentPubFpr = $null
            continue
        }
        if ($inPubBlock -and $line -like "fpr:*") {
            # fingerprint is field #10 (1-based) in --with-colons format
            $parts = $line -split ":"
            if ($parts.Count -ge 10) { $currentPubFpr = $parts[9] }
            continue
        }
        if ($inPubBlock -and $line -like "uid:*") {
            if ($line -match [Regex]::Escape($uidMatch)) {
                return $currentPubFpr
            }
        }
    }
    return $null
}

# Ensure vendor key exists in keyring; if not, try to import from file path above
$fpr = Get-PubKeyFingerprintByUid -uidMatch $VendorUidMatch
if (-not $fpr) {
    if (Test-Path $PublicKeyFile) {
        Log "Vendor key not found in keyring. Importing: $PublicKeyFile"
        & $gpgPath --import "$PublicKeyFile" 2>&1 | Out-Null
        $fpr = Get-PubKeyFingerprintByUid -uidMatch $VendorUidMatch
    }
}

if (-not $fpr) {
    Log "ERROR: Could not find PacifiCorp public key in keyring. Import it and retry."
    Log "Hint: gpg --import `"$PublicKeyFile`""
    exit 2
}
Log "Using vendor key fingerprint: $fpr"

# Collect clear files (skip any .pgp/.gpg that might be there by mistake)
$files = Get-ChildItem -Path $SourceFolder -File | Where-Object { $_.Extension -notin @(".pgp",".gpg") } | Sort-Object LastWriteTime
if (-not $files -or $files.Count -eq 0) {
    Log "No files to encrypt in $SourceFolder."
    exit 0
}

# Encrypt each file
foreach($f in $files){
    $inFile  = $f.FullName
    $outFile = Join-Path $TargetFolder ($f.BaseName + ".pgp")

    Log "Encrypting: $($f.Name) -> $(Split-Path $outFile -Leaf)"

    # --trust-model always avoids interactive trust prompts in background runs
    & $gpgPath --batch --yes --trust-model always --recipient $fpr --output "$outFile" --encrypt "$inFile"
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: gpg returned exit code $LASTEXITCODE for $($f.Name)."
        continue
    }

    Log "Encrypted OK: $($f.Name) -> $(Split-Path $outFile -Leaf)"
}

Log "Run complete."
