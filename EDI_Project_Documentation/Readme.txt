Readme – EDI Project SOP Documentation
=======================================

Project: RadiusPoint - EDI Developer Retainer
Client: RadiusPoint
Vendors: ApexEDI + multiple vendor partners
Last Updated: 23-Sep-2025
Owner: Perumal

Scope:
This SOP covers inbound 810 (Invoice), outbound 997 (Acknowledgment),
and vendor onboarding processes using Altova MapForce & FlowForce.

Environment:
- Dev: Local VM, Test SFTP
- Prod: Azure VM
- Tools: MapForce 2025, FlowForce Server 2025, GPG 2.4, WinSCP

Folder Structure:
/mappings   -> .mfd files for EDI ↔ CSV
/jobs       -> FlowForce job backup exports
/scripts    -> Batch files for decryption & SFTP
/input      -> Incoming vendor files
/output     -> Converted CSV output
/logs       -> Execution & error logs
/archive    -> Archived input/output files

Key Processes:
- 810 Invoice: Vendor EDI → CSV → ApexEDI
- 997 Acknowledgment: ApexEDI → Vendor
Validation includes TDS01 vs SAC05 total check.

FlowForce Jobs:
- Decrypt_PGP_Files (runs every 15 mins, input: /input/pgp, output: /input/decrypted)
- EDI810_To_ApexEDI_CSV (runs hourly, maps 810 → CSV, archives after success)

Security:
- Vendor files encrypted using PGP
- Keys stored in GPG keyring on Azure VM
- New vendor onboarding requires exchanging public keys

Change Log:
2025-09-22 – Added validation for invoice totals
2025-09-20 – Added new vendor onboarding SOP
2025-09-15 – Initial SOP documentation
