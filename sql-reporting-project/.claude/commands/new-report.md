# /project:new-report

Scaffold a new SSRS report specification and matching dataset query stub.

## Step 1 — Ask me these questions before writing anything:
1. What is the report name? (Will become the file name)
2. What program or grant type does it serve? (SSVF, GPD, PSH, ServTracker, etc.)
3. Who is the audience? (Program manager, director, funder, data team)
4. What is the primary question this report answers?
5. What filters should it have? (Date range, office, program, staff member, etc.)
6. What is the grain? (One row per client / enrollment / service / month / office)
7. What columns are needed?
8. Are there any calculated fields or subtotals?
9. Does it need charts or just a table?
10. Is there an existing similar report to reference?

## Step 2 — Generate these two files:

### File 1: docs/report-specs/[ProgramCode]_[ReportName]_spec.md
Use the template in docs/ssrs-development-guide.md

### File 2: queries/reports/[ProgramCode]_[ReportName]_dataset.sql
A starter CTE-based query with:
- Header comment block (report name, purpose, author placeholder, date)
- Parameter declarations (commented out — for SSRS to inject)
- Logical CTE skeleton based on the spec
- Placeholder SELECT matching the column list
- A note at the bottom: "-- TODO: Validate against [relevant HMIS spec or program guide]"

Do not populate actual table joins until I confirm the spec. Ask first.
