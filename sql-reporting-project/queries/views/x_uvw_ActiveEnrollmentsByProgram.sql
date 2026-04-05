-- ============================================================
-- View:    x_uvw_ActiveEnrollmentsByProgram
-- Purpose: Base view exposing all enrollments (active and exited)
--          with program, client, and site detail pre-joined.
--          Intended as the primary base for report dataset queries
--          instead of re-joining the same core tables in every report.
-- Grain:   One row per client per enrollment
-- Used By: Multiple — see docs/report-index.md
-- Created: [YYYY-MM-DD]
-- Author:  [Name]
-- Changes:
--   [YYYY-MM-DD] - Initial creation
-- ============================================================

CREATE OR ALTER VIEW x_uvw_ActiveEnrollmentsByProgram
AS

WITH

EnrollmentBase AS (
    -- All enrollments with their program and exit status
    SELECT
        e.EnrollmentID,
        e.ClientID,
        e.ProgramID,
        e.EnrollmentDate,
        e.ExitDate,
        e.SiteID,
        CASE
            WHEN e.ExitDate IS NULL THEN 1
            ELSE 0
        END                             AS IsActive
    FROM Enrollment e
),

ProgramDetail AS (
    -- Program lookup with type classification
    SELECT
        p.ProgramID,
        p.ProgramName,
        p.ProgramType,
        p.SiteID                        AS ProgramSiteID
    FROM Program p
),

SiteDetail AS (
    SELECT
        s.SiteID,
        s.SiteName
    FROM Site s
),

ExitDetail AS (
    SELECT
        ex.EnrollmentID,
        ex.ExitDate                     AS ExitRecordDate,
        ex.ExitDestination,
        ex.ExitReason
    FROM EnrollmentExit ex
)

SELECT
    -- Enrollment
    eb.EnrollmentID,
    eb.ClientID,
    eb.EnrollmentDate,
    eb.ExitDate,
    eb.IsActive,

    -- Program
    pd.ProgramID,
    pd.ProgramName,
    pd.ProgramType,

    -- Site
    eb.SiteID,
    sd.SiteName,

    -- Exit
    exd.ExitDestination,
    exd.ExitReason

FROM EnrollmentBase eb
INNER JOIN ProgramDetail pd  ON eb.ProgramID    = pd.ProgramID
INNER JOIN SiteDetail    sd  ON eb.SiteID       = sd.SiteID
LEFT JOIN  ExitDetail    exd ON eb.EnrollmentID = exd.EnrollmentID

GO
