# Report Dataset Queries

SQL dataset queries that back SSRS reports. Each file here corresponds to
a report listed in docs/report-index.md.

## Naming Convention
[ProgramCode]_[ReportName]_dataset.sql

## Rules
- Every file must have a header comment block
- Parameters are declared at the top with DECLARE for local testing
- Remove DECLARE statements when pasting into SSRS dataset definition
- Each file should match a report listed in docs/report-index.md
- Test in SSMS before deploying to SSRS

## Relationship to SSRS
One .sql file per SSRS dataset. A report with multiple datasets
(e.g., main table + a parameter lookup) should have separate .sql files:
    SSVF_MonthlyServiceReport_dataset.sql       ← main dataset
    SSVF_MonthlyServiceReport_programs.sql      ← parameter dropdown
