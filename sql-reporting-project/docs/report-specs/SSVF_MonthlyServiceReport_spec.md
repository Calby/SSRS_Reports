# Report Spec: SSVF Monthly Service Report

## Overview
- **Program:** SSVF (Supportive Services for Veterans Families)
- **Audience:** SSVF Program Manager, SVDP Data Team
- **Purpose:** Monthly summary of SSVF client enrollment activity and financial
  assistance delivered within a selected date range. Used for internal monitoring
  and VA funder reporting support.
- **Frequency:** Monthly (on-demand with date range parameter)
- **Requested By:** [Name]
- **Target Completion:** [Date]
- **Dataset Query:** queries/reports/SSVF_MonthlyServiceReport_dataset.sql
- **SSRS File:** ssrs/published/SSVF_MonthlyServiceReport.rdl

---

## Filters / Parameters

| Parameter   | Type    | Required | Default          | Notes                        |
|-------------|---------|----------|------------------|------------------------------|
| @StartDate  | Date    | Yes      | First of month   | Enrollment overlap start     |
| @EndDate    | Date    | Yes      | Last of month    | Enrollment overlap end       |
| @OfficeID   | Integer | No       | 0 (All offices)  | 0 = all; dropdown from Site  |

---

## Output

**Grain:** One row per client per SSVF enrollment

**Columns:**

| Column Name             | Source                        | Notes                                         |
|-------------------------|-------------------------------|-----------------------------------------------|
| ClientID                | Enrollment.ClientID           | Internal — used for sort; not labeled for end users |
| EnrollmentDate          | Enrollment.EnrollmentDate     |                                               |
| ExitDate                | EnrollmentExit.ExitDate       | Blank if still active                         |
| EnrollmentStatus        | Calculated                    | "Active" or "Exited"                          |
| DaysEnrolledInPeriod    | Calculated                    | Days within the selected date range           |
| VeteranStatus           | ClientDemographic             | Must be Veteran for SSVF eligibility          |
| Gender                  | ClientDemographic             |                                               |
| DisablingCondition      | ClientDemographic             |                                               |
| ServiceCount            | Services (count)              | Number of service transactions in period      |
| TotalDollarAmount       | Services (sum)                | Financial assistance total in period          |
| FirstServiceDate        | Services                      |                                               |
| MostRecentServiceDate   | Services                      |                                               |
| ExitDestination         | EnrollmentExit                | HUD coded value                               |
| ExitOutcomeCategory     | Calculated                    | Permanent / Non-Permanent / Still Enrolled    |
| SiteID                  | Enrollment.SiteID             | Used for grouping by office                   |

**Grouping / Subtotals:**
- Group by SiteID / SiteName
- Subtotal per office: client count, total services, total dollar amount
- Grand total row at the bottom

**Sort Order:**
- Primary: SiteName ascending
- Secondary: ClientID ascending within each site

---

## Charts
None in initial version. Potential future addition: bar chart of clients served per office.

---

## Data Quality Notes
- Clients with VeteranStatus = NULL or "Data not collected" should be flagged
- Enrollments with ExitDate before EnrollmentDate are data errors — exclude and flag
- Dollar amounts of $0 are valid (some services have no financial component)

---

## HMIS / Funder Compliance
- SSVF is VA-funded — follow VA SSVF Program Guide definitions for housing outcomes
- ExitOutcomeCategory calculation should align with VA's definition of "housing stability"
- Confirm ExitDestination code list against current CaseWorthy ListItem values

---

## Related Reports / Views
- Views: x_uvw_ActiveEnrollmentsByProgram (base enrollment data)
- Related: GPD_ExitDestinations (similar exit outcome logic for GPD program)

---

## Sign-Off Checklist
- [ ] Dataset query reviewed with /project:review-query
- [ ] Tested in SSMS with real data
- [ ] SSRS layout reviewed and parameters tested
- [ ] Reviewed with SSVF program manager
- [ ] ExitDestination codes verified against CaseWorthy ListItems
- [ ] Deployed to report server
- [ ] docs/report-index.md updated
