# SSRS Report Development Guide

Reference guide for building, deploying, and maintaining SSRS reports against
the CaseWorthy and ServTracker databases.

---

## Report Spec Template

Use this template when running /project:new-report. Save as:
docs/report-specs/[ProgramCode]_[ReportName]_spec.md

```markdown
# Report Spec: [Report Name]

## Overview
- **Program:** [SSVF / GPD / PSH / etc.]
- **Audience:** [Program Manager / Director / Funder / Data Team]
- **Purpose:** [What question does this answer?]
- **Frequency:** [Monthly / Quarterly / On-demand]
- **Requested By:** [Name]
- **Target Completion:** [Date]

## Filters / Parameters
| Parameter   | Type    | Required | Default        | Notes                  |
|-------------|---------|----------|----------------|------------------------|
| @StartDate  | Date    | Yes      | First of month |                        |
| @EndDate    | Date    | Yes      | Today          |                        |
| @ProgramID  | Integer | Yes      | —              | Dropdown from Program  |
| @OfficeID   | Integer | No       | All            | Optional office filter |

## Output

**Grain:** One row per [client / enrollment / service / month / office]

**Columns:**
| Column Name    | Source Table/Field        | Description / Business Rule         |
|----------------|---------------------------|--------------------------------------|
| ClientID       | Client.ClientID           | Internal ID — do not expose to users |
| EnrollmentDate | Enrollment.EnrollmentDate |                                      |
| ExitDate       | Enrollment.ExitDate       | NULL if still active                 |
| [Add columns]  |                           |                                      |

**Totals / Subtotals:**
- [Group by what?]
- [Row counts, sums, averages needed?]

**Sort Order:**
- [Primary sort, secondary sort]

## Charts (if any)
- [Chart type, X/Y axis, what it shows]

## Data Quality Notes
- [Known gaps or caveats in the source data]
- [Any fields that are commonly "Data not collected" or NULL]

## HMIS / Funder Compliance
- [Which HMIS elements are represented?]
- [Any funder-specific metric definitions that differ from HMIS standard?]

## Related Reports / Views
- [Reports that cover similar data]
- [Custom views this should use as a base]

## Sign-Off
- [ ] Dataset query reviewed
- [ ] SSRS layout reviewed  
- [ ] Tested with real data
- [ ] Reviewed with program manager
- [ ] Deployed to report server
```

---

## SSRS Development Workflow

### 1. Build the dataset query first
- Write and test in SSMS before touching SSRS
- Use parameters with DECLARE for local testing:
  ```sql
  DECLARE @StartDate DATE = '2026-01-01'
  DECLARE @EndDate   DATE = '2026-03-31'
  DECLARE @ProgramID INT  = 12
  ```
- Remove DECLARE statements before pasting into SSRS dataset

### 2. Create the SSRS report
- Start from a blank report or a similar existing report as template
- Connect to the correct data source
- Paste the tested dataset query into the dataset definition
- Map SSRS parameters to the SQL @Parameter names exactly

### 3. Layout
- Use a tablix for tabular data
- Group rows by a meaningful category (office, program, month) before row-level detail
- Add subtotals at each group level
- Page header: Report title, date range, program
- Page footer: Page X of Y, run date/time
- Keep fonts consistent: typically Segoe UI or Arial, 8-9pt body, 10pt headers

### 4. Testing
- Test with a narrow date range first to confirm the query runs
- Test with each parameter combination that matters
- Check that NULL values display correctly (COALESCE in SQL, or handle in SSRS expression)
- Check pagination — reports over ~500 rows should be tested for performance

### 5. Deployment
- Save .rdl file to ssrs/published/
- Deploy to report server
- Update docs/report-index.md with status = Active and last updated date
- Notify program manager / requester

---

## Common SSRS Expressions

**Format a date:**
```
=Format(Fields!EnrollmentDate.Value, "MM/dd/yyyy")
```

**Handle NULL date (show "Active" if no exit):**
```
=IIF(IsNothing(Fields!ExitDate.Value), "Active", Format(Fields!ExitDate.Value, "MM/dd/yyyy"))
```

**Row count in a group:**
```
=CountDistinct(Fields!ClientID.Value)
```

**Conditional color (flag overdue items):**
```
=IIF(Fields!DaysSinceContact.Value > 30, "Red", "Black")
```

**Subtotal that excludes NULL:**
```
=Sum(IIF(IsNothing(Fields!Amount.Value), 0, Fields!Amount.Value))
```

---

## Report Server Deployment Checklist
- [ ] .rdl file tested in SSRS local preview
- [ ] Parameters tested with all combinations
- [ ] No PHI exposed in default view
- [ ] Report title and run-date header present
- [ ] Deployed to correct folder on report server
- [ ] Permissions set (who can see this report?)
- [ ] docs/report-index.md updated
- [ ] Program manager notified
