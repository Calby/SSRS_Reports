# SQL Guide for CaseWorthy

**A practical guide to reading and writing SQL — using real SVDP CaseWorthy examples**

This guide teaches SQL concepts using the actual CaseWorthy database tables and views you work with every day. Each section introduces a concept, explains what it does in plain English, then shows it in action with real data.

---

## Table of Contents

1. [The Big Picture: What SQL Does](#1-the-big-picture-what-sql-does)
2. [SELECT — Choosing Your Columns](#2-select--choosing-your-columns)
3. [FROM — Picking Your Table](#3-from--picking-your-table)
4. [WHERE — Filtering Your Rows](#4-where--filtering-your-rows)
5. [JOIN — Connecting Tables Together](#5-join--connecting-tables-together)
6. [Aliases — Giving Tables Short Names](#6-aliases--giving-tables-short-names)
7. [CASE — If/Then Logic Inside SQL](#7-case--ifthen-logic-inside-sql)
8. [Functions — Built-In Calculations](#8-functions--built-in-calculations)
9. [GROUP BY — Summarizing Data](#9-group-by--summarizing-data)
10. [ORDER BY — Sorting Results](#10-order-by--sorting-results)
11. [Subqueries — Queries Inside Queries](#11-subqueries--queries-inside-queries)
12. [CTEs — Named Building Blocks](#12-ctes--named-building-blocks)
13. [Window Functions — ROW_NUMBER and PARTITION BY](#13-window-functions--row_number-and-partition-by)
14. [OUTER APPLY — A Smarter Join](#14-outer-apply--a-smarter-join)
15. [CROSS JOIN — Every Combination](#15-cross-join--every-combination)
16. [Views — Saving Queries for Reuse](#16-views--saving-queries-for-reuse)
17. [Putting It All Together — Reading a Full View](#17-putting-it-all-together--reading-a-full-view)
18. [CaseWorthy-Specific Patterns](#18-caseworthy-specific-patterns)
19. [Quick Reference Cheat Sheet](#19-quick-reference-cheat-sheet)

---

## 1. The Big Picture: What SQL Does

SQL (Structured Query Language) is how you ask a database a question. Every SQL query follows the same basic pattern:

```
"Give me THESE COLUMNS from THIS TABLE where THESE CONDITIONS are true."
```

In SQL, that looks like:

```sql
SELECT columns
FROM table
WHERE conditions
```

That's it. Everything else in SQL — joins, grouping, sorting, subqueries — is just adding more detail to that basic question.

---

## 2. SELECT — Choosing Your Columns

`SELECT` tells the database which columns you want to see. Think of it as choosing which columns to show in a spreadsheet.

### Show specific columns

```sql
SELECT FirstName, LastName, BirthDate
FROM Client
```

This returns three columns for every client — their first name, last name, and date of birth.

### Show all columns

```sql
SELECT *
FROM Client
```

The `*` means "give me everything." Useful for exploring, but in views we almost always pick specific columns.

### Rename columns with AS

Sometimes a column name in the database isn't user-friendly. `AS` lets you rename it in your results:

```sql
SELECT
    EntityID AS ClientID,
    FirstName,
    LastName,
    VeteranStatus AS VetStatus
FROM Client
```

`EntityID` will show up as "ClientID" in the results. The actual database column doesn't change — it's just a display name. You'll see this constantly in CaseWorthy views because `EntityID` is clearer to us as `ClientID`.

### Calculated columns

You can create brand new columns with math or logic:

```sql
SELECT
    EntityID AS ClientID,
    FirstName,
    LastName,
    730 - DATEDIFF(DAY, CreatedDate, GETDATE()) AS DaysUntilExpiration
FROM Client
```

This creates a column called `DaysUntilExpiration` that doesn't exist in the database — it's calculated on the fly every time the query runs.

---

## 3. FROM — Picking Your Table

`FROM` tells SQL which table to pull data from. It's the starting point of every query.

```sql
SELECT FirstName, LastName
FROM Client
```

This says: "Go to the `Client` table and get me first and last names."

Some common CaseWorthy tables you'll see in `FROM`:

| Table | What it holds |
|-------|--------------|
| `Client` | Client demographics (name, DOB, SSN, veteran status) |
| `Enrollment` | Program enrollments (start date, end date, status) |
| `EnrollmentMember` | Links individual clients to enrollments |
| `Assessment` | Assessment records (entry, during, exit) |
| `CaseManagerAssignment` | Which staff are assigned to which enrollments |
| `WorkHistory` | Staff employment records (job type, start date) |
| `DocumentCheck` | Uploaded client documents |
| `XSVdPReferral` | Custom SVDP referral records |

---

## 4. WHERE — Filtering Your Rows

`WHERE` is how you filter. Without it, you get every row in the table. With it, you only get the rows that match your conditions.

### Basic filter

```sql
SELECT FirstName, LastName, VeteranStatus
FROM Client
WHERE VeteranStatus = 1
```

Only returns clients where Veteran Status = Yes (1).

### Multiple conditions with AND / OR

```sql
SELECT FirstName, LastName
FROM Client
WHERE VeteranStatus = 1
  AND DeletedDate IS NULL
```

Both conditions must be true. The client must be a veteran **and** not soft-deleted.

```sql
SELECT FirstName, LastName
FROM Client
WHERE VeteranStatus = 1
  OR VeteranStatus = 8
```

Either condition can be true. Returns veterans **or** clients who answered "Don't Know."

### The soft-delete filter (CaseWorthy critical pattern)

This is the most important WHERE clause in CaseWorthy. Almost every query needs it:

```sql
WHERE DeletedDate IS NULL
```

or the legacy version:

```sql
WHERE DeletedDate = '12/31/9999'
```

Both mean the same thing: **"only give me active, non-deleted records."** CaseWorthy doesn't actually delete data — it sets `DeletedDate` to mark records as removed. If you forget this filter, you'll get deleted records mixed in with active ones.

### IN — matching a list of values

Instead of writing `OR` over and over:

```sql
-- Instead of this:
WHERE ProgramJobTypeID = 122
   OR ProgramJobTypeID = 123
   OR ProgramJobTypeID = 126
   OR ProgramJobTypeID = 130

-- Write this:
WHERE ProgramJobTypeID IN (122, 123, 126, 130)
```

Both do the same thing. `IN` is just cleaner when you have multiple values.

### IS NULL / IS NOT NULL

`NULL` means "no value" — the field is empty. You can't use `=` with NULL. You have to use `IS`:

```sql
-- WRONG (this won't work):
WHERE DeletedDate = NULL

-- RIGHT:
WHERE DeletedDate IS NULL
```

```sql
-- Find clients who HAVE a birth date recorded:
WHERE BirthDate IS NOT NULL
```

### Comparison operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equals | `WHERE Status = 1` |
| `!=` or `<>` | Not equals | `WHERE Status != 3` |
| `>` | Greater than | `WHERE BeginDate > '2025-01-01'` |
| `<` | Less than | `WHERE EndDate < GETDATE()` |
| `>=` | Greater than or equal | `WHERE DaysSince >= 90` |
| `<=` | Less than or equal | `WHERE DATEDIFF(DAY, UploadDate, GETDATE()) <= 730` |

---

## 5. JOIN — Connecting Tables Together

This is where SQL gets powerful. In CaseWorthy, data is spread across many tables. A client's name is in `Client`, their enrollment is in `Enrollment`, their case manager is in `CaseManagerAssignment`. JOINs connect these tables together.

### How joins work

A JOIN says: "Match rows from Table A to rows in Table B where a specific column matches."

Think of it like a VLOOKUP in Excel — you're looking up data from another table based on a shared ID.

### INNER JOIN — Only matching rows

```sql
SELECT
    c.FirstName,
    c.LastName,
    e.BeginDate AS EnrollmentStart,
    e.EndDate AS EnrollmentEnd
FROM Client c
INNER JOIN EnrollmentMember em ON em.ClientID = c.EntityID
INNER JOIN Enrollment e ON e.EnrollmentID = em.EnrollmentID
WHERE c.DeletedDate IS NULL
  AND em.DeletedDate IS NULL
  AND e.DeletedDate = '12/31/9999'
```

**What this does:** Gets every client's name along with their enrollment dates. The `INNER JOIN` means: only show clients who have enrollments, and only show enrollments that have clients. If a client has no enrollment, they're excluded. If an enrollment somehow has no client, it's excluded too.

**How the connections work:**
1. Start with `Client` (has the name)
2. Join to `EnrollmentMember` — this table links clients to enrollments (`ClientID` matches `EntityID`)
3. Join to `Enrollment` — this table has the enrollment dates (`EnrollmentID` matches `EnrollmentID`)

### LEFT JOIN — Keep everything from the left table

```sql
SELECT
    c.EntityID AS ClientID,
    dt.TypeDescription,
    lf.UploadDate
FROM Client c
CROSS JOIN DocumentTypes dt
LEFT JOIN LatestFiles lf
    ON lf.ClientID = c.EntityID
    AND lf.DocumentTypeID = dt.DocumentTypeID
```

**What this does:** Gets every client and every document type, and *if* they have an uploaded file, shows the upload date. If they don't have a file, the row still appears but `UploadDate` will be `NULL`.

**INNER JOIN vs LEFT JOIN:**
- `INNER JOIN` = "Only show rows where both sides match" (excludes non-matches)
- `LEFT JOIN` = "Show everything from the left table, even if there's no match on the right" (non-matches show NULL)

This is from the actual `x_uvw_ClientDocumentCheck_NonTFA` view. It uses LEFT JOIN because we want to see **all** clients and **all** document types — even when the document hasn't been uploaded yet. That's how the view can show "No" for documents that are missing.

### Real example: x_uvw_LatestUserByJobType

```sql
FROM CaseManagerAssignment CMA
LEFT JOIN StaffJobTypes SJT ON SJT.StaffID = CMA.UserID AND SJT.rn = 1
```

This joins case manager assignments to their job types. It uses `LEFT JOIN` because we want to keep all assignments even if the staff member doesn't have a job type in `WorkHistory` yet.

Notice the `AND SJT.rn = 1` — this is a multi-condition join. It's saying "match on StaffID AND only take the first row." More on `rn` (row number) in the [Window Functions](#13-window-functions--row_number-and-partition-by) section.

### Join summary

| Join Type | What It Does | When to Use It |
|-----------|-------------|----------------|
| `INNER JOIN` | Only rows that match in both tables | When you only want records that exist in both tables |
| `LEFT JOIN` | All rows from the left table + matches from the right | When the right table might not have a match and you still want the row |
| `RIGHT JOIN` | All rows from the right table + matches from the left | Rarely used — you can usually rewrite as a LEFT JOIN |
| `CROSS JOIN` | Every row from A combined with every row from B | When you need all possible combinations (see [Section 15](#15-cross-join--every-combination)) |

---

## 6. Aliases — Giving Tables Short Names

When you see things like `c.FirstName` or `CMA.EnrollmentID`, the letter/abbreviation before the dot is an **alias** — a short name for the table.

```sql
-- Without aliases (verbose):
SELECT Client.FirstName, Client.LastName, Enrollment.BeginDate
FROM Client
INNER JOIN EnrollmentMember ON EnrollmentMember.ClientID = Client.EntityID
INNER JOIN Enrollment ON Enrollment.EnrollmentID = EnrollmentMember.EnrollmentID

-- With aliases (clean):
SELECT c.FirstName, c.LastName, e.BeginDate
FROM Client c
INNER JOIN EnrollmentMember em ON em.ClientID = c.EntityID
INNER JOIN Enrollment e ON e.EnrollmentID = em.EnrollmentID
```

Both queries do the exact same thing. Aliases just make it shorter and easier to read.

**Common aliases in CaseWorthy views:**

| Table | Common Alias |
|-------|-------------|
| Client | `c` |
| Enrollment | `e` |
| EnrollmentMember | `em` |
| Assessment | `a` |
| CaseManagerAssignment | `CMA` |
| WorkHistory | `WH` |
| DocumentCheck | `dc` |
| Files | `f` |
| EnrollmentServicePlan | `esp` |

---

## 7. CASE — If/Then Logic Inside SQL

`CASE` is SQL's version of an IF statement. It lets you create new values based on conditions.

### Basic structure

```sql
CASE
    WHEN condition THEN result
    WHEN condition THEN result
    ELSE default_result
END
```

### Real example: Document validity check

From `x_uvw_ClientDocumentCheck_NonTFA`:

```sql
SELECT
    CASE
        WHEN lf.UploadDate IS NULL THEN 'No'
        WHEN DATEDIFF(DAY, lf.UploadDate, GETDATE()) <= 730 THEN 'Yes'
        ELSE 'No'
    END AS IsValid
```

**In plain English:**
- If there's no upload date (document was never uploaded) → **"No"**
- If the document was uploaded within the last 730 days (2 years) → **"Yes"**
- Otherwise (document is expired) → **"No"**

### Real example: Days since recertification

From `X_UVW_Latest90DayRecertWEnroll`:

```sql
CASE
    WHEN lr.BeginAssessment IS NOT NULL
    THEN DATEDIFF(DAY, lr.BeginAssessment, GETDATE())
    ELSE NULL
END AS DaysSinceLastRecert
```

**In plain English:**
- If the client has an assessment date → calculate how many days ago it was
- If they don't have one → return NULL (blank)

### Real example: Referral days calculation

From `x_uvw_DaysSinceLastReferral`:

```sql
DATEDIFF(DAY,
    r.CreatedDate,
    CASE
        WHEN r.X_ReferralStatus IN (4, 5, 7, 8, 99)
            THEN r.LastModifiedDate   -- frozen: use last modified as proxy for close date
        ELSE
            GETDATE()                 -- still open: count to today
    END
) AS DaysSinceReferral
```

**In plain English:**
- If the referral is closed (status 4, 5, 7, 8, or 99) → count days from creation to when it was last modified (closed)
- If the referral is still open → count days from creation to today

This shows a `CASE` used *inside* a function — the CASE decides which end-date to use in the DATEDIFF calculation.

---

## 8. Functions — Built-In Calculations

SQL Server has built-in functions that do calculations for you. Here are the ones used most in CaseWorthy views:

### DATEDIFF — Days between two dates

```sql
DATEDIFF(DAY, StartDate, EndDate)
```

Returns the number of days between two dates. Used everywhere in CaseWorthy:

```sql
-- Days since last recertification:
DATEDIFF(DAY, lr.BeginAssessment, GETDATE()) AS DaysSinceLastRecert

-- Days until document expires (730-day validity):
730 - DATEDIFF(DAY, lf.UploadDate, GETDATE()) AS DaysUntilExpiration

-- Days since last housing stability plan:
DATEDIFF(DAY, p.PlanBeginDate, GETDATE()) AS DaysSinceLastHousingStabilityPlan
```

### GETDATE — Today's date and time

```sql
GETDATE()   -- Returns the current date and time, like: 2026-03-16 14:30:00
```

Used as the "end date" when you want to measure time from some past event until now.

### TOP — Limit number of results

```sql
SELECT TOP 1 AssessmentID, BeginAssessment
FROM Assessment
ORDER BY BeginAssessment DESC
```

Only returns 1 row — the most recent assessment. `TOP 5` would return the 5 most recent.

### COUNT, SUM, AVG, MIN, MAX — Aggregate functions

These summarize data (used with [GROUP BY](#9-group-by--summarizing-data)):

```sql
SELECT
    ProgramID,
    COUNT(*) AS TotalEnrollments,
    MIN(BeginDate) AS EarliestEnrollment,
    MAX(BeginDate) AS LatestEnrollment
FROM Enrollment
WHERE DeletedDate = '12/31/9999'
GROUP BY ProgramID
```

| Function | What It Does |
|----------|-------------|
| `COUNT(*)` | Counts rows |
| `COUNT(ColumnName)` | Counts non-NULL values in that column |
| `SUM(Column)` | Adds up all values |
| `AVG(Column)` | Calculates the average |
| `MIN(Column)` | Finds the smallest value |
| `MAX(Column)` | Finds the largest value |

---

## 9. GROUP BY — Summarizing Data

`GROUP BY` collapses multiple rows into summary rows. It's how you answer questions like "how many enrollments does each program have?"

### Without GROUP BY

```sql
SELECT ProgramID, EnrollmentID
FROM Enrollment
WHERE DeletedDate = '12/31/9999'
```

Returns one row per enrollment — could be thousands of rows.

### With GROUP BY

```sql
SELECT
    ProgramID,
    COUNT(*) AS TotalEnrollments
FROM Enrollment
WHERE DeletedDate = '12/31/9999'
GROUP BY ProgramID
```

Returns one row per program, with the count of enrollments for each. If you have 20 programs, you get 20 rows.

### The rule

When you use `GROUP BY`, every column in your `SELECT` must either:
1. Be in the `GROUP BY` list, **or**
2. Be inside an aggregate function (COUNT, SUM, AVG, MIN, MAX)

```sql
-- VALID:
SELECT ProgramID, COUNT(*) AS Total
FROM Enrollment
GROUP BY ProgramID

-- INVALID (FirstName is not grouped or aggregated):
SELECT ProgramID, FirstName, COUNT(*) AS Total
FROM Enrollment
GROUP BY ProgramID    -- Error! What should FirstName be?
```

### HAVING — Filtering after grouping

`WHERE` filters individual rows *before* grouping. `HAVING` filters groups *after* grouping.

```sql
SELECT
    ProgramID,
    COUNT(*) AS TotalEnrollments
FROM Enrollment
WHERE DeletedDate = '12/31/9999'    -- filter rows first
GROUP BY ProgramID
HAVING COUNT(*) > 10                -- then filter groups
```

This only shows programs that have more than 10 enrollments.

### Real-world example: Documents per client

```sql
SELECT
    dc.ClientID,
    COUNT(*) AS TotalDocuments,
    COUNT(CASE WHEN DATEDIFF(DAY, f.CreatedDate, GETDATE()) <= 730 THEN 1 END) AS ValidDocuments,
    COUNT(CASE WHEN DATEDIFF(DAY, f.CreatedDate, GETDATE()) > 730 THEN 1 END) AS ExpiredDocuments
FROM DocumentCheck dc
INNER JOIN UVW_DocumentFile udf ON udf.DocumentCheckID = dc.DocumentCheckID
INNER JOIN Files f ON f.FileID = udf.FileID
WHERE dc.DeletedDate = '12/31/9999'
  AND f.DeletedDate = '12/31/9999'
GROUP BY dc.ClientID
```

This gives you one row per client showing their total, valid, and expired document counts.

---

## 10. ORDER BY — Sorting Results

`ORDER BY` controls the order of your results. Without it, SQL returns rows in no guaranteed order.

```sql
-- Sort by last name A → Z:
SELECT FirstName, LastName
FROM Client
WHERE DeletedDate IS NULL
ORDER BY LastName ASC

-- Sort by enrollment date, newest first:
SELECT EnrollmentID, BeginDate
FROM Enrollment
ORDER BY BeginDate DESC
```

| Direction | Meaning |
|-----------|---------|
| `ASC` | Ascending — A to Z, oldest to newest, smallest to largest (default) |
| `DESC` | Descending — Z to A, newest to oldest, largest to smallest |

You can sort by multiple columns:

```sql
ORDER BY LastName ASC, FirstName ASC    -- Sort by last name, then first name within ties
```

From `X_UVW_MostRecentHousingStabilityPlan`:

```sql
ORDER BY esp.PlanBeginDate DESC, esp.EnrollmentServicePlanID DESC
```

This sorts by plan date (newest first), and if two plans started on the same date, the one with the higher ID comes first.

---

## 11. Subqueries — Queries Inside Queries

A subquery is a full `SELECT` statement nested inside another query. Think of it as a query that feeds its results into a bigger query.

### Subquery in WHERE

```sql
SELECT FirstName, LastName
FROM Client
WHERE EntityID IN (
    SELECT ClientID
    FROM EnrollmentMember
    WHERE EnrollmentID = 12345
)
```

**In plain English:** "Get the names of clients who are members of enrollment 12345."

The inner query finds all `ClientID` values for that enrollment. The outer query then looks up their names.

### Subquery in FROM (derived table)

```sql
SELECT sub.ProgramID, sub.TotalEnrollments
FROM (
    SELECT ProgramID, COUNT(*) AS TotalEnrollments
    FROM Enrollment
    WHERE DeletedDate = '12/31/9999'
    GROUP BY ProgramID
) AS sub
WHERE sub.TotalEnrollments > 5
```

The inner query creates a temporary result set (like a virtual table), and the outer query reads from it.

Subqueries work, but they can get messy when nested deeply. That's where CTEs come in.

---

## 12. CTEs — Named Building Blocks

A CTE (Common Table Expression) is a named, reusable subquery. It's the same concept as a subquery but written in a way that's much easier to read.

### Basic structure

```sql
WITH MyTemporaryName AS (
    SELECT columns
    FROM table
    WHERE conditions
)
SELECT *
FROM MyTemporaryName
```

The `WITH` block defines a temporary result set. Then you query it below like any normal table.

### Why CTEs matter

**Every custom view in your CaseWorthy database uses CTEs.** They're the building-block pattern Gibson uses consistently. Let's break down a real one.

### Real example: x_uvw_LatestUserByJobType (step by step)

This view has **three CTEs chained together**. Each one builds on the previous:

```sql
-- CTE #1: Get each staff member's current job type
WITH StaffJobTypes AS (
    SELECT
        WH.ClientID AS StaffID,
        WH.ProgramJobTypeID,
        ROW_NUMBER() OVER (
            PARTITION BY WH.ClientID
            ORDER BY WH.BeginDate DESC
        ) AS rn
    FROM WorkHistory WH
    WHERE WH.DeletedDate = '12/31/9999'
),
```

**What this does:** Goes to `WorkHistory`, gets each staff member's job type history, and numbers them newest-first. So `rn = 1` is their current job.

```sql
-- CTE #2: Add job type info to each case manager assignment
AssignmentsWithJobType AS (
    SELECT
        CMA.EnrollmentID,
        CMA.ClientID,
        CMA.UserID,
        CMA.AssignmentID,
        CMA.BeginDate,
        SJT.ProgramJobTypeID
    FROM CaseManagerAssignment CMA
    LEFT JOIN StaffJobTypes SJT ON SJT.StaffID = CMA.UserID AND SJT.rn = 1
    WHERE CMA.DeletedDate = '12/31/9999'
),
```

**What this does:** Takes every case manager assignment and looks up that staff member's current job type (from CTE #1). The `LEFT JOIN` + `rn = 1` means "get their most recent job type."

```sql
-- CTE #3: For each enrollment + job type combo, find the most recent assignment
LatestPerJobType AS (
    SELECT
        EnrollmentID,
        ClientID,
        UserID,
        AssignmentID,
        ProgramJobTypeID,
        ROW_NUMBER() OVER (
            PARTITION BY EnrollmentID, ProgramJobTypeID
            ORDER BY BeginDate DESC
        ) AS rn
    FROM AssignmentsWithJobType
    WHERE ProgramJobTypeID IS NOT NULL
)
```

**What this does:** Within each enrollment, for each job type, number the assignments newest-first.

```sql
-- Final SELECT: Just keep the most recent one
SELECT
    ProgramJobTypeID,
    UserID,
    ClientID,
    EnrollmentID,
    AssignmentID
FROM LatestPerJobType
WHERE rn = 1
```

**What this does:** Only keep row number 1 — the latest assignment for each enrollment/job-type combination.

### Reading CTEs: The pattern

Every CTE-based view in CaseWorthy follows this pattern:

```
WITH Step1 AS (get raw data, number the rows),
     Step2 AS (join/filter the results from Step1),
     Step3 AS (further refine)
SELECT final result
FROM Step3
WHERE rn = 1    ← keep only the "latest" or "best" row
```

Think of CTEs as a recipe: each step prepares an ingredient, and the final SELECT assembles the dish.

---

## 13. Window Functions — ROW_NUMBER and PARTITION BY

This is the single most-used advanced pattern in CaseWorthy views. If you understand this, you can read almost any view in the system.

### The problem it solves

You often need "the most recent" something:
- The most recent assessment for each enrollment
- The most recent job type for each staff member
- The most recent document upload for each client + document type

### ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)

```sql
ROW_NUMBER() OVER (
    PARTITION BY WH.ClientID
    ORDER BY WH.BeginDate DESC
) AS rn
```

**Breaking it down:**

| Part | What It Does |
|------|-------------|
| `ROW_NUMBER()` | Assigns a number (1, 2, 3...) to each row |
| `PARTITION BY WH.ClientID` | Start numbering over for each staff member |
| `ORDER BY WH.BeginDate DESC` | Number them newest-first |
| `AS rn` | Call the result column "rn" |

### Visual example

Imagine a staff member (ClientID 500) has three job history records:

| ClientID | ProgramJobTypeID | BeginDate | → rn |
|:--------:|:----------------:|:---------:|:----:|
| 500 | 122 (Case Manager) | 2025-06-01 | **1** |
| 500 | 121 (CM Assistant) | 2024-01-15 | 2 |
| 500 | 120 (Receptionist) | 2023-03-01 | 3 |

And another staff member (ClientID 501) has two records:

| ClientID | ProgramJobTypeID | BeginDate | → rn |
|:--------:|:----------------:|:---------:|:----:|
| 501 | 130 (Navigator) | 2025-09-01 | **1** |
| 501 | 126 (Lead Navigator) | 2024-05-20 | 2 |

`PARTITION BY ClientID` means each person's rows are numbered independently. `ORDER BY BeginDate DESC` means the newest row gets `rn = 1`.

### Then filter to rn = 1

```sql
WHERE rn = 1
```

This keeps only the most recent row for each group — giving you exactly one row per staff member with their current job type.

### Where you'll see this in CaseWorthy views

| View | PARTITION BY | Gets you... |
|------|-------------|-------------|
| `x_uvw_LatestUserByJobType` | `ClientID` then `EnrollmentID, ProgramJobTypeID` | Latest staff assignment per enrollment per job type |
| `X_UVW_Latest90DayRecertWEnroll` | (uses TOP 1 instead) | Most recent during-assessment per enrollment |
| `x_uvw_ClientDocumentCheck_NonTFA` | `ClientID, DocumentTypeID` | Most recent upload per client per document type |
| `X_UVW_MostRecentHousingStabilityPlan` | `EnrollmentID` | Most recent housing stability plan per enrollment |

---

## 14. OUTER APPLY — A Smarter Join

`OUTER APPLY` is like a LEFT JOIN but more powerful. It lets you run a subquery for each row in the main table.

### Real example: X_UVW_Latest90DayRecertWEnroll

```sql
FROM Enrollment e
INNER JOIN EnrollmentMember em
    ON em.EnrollmentID = e.EnrollmentID
OUTER APPLY (
    SELECT TOP 1
        a.AssessmentID,
        a.BeginAssessment
    FROM Assessment a
    INNER JOIN XAssessEntry xae
        ON xae.AssessmentID = a.AssessmentID
    WHERE
        a.EnrollmentID = e.EnrollmentID           -- ← references the outer query!
        AND a.DeletedDate = '12/31/9999'
        AND xae.X_Whattypeofduringassessment IS NOT NULL
    ORDER BY
        a.BeginAssessment DESC,
        a.AssessmentID DESC
) lr
```

**What this does:** For each enrollment, it runs a mini-query to find the single most recent assessment that has a "during assessment" type filled in.

**Why not just use a regular JOIN?** Because we need `TOP 1` per enrollment, and we need to reference the outer row (`e.EnrollmentID`). OUTER APPLY lets us do both.

**OUTER APPLY vs CROSS APPLY:**
- `OUTER APPLY` = like LEFT JOIN — keeps the row even if the subquery returns nothing (values will be NULL)
- `CROSS APPLY` = like INNER JOIN — drops the row if the subquery returns nothing

---

## 15. CROSS JOIN — Every Combination

A `CROSS JOIN` produces every possible combination of rows from two tables. If Table A has 5 rows and Table B has 100 rows, you get 500 rows.

### Real example: x_uvw_ClientDocumentCheck_NonTFA

```sql
FROM Client c
CROSS JOIN DocumentTypes dt
LEFT JOIN LatestFiles lf
    ON lf.ClientID = c.EntityID
    AND lf.DocumentTypeID = dt.DocumentTypeID
```

**What this does:**
1. `CROSS JOIN` creates a row for every client × every document type combination. If you have 1,000 clients and 60 document types, that's 60,000 rows.
2. `LEFT JOIN` then checks if each combination has an uploaded file.
3. The result: a complete matrix showing which documents each client has and which are missing.

**Why this is useful:** The CaseWorthy document checklist forms need to show every document type for every client — even the ones they haven't uploaded. A CROSS JOIN guarantees every combination appears in the results.

---

## 16. Views — Saving Queries for Reuse

A **view** is a saved query that acts like a virtual table. Once created, you can query the view just like you'd query any table.

### Creating a view

```sql
CREATE OR ALTER VIEW [dbo].[x_uvw_MyView]
AS
SELECT
    c.EntityID AS ClientID,
    c.FirstName,
    c.LastName
FROM Client c
WHERE c.DeletedDate IS NULL
GO
```

Now anyone can write:

```sql
SELECT * FROM x_uvw_MyView
```

And they'll get the same results as running the full query.

### CaseWorthy naming conventions

| Prefix | Meaning |
|--------|---------|
| `x_uvw_` | Custom SVDP view |
| `X_UVW_` | Custom SVDP view (alternate casing) |
| `UVW_` | CaseWorthy native/system view |
| `vw_` | Custom view (alternate prefix) |

### Why views matter in CaseWorthy

Views are how CaseWorthy forms pull data. When you configure a form to show "days since last recert," the form is querying `X_UVW_Latest90DayRecertWEnroll` behind the scenes. The form just does:

```sql
SELECT DaysSinceLastRecert FROM X_UVW_Latest90DayRecertWEnroll WHERE ClientID = @CurrentClient
```

That's why Gibson creates views — they're the bridge between SQL and the CaseWorthy form builder.

---

## 17. Putting It All Together — Reading a Full View

Let's read `X_UVW_MostRecentHousingStabilityPlan` from top to bottom. This is a real production view.

```sql
CREATE OR ALTER VIEW [dbo].[X_UVW_MostRecentHousingStabilityPlan]
AS
```
*"Create (or update) a view called X_UVW_MostRecentHousingStabilityPlan."*

```sql
WITH MostRecentPlan AS (
    SELECT
        Client.EntityID AS ClientID,
        esp.EnrollmentID,
        esp.EnrollmentServicePlanID,
        esp.X_Phase,
        esp.PlanBeginDate,
        ROW_NUMBER() OVER (
            PARTITION BY esp.EnrollmentID
            ORDER BY esp.PlanBeginDate DESC, esp.EnrollmentServicePlanID DESC
        ) AS rn
    FROM Client
    INNER JOIN EnrollmentServicePlan esp
        ON Client.EntityID = esp.ClientID
    WHERE
        Client.DeletedDate = '12/31/9999'
        AND esp.DeletedDate = '12/31/9999'
),
```

**CTE #1 — MostRecentPlan:** *"For each enrollment, find all housing stability plans and number them newest-first."*

- Joins `Client` to `EnrollmentServicePlan` on `EntityID = ClientID`
- Filters out deleted records
- `ROW_NUMBER()` partitioned by enrollment, ordered by date descending → `rn = 1` is the latest plan

```sql
MostRecentGoal AS (
    SELECT
        spg.EnrollmentServicePlanID,
        g.GoalID,
        g.SetDate,
        g.PercentComplete,
        gt.TypeDescription,
        ROW_NUMBER() OVER (
            PARTITION BY spg.EnrollmentServicePlanID
            ORDER BY g.SetDate DESC, g.GoalID DESC
        ) AS rn
    FROM ServicePlanGoals spg
    INNER JOIN Goal g ON spg.GoalID = g.GoalID
    LEFT JOIN GoalType gt ON g.GoalTypeID = gt.GoalTypeID
)
```

**CTE #2 — MostRecentGoal:** *"For each service plan, find the most recent goal."*

- Joins through `ServicePlanGoals` → `Goal` → `GoalType`
- `LEFT JOIN` on GoalType because some goals might not have a type set
- Again uses `ROW_NUMBER()` to get the latest goal per plan

```sql
SELECT
    p.ClientID,
    p.EnrollmentID,
    p.EnrollmentServicePlanID AS LatestHousingStabilityPlanID,
    p.X_Phase AS LatestHousingStabilityPhase,
    DATEDIFF(DAY, p.PlanBeginDate, GETDATE()) AS DaysSinceLastHousingStabilityPlan,
    p.PlanBeginDate AS DateOfHousingStabilityPlan,
    g.TypeDescription AS GoalDescription,
    g.SetDate AS GoalSetDate,
    g.PercentComplete AS PercentCompleteofGoal,
    g.GoalID,
    DATEDIFF(DAY, g.SetDate, GETDATE()) AS DaysSinceLastGoalUpdate
FROM MostRecentPlan p
LEFT JOIN MostRecentGoal g
    ON p.EnrollmentServicePlanID = g.EnrollmentServicePlanID
    AND g.rn = 1
WHERE p.rn = 1;
```

**Final SELECT:** *"Take the latest plan (rn=1) and its latest goal (rn=1), calculate days-since values, and output a clean result."*

- `LEFT JOIN` because a plan might not have any goals yet
- Both `WHERE p.rn = 1` and `g.rn = 1` ensure we get exactly one plan and one goal per enrollment
- `DATEDIFF` calculates how stale the plan and goal are

**End result:** One row per enrollment showing the most recent housing stability plan, its phase, the most recent goal under that plan, and how many days old everything is.

---

## 18. CaseWorthy-Specific Patterns

These patterns appear in almost every CaseWorthy SQL view. Know these and you can read any view in the system.

### Pattern 1: Soft-delete filtering

```sql
WHERE DeletedDate IS NULL           -- standard version
WHERE DeletedDate = '12/31/9999'    -- CaseWorthy legacy version
```

**Always include this.** If you forget, you'll pull deleted records.

### Pattern 2: "Get the latest" with ROW_NUMBER

```sql
WITH Latest AS (
    SELECT
        columns,
        ROW_NUMBER() OVER (
            PARTITION BY GroupingColumn
            ORDER BY DateColumn DESC
        ) AS rn
    FROM SomeTable
    WHERE DeletedDate = '12/31/9999'
)
SELECT * FROM Latest WHERE rn = 1
```

This is the standard pattern for "most recent X per Y." You'll see it in every view.

### Pattern 3: EntityID is always the client

`EntityID` in the `Client` table = `ClientID` everywhere else. The join is always:

```sql
ON Client.EntityID = OtherTable.ClientID
```

### Pattern 4: WorkHistory.ClientID is the STAFF member

This is a gotcha. In the `WorkHistory` table, `ClientID` refers to the **staff person**, not the client being served. Staff members are also stored as entities/clients in CaseWorthy.

```sql
-- This gets staff job types, NOT client job types:
FROM WorkHistory WH
WHERE WH.ClientID = @StaffEntityID
```

### Pattern 5: Assessment event types

```sql
-- Assessment event types:
-- 1 = Entry assessment
-- 2 = During/Update assessment
-- 3 = Exit assessment
```

When a view filters on assessment type, it's usually looking for during-assessments (type 2) for recertification tracking.

### Pattern 6: Active enrollments

```sql
WHERE e.EndDate > GETDATE()         -- enrollment hasn't ended yet
  AND e.DeletedDate = '12/31/9999'  -- not deleted
```

`EndDate = '12/31/9999'` means the enrollment is still open (no exit date set).

### Pattern 7: ListItem lookups

Dropdown values in CaseWorthy are stored as integer IDs that point to the `ListItem` table:

```sql
-- To see the actual text value of a dropdown:
SELECT li.Description
FROM ListItem li
WHERE li.ListItemID = @SomeDropdownValue
```

---

## 19. Quick Reference Cheat Sheet

### SQL Keywords in Order of Execution

SQL doesn't run in the order you write it. Here's the actual execution order:

| Step | Keyword | What It Does |
|:----:|---------|-------------|
| 1 | `FROM` / `JOIN` | Pick tables and connect them |
| 2 | `WHERE` | Filter individual rows |
| 3 | `GROUP BY` | Collapse rows into groups |
| 4 | `HAVING` | Filter groups |
| 5 | `SELECT` | Choose which columns to output |
| 6 | `ORDER BY` | Sort the results |
| 7 | `TOP` | Limit how many rows to return |

This is why you can't use a column alias from SELECT in your WHERE clause — WHERE runs before SELECT.

### Common CaseWorthy Query Templates

**Find active clients:**
```sql
SELECT EntityID, FirstName, LastName
FROM Client
WHERE DeletedDate IS NULL
```

**Find active enrollments for a client:**
```sql
SELECT e.EnrollmentID, e.ProgramID, e.BeginDate, e.EndDate
FROM Enrollment e
INNER JOIN EnrollmentMember em ON em.EnrollmentID = e.EnrollmentID
WHERE em.ClientID = @ClientID
  AND e.DeletedDate = '12/31/9999'
  AND em.DeletedDate = '12/31/9999'
  AND e.EndDate > GETDATE()
```

**Get the most recent assessment for each enrollment:**
```sql
WITH LatestAssessment AS (
    SELECT
        EnrollmentID,
        AssessmentID,
        BeginAssessment,
        ROW_NUMBER() OVER (
            PARTITION BY EnrollmentID
            ORDER BY BeginAssessment DESC
        ) AS rn
    FROM Assessment
    WHERE DeletedDate = '12/31/9999'
)
SELECT * FROM LatestAssessment WHERE rn = 1
```

**Count enrollments by program:**
```sql
SELECT
    e.ProgramID,
    COUNT(*) AS TotalEnrollments,
    COUNT(CASE WHEN e.EndDate > GETDATE() THEN 1 END) AS ActiveEnrollments,
    COUNT(CASE WHEN e.EndDate <= GETDATE() THEN 1 END) AS ExitedEnrollments
FROM Enrollment e
WHERE e.DeletedDate = '12/31/9999'
GROUP BY e.ProgramID
ORDER BY TotalEnrollments DESC
```

---

*This guide covers the SQL patterns used in SVDP's CaseWorthy custom views. For the full database schema, see `../Schema/CaseWorthy_Database_Schema_Reference.md`. For list item values (dropdown IDs), see `../Schema/CaseWorthy_ListItem_Reference.md`.*
