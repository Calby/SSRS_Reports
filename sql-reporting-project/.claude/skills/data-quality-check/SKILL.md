---
name: data-quality-check
description: Run a data quality check against a CaseWorthy report dataset. Use when
  asked to check data quality, find missing values, flag enrollment errors, or audit
  HMIS universal data elements in a query result. Triggers on: "data quality",
  "DQ check", "missing values", "enrollment errors", "HMIS audit".
---

# Data Quality Check Skill

## When This Skill Applies
When asked to check data quality on a query result or report dataset, or to write
a data quality audit query for any CaseWorthy or ServTracker program.

## Standard DQ Checks to Include

### Enrollment Logic Errors
```sql
-- Enrollments where ExitDate precedes EnrollmentDate (data error)
SELECT EnrollmentID, ClientID, EnrollmentDate, ExitDate
FROM Enrollment
WHERE ExitDate < EnrollmentDate

-- Enrollments with future EnrollmentDate (likely data entry error)
SELECT EnrollmentID, ClientID, EnrollmentDate
FROM Enrollment
WHERE EnrollmentDate > GETDATE()
```

### Universal Data Element Completeness
For any HMIS report, check these fields for NULL, 'Data not collected',
'Don't know', or 'Refused':
- DateOfBirth
- Gender
- Race / Ethnicity
- VeteranStatus
- DisablingCondition
- PriorLivingSituation (Element 3.917)

### Duplicate Active Enrollments
```sql
-- Clients with more than one active enrollment in the same program
SELECT ClientID, ProgramID, COUNT(*) AS ActiveCount
FROM Enrollment
WHERE ExitDate IS NULL
GROUP BY ClientID, ProgramID
HAVING COUNT(*) > 1
```

### Age Anomalies
```sql
-- Clients with calculated age < 0 or > 120
SELECT ClientID, DateOfBirth,
       DATEDIFF(YEAR, DateOfBirth, GETDATE()) AS Age
FROM ClientDemographic
WHERE DATEDIFF(YEAR, DateOfBirth, GETDATE()) < 0
   OR DATEDIFF(YEAR, DateOfBirth, GETDATE()) > 120
```

## Output Format for DQ Reports
When generating a DQ audit query:
1. One CTE per check category
2. Final SELECT unions all issues with an IssueCategory column
3. Include ClientID and EnrollmentID for follow-up
4. Include a COUNT summary at the top using a separate CTE
5. Never return client names or SSNs in the output
