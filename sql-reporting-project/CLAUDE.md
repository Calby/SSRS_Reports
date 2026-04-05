# SQL Reporting — CaseWorthy / ServTracker

## What This Project Covers
SQL query development, SSRS report development, and view creation for CaseWorthy
(ClientTrack) and ServTracker databases. Supports nonprofit social services reporting
across HMIS-compliant programs: SSVF, GPD, HUD-VASH, PSH, RRH, CoC, ESG, and
aging services (ServTracker).

## Stack
- SQL Server (T-SQL)
- SSRS (SQL Server Reporting Services)
- CaseWorthy / ClientTrack schema
- ServTracker schema (aging services)

## Key Directories
- queries/ad-hoc/   — one-off analysis and exploration queries
- queries/reports/  — dataset queries backing SSRS reports
- queries/views/    — view definitions (x_uvw_ convention)
- ssrs/             — .rdl report files and SSRS specs
- docs/             — schema reference, report index, dev guide
- scratch/          — working drafts (gitignored)

## Naming Conventions
See .claude/rules/naming-conventions.md for full detail.
- Views:          x_uvw_[Description]
- Report queries: [ProgramCode]_[ReportName]_dataset.sql
- Ad hoc:         [YYYY-MM-DD]_[topic].sql
- SSRS reports:   [ProgramCode]_[ReportName].rdl

## SQL Style
See .claude/rules/sql-style.md — CTEs first, ALL CAPS keywords, aliased columns.

## Schema Reference
See .claude/rules/schema-notes.md for key tables and join patterns.
See docs/schema-overview.md for full schema map.

## HMIS Compliance
See .claude/rules/hmis-compliance.md for data element rules and program type logic.

## Active Reports
See docs/report-index.md for the current report inventory.

## Do Not
- Use SELECT * in any production query
- Hardcode ClientIDs, ProgramIDs, or EnrollmentIDs
- Return PHI/PII in ad hoc queries — use ClientID only
- Push directly to ssrs/published/ without review
- Modify existing views without documenting the change in docs/schema-overview.md
