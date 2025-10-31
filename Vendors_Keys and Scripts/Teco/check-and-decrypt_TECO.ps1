<#
    decrypt_auto_with_pass.ps1
    - Decrypts all .pgp files in $inDir using loopback pinentry and a supplied passphrase
    - Safe argument passing (array form) to avoid quoting issues
    - Logs to a daily logfile
#>

# ---------- CONFIG ----------
$inDir   = "C:\Users\RPAdmin\Desktop\EDI-TECO\Incoming\Encrypted-Incoming"
$outDir  = "C:\Users\RPAdmin\Desktop\EDI-TECO\Incoming\Decrypted-Output"
$passphrase = "x3XusS%RB?8ZbnCY"          # Your passphrase (protect file permissions)
$gpgExe = "C:\Program Files\GnuPG\bin\gpg.exe"
if (-not (Test-Path $gpgExe)) { $gpgExe = "C:\Program Files (x86)\GnuPG\bin\gpg.exe" }

$logDir = Join-Path (Split-Path $outDir -Parent) "Logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir ("decrypt_auto_" + (Get-Date -Format "yyyyMMdd") + ".log")

function Log($msg){
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$ts  $msg" | Out-File -FilePath $logFile -Append -Encoding utf8
    Write-Host $msg
}

# Make sure directories exist
if (-not (Test-Path $inDir)) { Log "ERROR: Input folder not found: $inDir"; exit 1 }
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null; Log "Created output folder: $outDir" }

# Check gpg exists
if (-not (Test-Path $gpgExe)) { Log "ERROR: gpg.exe not found at expected locations."; exit 2 }

# Log current user and GnuPG homedir for debugging
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Log "Running as user: $currentUser"

# Optional: show GPG home (may vary)
$gpgHome = (& $gpgExe --version 2>$null) | Select-String -Pattern "Home:" -SimpleMatch
if ($gpgHome) { Log "GnuPG version/home info: $($gpgHome.Line)" }

# Helper: attempt to ensure agent allows loopback (best-effort)
# This will only work if gpg-agent.conf is writable by this user and gpgconf is available.
try {
    $agentConfPath = Join-Path $env:APPDATA "gnupg\gpg-agent.conf"
    if (Test-Path $agentConfPath) {
        $confText = Get-Content $agentConfPath -ErrorAction SilentlyContinue
        if ($confText -notmatch 'allow-loopback-pinentry') {
            Log "Note: gpg-agent.conf exists but does not contain allow-loopback-pinentry. Please add it manually if needed: $agentConfPath"
        } else {
            Log "gpg-agent.conf already contains allow-loopback-pinentry"
        }
    } else {
        Log "gpg-agent.conf not found at $agentConfPath. Create it and add line: allow-loopback-pinentry"
    }
} catch {
    Log "Warning: could not inspect gpg-agent.conf: $($_.Exception.Message)"
}

# Process files
$files = Get-ChildItem -Path $inDir -Filter *.pgp -File -ErrorAction SilentlyContinue
if (-not $files -or $files.Count -eq 0) { Log "No .pgp files to process in $inDir."; exit 0 }

foreach ($f in $files) {
    $inFile = $f.FullName
    $outFile = Join-Path $outDir ($f.BaseName + ".dec")

    Log "Starting decrypt: $($f.Name)"

    # Build argument array (safer than one long string)
    $args = @(
        "--batch",
        "--yes",
        "--pinentry-mode", "loopback",
        "--passphrase", $passphrase,
        "--output", $outFile,
        "--decrypt", $inFile
    )

    # Run gpg
    $proc = Start-Process -FilePath $gpgExe -ArgumentList $args -NoNewWindow -Wait -PassThru
    $exit = $proc.ExitCode

    if ($exit -eq 0) {
        Log "Decrypted OK -> $outFile"
        try {
            Remove-Item -Path $inFile -Force
            Log "Deleted source encrypted file: $inFile"
        } catch {
            Log "Warning: failed to delete source file: $($_.Exception.Message)"
        }
    } else {
        Log "ERROR: gpg exit code $exit for file $($f.Name)."
        # capture any stderr output - try running gpg with --verbose to debug if needed
    }
}

Log "Script finished."
