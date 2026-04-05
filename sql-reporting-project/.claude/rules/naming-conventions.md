# Naming Conventions

## Views (CaseWorthy Custom)
- Prefix: x_uvw_
- Format: x_uvw_[DescriptiveName]
- PascalCase after prefix
- Examples:
    x_uvw_ActiveEnrollmentsByProgram
    x_uvw_SSVFServiceSummary
    x_uvw_GPDExitDestinations
    x_uvw_AssessmentSignOffStatus

## SQL Files

### Report Dataset Queries (queries/reports/)
Format: [ProgramCode]_[ReportName]_dataset.sql
Examples:
    SSVF_MonthlyServiceReport_dataset.sql
    GPD_ExitDestinations_dataset.sql
    PSH_ContactLog_dataset.sql
    SRVTRK_ParticipantSummary_dataset.sql

### Ad Hoc Queries (queries/ad-hoc/)
Format: [YYYY-MM-DD]_[brief-description].sql
Examples:
    2026-04-08_servtracker-enrollment-check.sql
    2026-04-10_ssvf-missing-exits.sql

### View Definitions (queries/views/)
Format: x_uvw_[Description].sql (matches the view name)
Examples:
    x_uvw_ActiveEnrollmentsByProgram.sql
    x_uvw_SSVFServiceSummary.sql

## SSRS Files (ssrs/)

### Report Files
Format: [ProgramCode]_[ReportName].rdl
Examples:
    SSVF_MonthlyServiceReport.rdl
    GPD_ExitDestinations.rdl

### Spec Documents (docs/report-specs/)
Format: [ProgramCode]_[ReportName]_spec.md

## Program Codes
Use these consistently across file names, comments, and filter values:

| Code      | Program / Grant Type         | System        |
|-----------|------------------------------|---------------|
| SSVF      | Supportive Services for Vets | CaseWorthy    |
| GPD       | Grant Per Diem               | CaseWorthy    |
| HUDVASH   | HUD-VASH                     | CaseWorthy    |
| PSH       | Permanent Supportive Housing | CaseWorthy    |
| RRH       | Rapid Rehousing              | CaseWorthy    |
| SOAR      | SSI/SSDI Outreach            | CaseWorthy    |
| HN        | Housing Navigation           | CaseWorthy    |
| HCN       | Healthcare Navigation        | CaseWorthy    |
| ESG       | Emergency Solutions Grant    | CaseWorthy    |
| SRVTRK    | ServTracker (aging services) | ServTracker   |

## Database Object Naming
- Custom views: x_uvw_ prefix (CaseWorthy convention)
- Stored procedures (if created): x_usp_[Description]
- Never modify or rename base CaseWorthy/ServTracker tables or views
  — only create objects with the x_ prefix

## Parameter Naming in SSRS / SQL
- Date ranges: @StartDate, @EndDate
- Program filter: @ProgramID (integer ID, not name string)
- Office filter: @OfficeID or @OfficeName depending on the report
- Staff filter: @StaffID
- All parameters PascalCase with @ prefix
