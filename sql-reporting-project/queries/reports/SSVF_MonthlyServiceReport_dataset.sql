-- ============================================================
-- Query:   SSVF_MonthlyServiceReport_dataset
-- Purpose: Returns client-level service activity for SSVF grant
--          reporting. One row per client per enrollment. Used as
--          the primary dataset in SSVF_MonthlyServiceReport.rdl.
-- Grain:   One row per client per SSVF enrollment
-- Params:  @StartDate, @EndDate, @OfficeID (0 = All offices)
-- Report:  SSVF_MonthlyServiceReport.rdl
-- Created: [YYYY-MM-DD]
-- Author:  [Name]
-- Changes:
--   [YYYY-MM-DD] - [What changed and why]
-- ============================================================

-- ── For local testing in SSMS only — remove before pasting into SSRS ──
DECLARE @StartDate DATE = '2026-01-01'
DECLARE @EndDate   DATE = '2026-03-31'
DECLARE @OfficeID  INT  = 0            -- 0 = all offices
-- ─────────────────────────────────────────────────────────────────────

WITH

SSVFEnrollments AS (
    -- Active and exited SSVF enrollments that overlap the report date range
    SELECT
        e.EnrollmentID,
        e.ClientID,
        e.ProgramID,
        e.EnrollmentDate,
        e.ExitDate,
        e.SiteID
    FROM Enrollment e
    INNER JOIN Program p ON e.ProgramID = p.ProgramID
    WHERE p.ProgramType = 'SSVF'                            -- SSVF program type only
      AND e.EnrollmentDate <= @EndDate                      -- enrolled before or during range
      AND (e.ExitDate IS NULL OR e.ExitDate >= @StartDate)  -- still active or exited within range
      AND (@OfficeID = 0 OR e.SiteID = @OfficeID)           -- office filter (0 = all)
),

ClientDemographics AS (
    -- Pull veteran status and basic demographics for each enrolled client
    SELECT
        cd.ClientID,
        cd.VeteranStatus,
        cd.Gender,
        cd.Race,
        cd.Ethnicity,
        cd.DisablingCondition,
        DATEDIFF(YEAR, cd.DateOfBirth, @EndDate) AS AgeAtEndOfPeriod
    FROM ClientDemographic cd
    INNER JOIN SSVFEnrollments se ON cd.ClientID = se.ClientID
),

ServiceActivity AS (
    -- Financial assistance and services delivered within the date range
    SELECT
        s.ClientID,
        s.EnrollmentID,
        COUNT(DISTINCT s.ServiceID)     AS ServiceCount,
        SUM(COALESCE(s.Amount, 0))      AS TotalDollarAmount,
        MIN(s.ServiceDate)              AS FirstServiceDate,
        MAX(s.ServiceDate)              AS MostRecentServiceDate
    FROM Services s
    INNER JOIN SSVFEnrollments se ON s.EnrollmentID = se.EnrollmentID
    WHERE s.ServiceDate BETWEEN @StartDate AND @EndDate
    GROUP BY
        s.ClientID,
        s.EnrollmentID
),

ExitInfo AS (
    -- Exit destination for clients who exited within or before the date range
    SELECT
        ex.EnrollmentID,
        ex.ExitDate,
        ex.ExitDestination
    FROM EnrollmentExit ex
    INNER JOIN SSVFEnrollments se ON ex.EnrollmentID = se.EnrollmentID
)

SELECT
    -- Identifiers (do not expose ClientID in user-facing report — use as sort key only)
    se.ClientID,
    se.EnrollmentID,

    -- Enrollment dates
    se.EnrollmentDate,
    ei.ExitDate,
    CASE
        WHEN ei.ExitDate IS NULL THEN 'Active'
        ELSE 'Exited'
    END                                                     AS EnrollmentStatus,

    -- Days enrolled within the report period
    DATEDIFF(
        DAY,
        CASE WHEN se.EnrollmentDate < @StartDate THEN @StartDate ELSE se.EnrollmentDate END,
        CASE WHEN COALESCE(ei.ExitDate, @EndDate) > @EndDate THEN @EndDate ELSE COALESCE(ei.ExitDate, @EndDate) END
    )                                                       AS DaysEnrolledInPeriod,

    -- Veteran and demographics
    cd.VeteranStatus,
    cd.Gender,
    cd.Race,
    cd.Ethnicity,
    cd.DisablingCondition,
    cd.AgeAtEndOfPeriod,

    -- Service activity
    COALESCE(sa.ServiceCount, 0)                            AS ServiceCount,
    COALESCE(sa.TotalDollarAmount, 0)                       AS TotalDollarAmount,
    sa.FirstServiceDate,
    sa.MostRecentServiceDate,

    -- Exit outcome
    ei.ExitDestination,
    CASE
        WHEN ei.ExitDestination IN (
            -- Permanent housing destination codes — verify against your HUD codeset
            'Owned by client (no subsidy)',
            'Rental by client (no subsidy)',
            'Permanent housing for formerly homeless persons',
            'Staying or living with family (permanent tenure)',
            'Staying or living with friends (permanent tenure)'
        ) THEN 'Permanent'
        WHEN ei.ExitDate IS NULL THEN 'Still Enrolled'
        ELSE 'Non-Permanent / Unknown'
    END                                                     AS ExitOutcomeCategory,

    -- Office
    se.SiteID

FROM SSVFEnrollments se
LEFT JOIN ClientDemographics   cd ON se.ClientID     = cd.ClientID
LEFT JOIN ServiceActivity      sa ON se.EnrollmentID = sa.EnrollmentID
LEFT JOIN ExitInfo             ei ON se.EnrollmentID = ei.EnrollmentID

ORDER BY
    se.SiteID,
    se.ClientID;

-- TODO: Validate ExitDestination string values against your CaseWorthy ListItem codes
-- TODO: Confirm VeteranStatus field name and values in ClientDemographic
-- TODO: Confirm ProgramType value for SSVF in your environment (may be ID, not string)
