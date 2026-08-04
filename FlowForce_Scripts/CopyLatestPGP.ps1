# ===========================================================
# CopyLatestPGP.ps1
# Copies ONLY a NEW encrypted PGP file to FTP Outgoing
# ===========================================================

$SourceFolder      = "C:\Users\RPAdmin\Desktop\EDI-ROCKYMOUNTAIN\Ack\Encryption"
$DestinationFolder = "\\100.80.146.90\f$\FPT Clients\EDI\Automation\EDI-ROCKYMOUNTAIN\Outgoing"

$LogFolder         = "C:\Temp"
$LogFile           = "$LogFolder\CopyLatestPGP.log"
$LastProcessedFile = "$LogFolder\LastProcessedPGP.txt"

#------------------------------------------------------------
# Create Log Folder
#------------------------------------------------------------

if (!(Test-Path $LogFolder))
{
    New-Item -ItemType Directory -Path $LogFolder | Out-Null
}

Add-Content $LogFile ""
Add-Content $LogFile "=========================================================="
Add-Content $LogFile "Started : $(Get-Date)"

try
{
    #--------------------------------------------------------
    # Validate folders
    #--------------------------------------------------------

    if (!(Test-Path $SourceFolder))
    {
        throw "Source folder not found."
    }

    if (!(Test-Path $DestinationFolder))
    {
        throw "Destination folder not found."
    }

    #--------------------------------------------------------
    # Get newest PGP file
    #--------------------------------------------------------

    $Files = Get-ChildItem $SourceFolder -Filter *.pgp

    if (!$Files)
    {
        Add-Content $LogFile "No PGP file found."
        Write-Host "NO_FILE_FOUND"
        exit 0
    }

    $LatestFile = $Files |
                  Sort-Object CreationTimeUtc -Descending |
                  Select-Object -First 1

    Add-Content $LogFile "Latest File : $($LatestFile.Name)"
    Add-Content $LogFile "Created Time : $($LatestFile.CreationTime)"

    #--------------------------------------------------------
    # Read last processed filename
    #--------------------------------------------------------

    $LastProcessed = ""

    if (Test-Path $LastProcessedFile)
    {
        $LastProcessed = (Get-Content $LastProcessedFile -ErrorAction SilentlyContinue).Trim()
    }

    Add-Content $LogFile "Last Processed : $LastProcessed"

    #--------------------------------------------------------
    # Skip if already processed
    #--------------------------------------------------------

    if ($LatestFile.Name -eq $LastProcessed)
    {
        Add-Content $LogFile "Already processed. Nothing to copy."

        Write-Host "ALREADY_PROCESSED"
        Write-Host $LatestFile.Name

        exit 0
    }

    #--------------------------------------------------------
    # Remove same file from destination (if exists)
    #--------------------------------------------------------

    $DestinationFile = Join-Path $DestinationFolder $LatestFile.Name

    if (Test-Path $DestinationFile)
    {
        Remove-Item $DestinationFile -Force
    }

    #--------------------------------------------------------
    # Copy latest file
    #--------------------------------------------------------

    Copy-Item $LatestFile.FullName -Destination $DestinationFolder -Force

    #--------------------------------------------------------
    # Verify Copy
    #--------------------------------------------------------

    if (!(Test-Path $DestinationFile))
    {
        throw "Copy verification failed."
    }

    $SourceHash = (Get-FileHash $LatestFile.FullName -Algorithm SHA256).Hash
    $DestHash   = (Get-FileHash $DestinationFile -Algorithm SHA256).Hash

    if ($SourceHash -ne $DestHash)
    {
        throw "File verification failed. Hash mismatch."
    }

    #--------------------------------------------------------
    # Update Last Processed File
    #--------------------------------------------------------

    Set-Content $LastProcessedFile $LatestFile.Name

    Add-Content $LogFile "Copied Successfully."
    Add-Content $LogFile "Destination : $DestinationFolder"

    Write-Host "SUCCESS"
    Write-Host $LatestFile.Name
}
catch
{
    Add-Content $LogFile "ERROR : $($_.Exception.Message)"

    Write-Host "FAILED"
    Write-Host $_.Exception.Message

    exit 1
}

Add-Content $LogFile "Finished : $(Get-Date)"
Add-Content $LogFile "=========================================================="