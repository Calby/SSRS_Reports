# Custom Views (x_uvw_)

SQL view definitions following the CaseWorthy x_uvw_ naming convention.
Each file here is the source-controlled definition of a deployed custom view.

## Naming Convention
x_uvw_[Description].sql  — filename matches the view name exactly

## Rules
- Never modify a deployed view without updating the source file here first
- Add a change log entry in the file header comment block for every modification
- After any change, test all reports listed in docs/report-index.md that reference the view
- Do not drop and recreate — use CREATE OR ALTER VIEW so existing report connections survive
- Add new views to the Views table in docs/schema-overview.md

## Deployment
Run the .sql file directly in SSMS against the target database.
The CREATE OR ALTER VIEW statement handles both new and existing views.
