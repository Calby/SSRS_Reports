---
name: ssrs-caseworthy
description: >
  Build SQL Server Reporting Services (SSRS) reports for the CaseWorthy homeless
  services case management system at St. Vincent de Paul CARES. Use this skill
  whenever the user asks to build, plan, design, or hand off any CaseWorthy report —
  including caseload reports, program reports, operational dashboards, SSVF data
  quality reports, or any other SSRS-based report against the CaseWorthy database.
  Also triggers on phrases like "new report", "SSRS dataset", "SQL for the report",
  "hand off to Gibson", "hand off to Eccovia", or "hand off to the reports team".
  Always use this skill for any CaseWorthy reporting task — do not attempt to build
  these reports without it.
---

# CaseWorthy SSRS Report Builder — SVDP CARES

This skill guides the full end-to-end workflow for building a CaseWorthy SSRS report:
intake → schema research → SQL datasets → RDL skeleton → visual mockup → handoff doc → handoff email.

---

## Step 0 — Read First

Before writing a single line of SQL, read the relevant reference files:

- **Always read**: `references/caseworthy-conventions.md` — DB conventions, active record filters, ListItem decodes, view patterns, table index
- **For operational reports** (caseload, program, staff): `references/report-types.md` → Operational section
- **For DQ/compliance reports** (SSVF DQ, HUD APR, data audits): `references/report-types.md` → DQ/Compliance section

---

## Step 1 — Intake Checklist

Run through every item below before touching the schema. Missing any of these will cause rework.

### 1A — Report Identity
- [ ] Report name and plain-English purpose (one sentence)
- [ ] Who uses it? (supervisors, managers, data team, funders)
- [ ] Is this operational (live caseload) or DQ/compliance (audit, data quality)?

### 1B — Population Scope
- [ ] Active enrollments only, or include exited clients?
- [ ] Date window: enrollment begin date, service date, exit date, or report run date?
- [ ] Head of Household only, or all household members?
- [ ] Specific programs or all programs? If specific, get Program IDs.

### 1C — Parameters
Use the standard 5-parameter set as a baseline. Confirm which apply and whether any custom parameters are needed.

| Parameter | Type | Notes |
|---|---|---|
| @StartDate | date | Enrollment/service begin range start. Default: first of current month |
| @EndDate | date | Enrollment/service begin range end. Default: today |
| @OrganizationID | int multi-select | All/None/Some. Default: -1 (all) |
| @ProgramID | int multi-select | All/None/Some. Default: -1 (all) |
| @OfficeLocation | int multi-select | Dropdown from dsOfficeList (ListItemCategoryID = 1000000403). Default: -1 (all) |

Common custom additions:
- `@HoHOnly` bit checkbox — 1=HoH only, 0=all members
- `@ExitedOnly` bit — for historical/exit reports
- `@StaffID` int — filter by assigned case manager

### 1D — Field List
For every column in the report, confirm:
- Source table/view and field name
- Whether it needs a ListItem decode (get the ListItemCategoryID or list name)
- Whether it's calculated (confirm the formula)
- Whether it's from a custom view (get the view name and confirm join keys)

### 1E — Report Structure
- Flat table, or grouped by office/program/staff?
- Summary rows needed (counts, averages)?
- Page breaks between groups?
- Sort order?
- Conditional formatting? (confirm thresholds and colors)

### 1F — Confirm Before Writing SQL
Do not begin SQL until these are confirmed:
- [ ] Active record convention: `DeletedDate IS NULL` or `EndDate = '9999-12-31'`
- [ ] Any ListItem decodes — confirm ListItemCategoryID for each
- [ ] Any custom view joins — confirm join keys (usually ClientID + EnrollmentID)
- [ ] Referral/status field values — confirm integer values for each status label

---

## Step 2 — Schema Research

Reference `references/caseworthy-conventions.md` for the table index, naming conventions, and view patterns. Key lookup targets:
- ListItemCategoryID values: query `SELECT * FROM ListItemCategory WHERE CategoryName LIKE '%keyword%'`
- Custom view columns: query `SELECT TOP 1 * FROM x_uvw_ViewName`
- Program IDs: query `SELECT ProgramID, ProgramName FROM Program WHERE DeletedDate IS NULL`

Document every confirmed value with a date stamp. These become the `[x] confirmed` comments in the SQL file header.

---

## Step 3 — SQL Datasets

### File naming
`{ReportName}_Dataset_v1.sql`

### File structure
Every SQL file must contain:

```
-- ============================================================
-- REPORT: {Report Name}
-- PURPOSE: {one sentence}
-- GENERATED: {date}
-- ============================================================
-- PARAMETERS
--   @Param   type   description
-- ============================================================
-- CONFIRMED ITEMS
--   [x] item = value (confirmed YYYY-MM-DD)
-- !! ALL ITEMS CONFIRMED — READY FOR DEPLOYMENT !!
-- ============================================================

-- DATASET 1: ds{ReportName}
SELECT ...

-- ============================================================
-- DATASET 2: dsOfficeList (parameter dropdown — include in every report)
-- ============================================================
SELECT ListItemID AS [Value], ListItemText AS [Label]
FROM ListItem
WHERE ListItemCategoryID = 1000000403
  AND DeletedDate IS NULL
ORDER BY SortOrder ASC;
```

### Standard SQL patterns

**Active enrollment filter:**
```sql
WHERE em.EndDate = '9999-12-31'   -- active members only (not NULL)
  AND em.DeletedDate IS NULL
```

**ListItem decode:**
```sql
LEFT JOIN ListItem li
    ON  field = li.ListItemID
    AND li.ListItemCategoryID = {confirmed ID}
```

**Days counter (never resets — confirm behavior with user):**
```sql
recert.DaysSinceLastRecert   AS [Days Since Last Recert]
-- Running integer from 0. Increments daily. Never resets until next completed event.
-- NULL only if no row exists in view (client has never had the event recorded).
```

**Recert status flag for conditional formatting:**
```sql
CASE
    WHEN recert.DaysSinceLastRecert IS NULL  THEN 'No Recert on File'
    WHEN recert.DaysSinceLastRecert >= 90    THEN 'Overdue'
    WHEN recert.DaysSinceLastRecert >= 70    THEN 'Due Soon'
    ELSE 'Current'
END  AS [Recert Status]
-- Thresholds: confirm 70/90 with user — these are SVDP defaults
```

**Assigned staff via job type view:**
```sql
LEFT JOIN (
    SELECT ujt.ClientID, ujt.EnrollmentID,
           e.EntityName AS CaseManager
    FROM x_uvw_LatestUserByJobType ujt
    INNER JOIN Entity e ON ujt.UserID = e.EntityID AND e.DeletedDate IS NULL
    WHERE ujt.ProgramJobTypeID IN ({confirmed IDs})
) lcm ON em.ClientID = lcm.ClientID AND em.EnrollmentID = lcm.EnrollmentID
```

**Case manager job type IDs (confirmed defaults):**

| ID | Title |
|---|---|
| 122 | Case Manager |
| 123 | SOAR-Case Manager IV |
| 205 | Aftercare Coordinator |
| 207 | SOAR Benefits Specialist |
| 213 | Case Manager IV |

Confirm with user whether additional types apply for the specific report.

---

## Step 4 — RDL Skeleton

Build a `.rdl` file (XML) with:
- Data source block (connection string placeholder for analyst to fill)
- Both datasets embedded with escaped SQL
- All parameters pre-configured with correct types, defaults, and multi-select flags
- `@OfficeLocation` parameter bound to `dsOfficeList` with Value=ListItemID, Label=ListItemText
- Tablix table with all columns mapped to dataset fields
- Row grouping by Office Location (with page break between) → Program Name
- Program group header showing program name + client count: `=Fields!Program_Name.Value & " (" & CountRows() & " clients)"`
- Column headers repeating on each page
- Conditional formatting expressions pre-wired on any flagged columns
- Report header showing title, run-by user, run date, and parameter display
- Page setup: Landscape, 14" × 8.5", 0.25" margins

**Conditional formatting expression pattern (Recert example):**
```vb
=IIF(Fields!Recert_Status.Value="Overdue","#FFCCCC",
 IIF(Fields!Recert_Status.Value="Due Soon","#FFF2CC",
 IIF(Fields!Recert_Status.Value="No Recert on File","#E0E0E0",
 "Transparent")))
```

> **Note on RDL delivery**: Before sending, confirm with Gibson/Eccovia whether the reports team works directly with RDL files in Report Builder, or whether Eccovia manages SSRS deployment through a different backend process. If the latter, the SQL + handoff doc may be sufficient and the RDL may cause confusion.

---

## Step 5 — Visual HTML Mockup

Build a standalone `.html` file the designer can open in any browser. Must include:
- Mockup notice banner (fictional data, layout reference only)
- Report header (title, subtitle, run-by, run date, date range)
- Parameter bar showing selected filters
- Legend for any conditional formatting colors
- At least 2 office groups, each with at least 2 program sub-groups
- At least 3–4 sample data rows per program (use realistic but fictional names/values)
- Color-coded cells matching the confirmed conditional formatting thresholds
- Badges for Yes/No/Housed/Unhoused/Received fields
- Footer with org name, report name, page number placeholder, confidentiality note
- Page orientation note (landscape)

---

## Step 6 — Handoff Document

Build a `.docx` using the docx skill. Read `/mnt/skills/public/docx/SKILL.md` first.

Required sections:
1. **Purpose** — What the report is and why it replaces the manual process
2. **What the Report Shows** — Bullet list of what supervisors will see
3. **Datasets** — One paragraph per dataset explaining source tables and join logic
4. **Report Parameters** — Table: Parameter / Type / Required / Notes
5. **Column Reference** — Table: Column Name / Source / Type / Notes
6. **Conditional Formatting Instructions** — Table of conditions + Report Builder expression
7. **Sorting and Grouping** — How rows are organized and what group headers show
8. **Key Business Logic Notes** — One subsection per non-obvious business rule
9. **Remaining Open Items** — Any unresolved items for the analyst to verify during testing

Tone: brief, plain English, no jargon. Written for an analyst who knows Report Builder but does not know SVDP's data model.

---

## Step 7 — Handoff Email

Draft an email to Gibson (CaseWorthy Support contact) that:
- Lists all attached files by name with a one-line description of each
- Asks the reports team to review before implementing
- Invites questions and offers to clarify anything
- Includes the RDL delivery question if it hasn't been answered yet (see Step 4 note)
- Keeps it brief — Gibson forwards this, so it needs to be readable at a glance

---

## Deliverables Checklist

| File | Name Pattern | Required |
|---|---|---|
| SQL datasets | `{ReportName}_Dataset_v1.sql` | Always |
| RDL skeleton | `{ReportName}.rdl` | Yes (pending RDL confirmation) |
| Visual mockup | `{ReportName}_Mockup.html` | Always |
| Handoff document | `{ReportName}_Handoff.docx` | Always |
| Handoff email | Composed in chat | Always |

---

## Report Type Reference

See `references/report-types.md` for:
- **Operational reports** — Caseload, program roster, staff assignment reports
- **DQ/Compliance reports** — SSVF DQ checks, HUD APR, data audit reports
