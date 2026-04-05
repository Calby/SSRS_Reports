# SQL Style Rules

## Keywords
- ALL CAPS for all SQL keywords: SELECT, FROM, WHERE, JOIN, LEFT JOIN, WITH, AS,
  GROUP BY, ORDER BY, HAVING, CASE, WHEN, THEN, ELSE, END, INSERT, UPDATE, etc.
- Lowercase for column names, table names, alias names, CTE names.

## CTE-First Pattern (Required for all multi-step queries)
Write logic as named CTEs before the final SELECT. Never nest subqueries more
than one level deep — if you need two levels, you need a CTE.

```sql
-- ============================================================
-- Query:   [Name]
-- Purpose: [What this returns and why]
-- Grain:   [One row per: ...]
-- Params:  @StartDate, @EndDate, @ProgramID (if applicable)
-- Created: [YYYY-MM-DD]
-- ============================================================

WITH

ActiveEnrollments AS (
    -- Clients with an open enrollment in the target program within date range
    SELECT
        e.ClientID,
        e.EnrollmentID,
        e.ProgramID,
        e.EnrollmentDate,
        e.ExitDate
    FROM Enrollment e
    WHERE e.ProgramID = @ProgramID
      AND e.EnrollmentDate <= @EndDate
      AND (e.ExitDate IS NULL OR e.ExitDate >= @StartDate)
),

ServiceActivity AS (
    -- Services delivered to those clients in the date range
    SELECT
        s.ClientID,
        s.EnrollmentID,
        COUNT(s.ServiceID)          AS ServiceCount,
        SUM(s.Amount)               AS TotalAmount,
        MAX(s.ServiceDate)          AS MostRecentService
    FROM Services s
    INNER JOIN ActiveEnrollments ae ON s.EnrollmentID = ae.EnrollmentID
    WHERE s.ServiceDate BETWEEN @StartDate AND @EndDate
    GROUP BY
        s.ClientID,
        s.EnrollmentID
)

SELECT
    ae.ClientID,
    ae.EnrollmentID,
    ae.EnrollmentDate,
    ae.ExitDate,
    COALESCE(sa.ServiceCount, 0)    AS ServiceCount,
    COALESCE(sa.TotalAmount, 0)     AS TotalAmount,
    sa.MostRecentService
FROM ActiveEnrollments ae
LEFT JOIN ServiceActivity sa ON ae.EnrollmentID = sa.EnrollmentID
ORDER BY ae.ClientID;
```

## Column Aliasing
- Alias every output column explicitly — no ambiguous names
- Use descriptive names, not abbreviations: EnrollmentDate not EnrDt
- For calculated fields, always alias: COUNT(*) AS ClientCount, not COUNT(*)

## Indentation
- 4 spaces (no tabs)
- Continuation lines for WHERE / AND / OR align under the first condition
- JOIN conditions indent under their JOIN

## NULL Handling
- Always use IS NULL / IS NOT NULL — never = NULL or <> NULL
- When a LEFT JOIN column might be null, wrap in COALESCE where appropriate
- ISNULL(col, 0) is acceptable shorthand for numeric defaults

## Date Filtering
- Use open-ended ranges over BETWEEN for enrollment/exit logic:
  WHERE EnrollmentDate <= @EndDate AND (ExitDate IS NULL OR ExitDate >= @StartDate)
- BETWEEN is acceptable for service dates when both endpoints are firm
- Avoid YEAR(col) = 2025 — use col >= '2025-01-01' AND col < '2026-01-01'

## Comments
- Header comment block on every file (see template above)
- One-line comment above each CTE explaining its purpose
- Inline comments for any non-obvious business logic

## Formatting Don'ts
- No SELECT *
- No magic numbers — use a variable or a comment explaining the value
- No comma-first style
- No single-letter aliases except for very short, obvious joins (e ON e.ID = ...)
