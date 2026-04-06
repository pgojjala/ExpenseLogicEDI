# ===============================
# FINAL - Polling File Move Script (FTP SAFE)
# ===============================

$logFile = "C:\Scripts\FlowForce_Scripts\move_log.txt"

# Vendor configuration
$vendors = @(
    @{ name="AEP"; source="F:\EDI\Automation\EDI-AEP\Incoming"; destination="C:\Users\RPAdmin\Desktop\EDI-AEP\Incoming\" },
    @{ name="ATMOSENERGY"; source="F:\EDI\Automation\EDI-ATMOSENERGY\Incoming"; destination="C:\Users\RPAdmin\Desktop\EDI-ATMOSENERGY\Incoming\" },
    @{ name="CONSUMERSENERGY"; source="F:\EDI\Automation\EDI-CONSUMERSENERGY\Incoming"; destination="C:\Users\RPAdmin\Desktop\EDI-CONSUMERSENERGY\Incoming\" },
    @{ name="SOUTHERNCOMPANYELEC"; source="F:\EDI\Automation\EDI-SOUTHERNCOMPANYELEC\Incoming"; destination="C:\Users\RPAdmin\Desktop\EDI-SOUTHERNCOMPANYELEC\Incoming\" },
    @{ name="DIRECTENERGY"; source="F:\EDI\Automation\EDI-DIRECTENERGY\Incoming"; destination="C:\Users\RPAdmin\Desktop\EDI-DIRECTENERGY\Incoming\" },
    @{ name="BGE"; source="F:\EDI\Automation\EDI-BGE\Incoming"; destination="C:\Users\RPAdmin\Desktop\EDI-BGE\Incoming\" },
    @{ name="TECO"; source="F:\EDI\Automation\EDI-TECO\Incoming"; destination="C:\Users\RPAdmin\Desktop\EDI-TECO\Incoming\Encrypted-Incoming\" }
)

Add-Content $logFile "`n===== Polling Script Started: $(Get-Date) ====="

while ($true) {

    foreach ($vendor in $vendors) {

        try {
            # Ensure destination exists
            if (!(Test-Path $vendor.destination)) {
                New-Item -ItemType Directory -Path $vendor.destination -Force | Out-Null
            }

            # Get files
            $files = Get-ChildItem -Path $vendor.source -File -ErrorAction SilentlyContinue

            foreach ($file in $files) {

                # 🔒 Check if file is still being written (important for FTP)
                $maxRetries = 5
                $retry = 0

                while ($retry -lt $maxRetries) {
                    try {
                        $stream = [System.IO.File]::Open($file.FullName, 'Open', 'Read', 'None')
                        $stream.Close()
                        break
                    }
                    catch {
                        Start-Sleep -Seconds 2
                        $retry++
                    }
                }

                try {
                    Move-Item $file.FullName -Destination $vendor.destination -Force
                    Add-Content $logFile "SUCCESS [$($vendor.name)]: $($file.Name) moved at $(Get-Date)"
                }
                catch {
                    Add-Content $logFile "ERROR [$($vendor.name)]: $($file.Name) - $_"
                }
            }

        }
        catch {
            Add-Content $logFile "ERROR [$($vendor.name)]: $_"
        }
    }

    # ⏱️ Wait 1 minute before next scan
    Start-Sleep -Seconds 60
}