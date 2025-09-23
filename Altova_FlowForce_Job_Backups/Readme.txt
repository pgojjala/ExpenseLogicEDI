FlowForce Backup Readme
========================
Backup Date   : 23-Sep-2025
Environment   : Backup_From_Production
FlowForce Ver : 2025 SP1
Author        : Perumal

Jobs Included:
--------------
1. Decrypt_PGP_Files
   - Purpose: Decrypts incoming vendor files using GPG
   - Schedule: Every 15 mins
   - Script: /scripts/decrypt_pgp.bat
   - Input: /input/pgp
   - Output: /input/decrypted
   - Log: /logs/decrypt.log

2. EDI810_To_ApexEDI_CSV
   - Purpose: Convert inbound EDI 810 → ApexEDI CSV
   - Mapping: /mappings/EDI810_To_CSV.mfd
   - Schedule: Hourly
   - Input: /input/decrypted
   - Output: /output/csv
   - Archive: /archive/edi810

Dependencies:
-------------
- GPG Installed at C:\Program Files\GnuPG
- Batch scripts in /scripts
- MapForce Server Runtime available
- Requires Altova License activated

Restore Instructions:
---------------------
1. Import jobs into FlowForce using backup file
2. Update input/output folder paths if environment changes
3. Ensure PGP keys are installed in GPG keyring
4. Re-test job manually before enabling schedule

Change Log:
-----------
2025-09-22 - Updated schedule from 30 mins → hourly (Job: EDI810_To_ApexEDI_CSV)
2025-09-20 - Added new vendor support in PGP decrypt job
