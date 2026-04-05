# Report Types — CaseWorthy SSRS at SVDP CARES

---

## Operational Reports

**Definition**: Reports used day-to-day by supervisors and managers to monitor active caseloads, program rosters, staff assignments, and client status. Data is current as of the run date.

### Prototype: Caseload Report

The Caseload Report is the canonical operational report at SVDP CARES. Use it as the model for any new operational report.

**Purpose**: Show every active enrollment member across all programs, grouped by office and program, with key status fields visible at a glance.

**Population**: Active enrollment members (`EnrollmentMember.EndDate = '9999-12-31'`), filtered by date range, office, program, org, and optionally HoH only.

**Core join pattern**:
```sql
FROM EnrollmentMember em
INNER JOIN Enrollment e   ON em.EnrollmentID  = e.EnrollmentID  AND e.DeletedDate  IS NULL
INNER JOIN Program p      ON e.ProgramID      = p.ProgramID     AND p.DeletedDate  IS NULL
INNER JOIN Client c       ON em.ClientID      = c.EntityID      AND c.DeletedDate  IS NULL
LEFT  JOIN EnrollmentHMIS eh ON em.EnrollmentID = eh.EnrollmentID AND eh.DeletedDate IS NULL
```

**Standard operational columns**:

| Column | Source | Notes |
|---|---|---|
| Client ID | `Client.EntityID` | |
| First Name | `Client.FirstName` | |
| Last Name | `Client.LastName` | |
| Office Location | `Client.X_Office → ListItem` | CategoryID 1000000403 |
| Program Name | `Program.ProgramName` | |
| Begin Date | `EnrollmentMember.BeginDate` | |
| Days Enrolled | `DATEDIFF(DAY, BeginDate, GETDATE())` | Calculated |
| # Enrolled Family Members | `COUNT(EnrollmentMember)` per EnrollmentID | Calculated |
| Assigned Staff | `x_uvw_LatestUserByJobType` | Confirm job type IDs |
| Move-In Date | `EnrollmentHMIS.MoveInDate` | NULL = not housed |
| Housed / Not Housed | Derived from Move-In Date | Calculated |
| Last Recert Date | `X_UVW_Latest90DayRecertWEnroll.AssessmentDate` | |
| Days Since Last Recert | `X_UVW_Latest90DayRecertWEnroll.DaysSinceLastRecert` | Running counter |
| Recert Status | Derived from DaysSinceLastRecert | For conditional formatting |
| Connection with SOAR | `AssessHUDProgram.ConnectionWithSOAR → ListItem` | CategoryID 37; entry assessment only |
| Current Receive Shallow Sub | `Client.X_ShallowSubsidyStatus → ListItem` | |
| Referred from HUD-VASH | `Client.X_ReferredFromHUDVASH → ListItem` | |
| Received Legal Assistance | `XLegalServiceReferral` where `X_ReferralStatus = 4` | Approved only |
| Days With No Service/Contact | `DATEDIFF(DAY, Client.LastModifiedDate, GETDATE())` | Proxy for last activity |

**Standard operational grouping**:
- Outer group: Office Location (page break between offices)
- Inner group: Program Name
- Sort: Last Name ASC → First Name ASC within program

**Standard conditional formatting**:
- Days Since Last Recert ≥ 90 → Red (#FFCCCC), bold, dark red text
- Days Since Last Recert 70–89 → Yellow (#FFF2CC), bold, dark yellow text
- Days Since Last Recert < 70 → Light green (#D6F0D6) or transparent
- Days Since Last Recert NULL → Light gray (#E0E0E0), italic

### Adapting for Other Operational Reports

When building a new operational report (not caseload), use this checklist:
- [ ] Does it need family member counts? → Add the COUNT subquery
- [ ] Does it need housing status? → Add EnrollmentHMIS join
- [ ] Does it need recert tracking? → Add X_UVW_Latest90DayRecertWEnroll join
- [ ] Does it need staff assignment? → Add x_uvw_LatestUserByJobType join + confirm job type IDs
- [ ] Does it need SOAR/subsidy/VASH fields? → Add ListItem decodes + confirm ListItemCategoryIDs
- [ ] Does it need legal assistance? → Add XLegalServiceReferral join, filter X_ReferralStatus = 4

---

## DQ / Compliance Reports

**Definition**: Reports used to identify data quality issues, missing data, and compliance gaps in CaseWorthy entries. Typically run by data managers, program coordinators, and compliance staff before funder reporting deadlines.

**Status**: The SSVF DQ Report was scoped and deferred during the Caseload Report build. It is the primary DQ report target for Phase 2.

### SSVF DQ Report (Phase 2 — Deferred)

**Purpose**: Surface data quality errors in SSVF program entries against HUD/VA data standards. 53 main checks + 4 TFA checks = 57 total checks.

**Check categories**:
1. Client Demographics (missing DOB, SSN, race, gender, veteran status, etc.)
2. Entry Assessment (missing or invalid HUD entry fields)
3. Exit Assessment (missing or invalid HUD exit fields)
4. Veteran-Specific Fields (SSVF-specific veteran data)
5. Household Integrity (HOH relationship, member count consistency)
6. Date Logic (entry after exit, overlapping enrollments, impossible dates)
7. Data Integrity (duplicate records, orphaned assessments)
8. TFA Checks — HP/RRH Low/High financial assistance flags (requires financial assistance table investigation — Phase 2)

**Known complexity**: TFA checks require mapping to the financial assistance tables which had not been fully investigated at time of deferral. Do not attempt TFA checks without first researching the financial assistance table schema.

**Recommended DQ report structure**:
- Each row = one client + one failed check
- Columns: Client ID, Name, Program, Enrollment Begin Date, Check Category, Check Name, Field in Error, Current Value, Expected Value/Rule
- Parameters: @StartDate, @EndDate, @ProgramID, @OrganizationID, plus @CheckCategory multi-select to filter by category
- Grouping: by Check Category → Check Name, so data managers can work through one issue type at a time
- No conditional formatting needed — every row in the report is by definition an error

**SQL pattern for DQ checks**:
```sql
-- Each check is a separate UNION ALL block
-- Label each with a category and check name for grouping
SELECT
    c.EntityID          AS [Client ID],
    c.FirstName         AS [First Name],
    c.LastName          AS [Last Name],
    p.ProgramName       AS [Program],
    em.BeginDate        AS [Enrollment Begin],
    'Demographics'      AS [Check Category],
    'Missing Date of Birth' AS [Check Name],
    'DateOfBirth'       AS [Field in Error],
    CAST(c.DateOfBirth AS nvarchar) AS [Current Value],
    'Required — cannot be null or default' AS [Rule]
FROM EnrollmentMember em
INNER JOIN Enrollment e  ON em.EnrollmentID = e.EnrollmentID AND e.DeletedDate IS NULL
INNER JOIN Program p     ON e.ProgramID     = p.ProgramID    AND p.DeletedDate IS NULL
INNER JOIN Client c      ON em.ClientID     = c.EntityID     AND c.DeletedDate IS NULL
WHERE em.EndDate    = '9999-12-31'
  AND em.DeletedDate IS NULL
  AND c.DateOfBirth IS NULL   -- ← the actual DQ condition

UNION ALL

-- next check...
```

**Before building the SSVF DQ report**:
- [ ] Confirm which SSVF ProgramIDs are in scope
- [ ] Get the full list of 53 required checks from the SSVF Data Quality Framework document
- [ ] Research financial assistance table schema before attempting TFA checks
- [ ] Confirm with user which check categories to include in Phase 1 vs later phases

### General DQ Report Guidelines

- Run DQ reports against a defined program type + date window — never open-ended
- Always include a row count per check category in the report header or group footer
- DQ reports do not need RDL conditional formatting — the presence of a row is the alert
- DQ reports benefit from a "severity" column (Error vs Warning) when checks have different urgency
- Consider a summary dataset (dsCheckSummary) alongside the detail dataset (dsDQDetail) so the report can show a count-by-category summary at the top before the full detail table
