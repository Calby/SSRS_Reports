-- ============================================================
-- View:    x_uvw_AssessmentSignOffStatus
-- Purpose: Exposes assessment sign-off status per assessment,
--          including how many days since the assessment was
--          completed and whether it is overdue for sign-off.
--          Backs the Assessment Sign-Off Backlog report.
-- Grain:   One row per assessment
-- Used By: ALL_AssessmentSignOffBacklog.rdl
-- Created: [YYYY-MM-DD]
-- Author:  [Name]
-- Changes:
--   [YYYY-MM-DD] - Initial creation
-- ============================================================

CREATE OR ALTER VIEW x_uvw_AssessmentSignOffStatus
AS

WITH

AssessmentBase AS (
    SELECT
        a.AssessmentID,
        a.ClientID,
        a.EnrollmentID,
        a.AssessmentType,              -- Entry, Annual, Exit, Update
        a.AssessmentDate,
        a.CompletedByUserID
    FROM Assessment a
),

SignOffStatus AS (
    -- Most recent sign-off record per assessment
    SELECT
        aso.AssessmentID,
        aso.SignOffStatus,
        aso.SignOffDate,
        aso.SignedOffByUserID
    FROM AssessmentSignOff aso
),

CompletedBy AS (
    SELECT
        u.UserID,
        u.FirstName + ' ' + u.LastName  AS CompletedByName,
        u.SiteID
    FROM AppUser u
),

SignedOffBy AS (
    SELECT
        u.UserID,
        u.FirstName + ' ' + u.LastName  AS SignedOffByName
    FROM AppUser u
),

EnrollmentContext AS (
    SELECT
        e.EnrollmentID,
        e.ProgramID,
        e.SiteID
    FROM Enrollment e
),

SiteContext AS (
    SELECT
        s.SiteID,
        s.SiteName
    FROM Site s
)

SELECT
    -- Assessment identity
    ab.AssessmentID,
    ab.ClientID,
    ab.EnrollmentID,
    ab.AssessmentType,
    ab.AssessmentDate,

    -- Who completed it
    ab.CompletedByUserID,
    cb.CompletedByName,

    -- Sign-off status
    COALESCE(sos.SignOffStatus, 'Pending')          AS SignOffStatus,
    sos.SignOffDate,
    sos.SignedOffByUserID,
    sob.SignedOffByName,

    -- Calculated fields
    DATEDIFF(DAY, ab.AssessmentDate, GETDATE())     AS DaysSinceAssessment,
    CASE
        WHEN sos.SignOffStatus = 'Approved'          THEN 0
        WHEN DATEDIFF(DAY, ab.AssessmentDate, GETDATE()) > 30 THEN 1
        ELSE 0
    END                                             AS IsOverdue,           -- 30-day threshold

    -- Location context
    ec.ProgramID,
    ec.SiteID,
    sc.SiteName

FROM AssessmentBase ab
LEFT JOIN SignOffStatus      sos ON ab.AssessmentID      = sos.AssessmentID
LEFT JOIN CompletedBy        cb  ON ab.CompletedByUserID = cb.UserID
LEFT JOIN SignedOffBy        sob ON sos.SignedOffByUserID = sob.UserID
LEFT JOIN EnrollmentContext  ec  ON ab.EnrollmentID      = ec.EnrollmentID
LEFT JOIN SiteContext        sc  ON ec.SiteID            = sc.SiteID

GO
