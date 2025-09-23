Project: EDI_810_to_CSV_ApexEDI
Version: 1.2
Author: Perumal
Last Updated: 22-Sep-2025

Purpose:
This mapping converts inbound EDI 810 (Invoice) files into CSV format required by ApexEDI.

Input:
- File Type: EDI X12 810 (version 4010)
- Source Schema: EDI_810.mfd
- Sample Input: /input/sample_810.edi

Output:
- File Type: CSV (comma-delimited)
- Target Schema: ApexEDI_Invoice.csv
- Sample Output: /output/sample_invoice.csv

Mapping Logic:
- TDS01 compared with sum(SAC05). If mismatch, flag in validation field.
- N1 segments mapped to Customer/Provider fields.
- Dates converted to YYYY-MM-DD format.

Dependencies:
- Requires EDI_810.mfd (schema file)
- Requires CSV definition ApexEDI_Invoice.mfd
- Deployed to FlowForce Job: EDI810_To_ApexEDI_CSV_Job

Execution:
- Manual: Open .mfd in MapForce, press "Run Output".
- FlowForce: Job runs every hour, picks files from /input/decrypted.

Change Log:
- 2025-09-22: Added validation for invoice totals.
- 2025-09-18: Initial deployment to FlowForce.
