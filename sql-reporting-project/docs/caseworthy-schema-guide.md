# Understanding the CaseWorthy Database Schema

**How CaseWorthy organizes data — and what it means for learning SQL**

If you're a CaseWorthy administrator learning SQL, the database can feel overwhelming at first. Hundreds of tables, cryptic naming conventions, and data relationships that aren't always obvious. This article breaks down how the CaseWorthy schema actually works, calls out the things it does differently from what you'd expect, and uses real production views to show how it all connects.

This isn't a generic SQL tutorial. It's written for people who work in CaseWorthy every day and want to understand what's happening under the hood.

---

## The Core Idea: Everything Is an Entity

The first thing to understand about CaseWorthy is that **every person in the system — clients, staff, providers, organizations — starts as an Entity.**

```
Entity (EntityID)
  ├── Client      (demographics, DOB, SSN, veteran status)
  ├── Users       (login, role, supervisor, active status)
  ├── Provider    (provider name, address)
  └── Organization (org name, structure)
```

The `Entity` table is the root of the system. It assigns a universal `EntityID` to every person and organization. Then specialized tables extend it:

- `Client` adds demographics (name, DOB, SSN, veteran status)
- `Users` adds login credentials, roles, and supervisor assignments
- `Provider` adds provider-specific details

**What this means for SQL:** The `EntityID` is your universal key. When you see `ClientID` in another table, it's pointing back to `Entity.EntityID`. When you see `UserID`, it's also an `EntityID`. They're all the same numbering system.

```sql
-- These two people live in the same Entity table:
SELECT EntityID, EntityName FROM Entity WHERE EntityID = 12345  -- a client
SELECT EntityID, EntityName FROM Entity WHERE EntityID = 67890  -- a staff member
```

**The gotcha:** This means staff members ARE clients in the database. The `WorkHistory` table has a `ClientID` column, but it refers to the **staff member**, not a client being served. This trips up everyone when they first encounter it.

---

## How Clients Connect to Programs

This is the most important relationship in CaseWorthy, and it's not a direct connection. Clients don't link directly to enrollments. There's a table in between.

```
Client → EnrollmentMember → Enrollment → Program
```

### Why the extra table?

Because CaseWorthy supports **household enrollments**. A family of four enrolls as one `Enrollment`, but each family member gets their own `EnrollmentMember` row. This lets each person have:
- Their own start and end dates (a child might join late)
- Their own relationship to Head of Household
- Their own assessment records
- Their own case manager assignment

```sql
-- The three-table chain you'll write over and over:
SELECT c.FirstName, c.LastName, e.BeginDate, e.ProgramID
FROM Client c
INNER JOIN EnrollmentMember em ON em.ClientID = c.EntityID
INNER JOIN Enrollment e ON e.EnrollmentID = em.EnrollmentID
WHERE c.DeletedDate IS NULL
  AND em.DeletedDate IS NULL
  AND e.DeletedDate = '12/31/9999'
```

**What CaseWorthy does differently:** Many case management systems link clients directly to programs. CaseWorthy's three-table approach (Client → EnrollmentMember → Enrollment) is more flexible but means every query that needs both client data and enrollment data requires two JOINs instead of one. You'll never write a single JOIN to get from client to enrollment — it's always at least two.

### The Enrollment table itself

| Column | What It Means |
|--------|--------------|
| `EnrollmentID` | Unique ID for this enrollment |
| `ProgramID` | Which program (SSVF, GPD, RRH, etc.) |
| `FamilyID` | Groups household members together |
| `BeginDate` | When the enrollment started |
| `EndDate` | When it ended — **`12/31/9999` means still active** |
| `Status` | Active, Exited, Pending, etc. |

The `EndDate = '12/31/9999'` convention is one of CaseWorthy's signature patterns. Instead of using NULL to mean "no end date," they use a far-future date. This means "still active" in the system, and you'll filter on it constantly:

```sql
-- Active enrollments only:
WHERE e.EndDate > GETDATE() AND e.DeletedDate = '12/31/9999'
```

---

## The Soft-Delete System

CaseWorthy never truly deletes data. When a record is "deleted," it just sets the `DeletedDate` column. The row stays in the database forever.

**Every single table has this column.** And every single query needs to filter on it. Miss this filter and you'll pull records that were removed months or years ago.

There are two conventions, and they coexist in the same database:

| Convention | Meaning | Tables That Use It |
|------------|---------|-------------------|
| `DeletedDate IS NULL` | Active record | Client, EnrollmentMember, XSVdPReferral, and many others |
| `DeletedDate = '12/31/9999'` | Active record | Enrollment, WorkHistory, CaseManagerAssignment, DocumentCheck, Assessment |

**Why two conventions?** This is a CaseWorthy legacy inconsistency. Some tables use NULL to mean "not deleted" and others use the far-future date. There's no pattern to predict which one a table uses — you have to check.

**What this means for SQL:** You need to include a soft-delete filter for **every table** in your query. If you join three tables, you need three filters:

```sql
FROM Client c
INNER JOIN EnrollmentMember em ON em.ClientID = c.EntityID
INNER JOIN Enrollment e ON e.EnrollmentID = em.EnrollmentID
WHERE c.DeletedDate IS NULL              -- Client uses NULL
  AND em.DeletedDate IS NULL             -- EnrollmentMember uses NULL
  AND e.DeletedDate = '12/31/9999'       -- Enrollment uses far-future date
```

Every view Gibson has built includes these filters. If you forget one, your results will quietly include deleted data, and the numbers will be wrong in ways that are hard to spot.

---

## The Assessment Architecture: One Parent, Many Extensions

Assessments in CaseWorthy use a **parent-extension pattern**. There's one core `Assessment` table that stores the basics (who, when, what type), and then a constellation of extension tables that store the actual assessment data:

```
Assessment (AssessmentID, ClientID, EnrollmentID, AssessmentEvent, BeginAssessment)
  ├── AssessHUDUniversal    (housing status, prior residence, chronic homelessness)
  ├── AssessHUDProgram      (exit destination, disabling condition, DV, substance use)
  ├── XAssessEntry          (client type, referral source, VI-SPDAT scores, income verification)
  ├── Xacuityscale          (11-section acuity scoring)
  ├── XRiskAssess           (self-harm, safety)
  ├── XBarrierAssess        (barrier scoring)
  ├── XClientHousing        (housing preferences)
  ├── XHouseholdBudget      (budget data)
  └── XCompletedSSVFSurvey  (SSVF satisfaction survey)
```

All extension tables join 1:1 on `AssessmentID`. That means for any assessment, there's at most one row in each extension table.

### Assessment Event Types

The `AssessmentEvent` column tells you WHEN in the enrollment lifecycle this assessment happened:

| Value | Meaning | When It Happens |
|:-----:|---------|----------------|
| 1 | Entry | At enrollment start |
| 2 | During/Update | 90-day recertification, annual review |
| 3 | Exit | At enrollment exit |

This is important because the 90-day recertification tracking that drives a lot of SVDP's reporting is based on `AssessmentEvent = 2` (During assessments). The `X_UVW_Latest90DayRecertWEnroll` view specifically filters for during-assessments to find when each client was last recertified.

**What CaseWorthy does well here:** The extension pattern is clean. Instead of cramming 200 columns into one massive Assessment table, they split the data logically. This makes queries targeted — if you only need acuity scores, you join to `Xacuityscale` and ignore the rest. If you need HUD data, you join to `AssessHUDUniversal`.

**What to watch out for:** The `XAssessEntry` table is confusingly named. Despite the name, it's not limited to Entry assessments — it also stores during-assessment type data via `X_Whattypeofduringassessment`. The `X_UVW_Latest90DayRecertWEnroll` view joins to this table and filters on that column to identify recertification assessments specifically.

---

## Dropdown Values: The ListItem System

Almost every dropdown field in CaseWorthy — gender, race, referral status, job type, review status — is stored as an integer ID that points to the `ListItem` table.

```sql
-- What you see in the database:
Client.VeteranStatus = 1
Client.Gender = 1000000234
XSVdPReferral.X_ReferralStatus = 4

-- What those numbers mean:
-- VeteranStatus 1 = "Yes" (HUD-defined, hardcoded values)
-- Gender 1000000234 = whatever label is in ListItem
-- ReferralStatus 4 = "Closed - Successful" (from ListItem)
```

There are two patterns:

**Pattern 1: HUD-defined values** — Some fields use hardcoded integer values defined by HUD data standards. Veteran Status (0/1/8/9/99), SSN Data Quality (1/2/8/9), and Assessment Event (1/2/3) are examples. These are standardized and you can use CASE statements to decode them.

**Pattern 2: ListItem lookups** — Most custom fields use CaseWorthy's ListItem table. The integer stored in the column is a `ListItemID` that points to a row with the display text. To see what a value means, you'd join to `ListItem`.

**What this means for SQL:** When you GROUP BY or filter on these fields, you're working with numbers, not text. The query `WHERE X_ReferralStatus IN (4, 5, 7, 8, 99)` makes no intuitive sense until you know the ListItem mapping. Document these mappings (which is why we maintain `../Schema/CaseWorthy_ListItem_Reference.md`).

---

## The Custom Field System: X_ Prefix

CaseWorthy distinguishes between its built-in fields and fields that organizations add:

| Prefix | Meaning | Examples |
|--------|---------|---------|
| No prefix | Native CaseWorthy field | `FirstName`, `BirthDate`, `VeteranStatus`, `BeginDate` |
| `X_` | Custom field added by SVDP | `X_SOAR`, `X_Office`, `X_ReferralStatus`, `X_Phase` |
| `x_uvw_` | Custom SQL view created by SVDP | `x_uvw_LatestUserByJobType`, `x_uvw_ClientDocumentCheck_NonTFA` |

**What CaseWorthy does well:** This prefix convention makes it immediately clear what's standard and what's custom. If you see `X_AcuityTotal`, you know SVDP added that field and it won't exist in other CaseWorthy installations.

**What to watch out for:** Custom tables (like `XSVdPReferral`, `XAssessEntry`, `Xacuityscale`) don't always follow a consistent naming pattern. Some use `X_` prefix, some use `X` prefix without the underscore, and the casing varies (`XBarrierAssess` vs `Xacuityscale`). When writing SQL, always double-check the exact table name.

Also notable: custom fields are added to the table's column list alongside native fields. So the `Client` table has both `VeteranStatus` (native) and `X_SOAR` (custom) as peers. There's no separate custom table for client-level custom fields — they're added directly to the existing table.

---

## How CaseWorthy Views Solve the "Latest Record" Problem

The single most common question in CaseWorthy reporting is: **"What is the most recent X for each Y?"**

- Most recent assessment for each enrollment
- Most recent job type for each staff member
- Most recent case manager assignment per enrollment per job type
- Most recent document upload per client per document type
- Most recent housing stability plan per enrollment

CaseWorthy handles this with a consistent SQL pattern across all its custom views: **ROW_NUMBER() with PARTITION BY, then filter to rn = 1.**

### The pattern

```sql
WITH LatestSomething AS (
    SELECT
        columns,
        ROW_NUMBER() OVER (
            PARTITION BY GroupingColumn    -- "for each _____"
            ORDER BY DateColumn DESC      -- "most recent"
        ) AS rn
    FROM SomeTable
    WHERE DeletedDate = '12/31/9999'      -- active only
)
SELECT * FROM LatestSomething WHERE rn = 1  -- keep only the latest
```

### How each production view uses this pattern

**x_uvw_LatestUserByJobType** — Uses it TWICE in the same query:

1. First CTE: `PARTITION BY WH.ClientID ORDER BY WH.BeginDate DESC` → gets each staff member's current job type
2. Third CTE: `PARTITION BY EnrollmentID, ProgramJobTypeID ORDER BY BeginDate DESC` → gets the most recent assignment for each enrollment/job-type combination

**x_uvw_ClientDocumentCheck_NonTFA** — Uses it to find the most recent file upload per client per document type:

```sql
ROW_NUMBER() OVER (
    PARTITION BY dc.ClientID, dc.DocumentTypeID
    ORDER BY f.CreatedDate DESC
) AS rn
```

**X_UVW_MostRecentHousingStabilityPlan** — Uses it TWICE:

1. `PARTITION BY esp.EnrollmentID ORDER BY esp.PlanBeginDate DESC` → latest plan per enrollment
2. `PARTITION BY spg.EnrollmentServicePlanID ORDER BY g.SetDate DESC` → latest goal per plan

**What CaseWorthy does consistently:** Every custom view follows this CTE + ROW_NUMBER pattern. Once you learn to read one view, you can read them all. The structure is always:

```
WITH Step1 AS (get data, number rows),
     Step2 AS (optionally join/refine),
     Step3 AS (optionally join/refine further)
SELECT final columns
FROM last CTE
WHERE rn = 1
```

### The alternative pattern: OUTER APPLY with TOP 1

`X_UVW_Latest90DayRecertWEnroll` uses a different approach — `OUTER APPLY` with `SELECT TOP 1`:

```sql
OUTER APPLY (
    SELECT TOP 1
        a.AssessmentID,
        a.BeginAssessment
    FROM Assessment a
    INNER JOIN XAssessEntry xae ON xae.AssessmentID = a.AssessmentID
    WHERE a.EnrollmentID = e.EnrollmentID
      AND a.DeletedDate = '12/31/9999'
      AND xae.X_Whattypeofduringassessment IS NOT NULL
    ORDER BY a.BeginAssessment DESC, a.AssessmentID DESC
) lr
```

This achieves the same "latest record" goal but uses a correlated subquery instead of ROW_NUMBER. Both patterns are valid — OUTER APPLY is sometimes preferred when the subquery needs to reference the outer row and involves multiple JOINs internally.

---

## The Document Compliance Architecture

CaseWorthy's document tracking involves four tables:

```
Client
  └── DocumentCheck (the metadata: type, dates, client)
        └── UVW_DocumentFile (links document to its file)
              └── Files (the actual uploaded file)
```

The SVDP document check views (`x_uvw_ClientDocumentCheck_NonTFA` and `x_uvw_ClientDocumentCheck_TFA`) use a CROSS JOIN to create a complete matrix:

```sql
FROM Client c
CROSS JOIN DocumentTypes dt          -- every client × every document type
LEFT JOIN LatestFiles lf             -- check if a file exists
    ON lf.ClientID = c.EntityID
    AND lf.DocumentTypeID = dt.DocumentTypeID
```

**Why CROSS JOIN?** Because the form needs to show every document type for every client — even the ones that haven't been uploaded. A regular JOIN would only show documents that exist. CROSS JOIN creates the complete checklist, and LEFT JOIN fills in which ones are present.

**The 730-day rule:** Documents expire after 730 days (2 years). The views calculate this with:

```sql
CASE
    WHEN lf.UploadDate IS NULL THEN 'No'
    WHEN DATEDIFF(DAY, lf.UploadDate, GETDATE()) <= 730 THEN 'Yes'
    ELSE 'No'
END AS IsValid
```

**What's smart about this design:** The two views (`_NonTFA` and `_TFA`) are structurally identical — same logic, same CROSS JOIN pattern, same 730-day validity check. The only difference is the list of `DocumentTypeID` values in the CTE. This kind of parallel structure makes the system predictable.

---

## Case Manager Assignment: The Indirect Path

Finding out who a client's case manager is requires understanding a chain of relationships that isn't intuitive:

```
EnrollmentMember (ClientID, EnrollmentID)
  → CaseManagerAssignment (UserID = the case manager)
    → WorkHistory (ClientID = the staff member's EntityID)
      → ProgramJobTypeID (the staff person's job type)
```

**The confusing part:** `CaseManagerAssignment.UserID` is the staff person, but to find their job title, you go to `WorkHistory` where the same person is identified by `ClientID`. In `WorkHistory`, `ClientID` means "the employee" because staff members are entities too.

The `x_uvw_LatestUserByJobType` view untangles this by:
1. Looking up each staff member's current job type from WorkHistory
2. Joining that to CaseManagerAssignment to tag each assignment with a job type
3. Finding the most recent assignment per enrollment per job type

**What CaseWorthy doesn't do:** There's no single field that says "this person's case manager is _____." Instead, it's a multi-step lookup through assignments and work history. This is why views like `x_uvw_LatestUserByJobType` and `UVW_LatestCaseManager` exist — they pre-compute this chain so forms can reference the result directly.

---

## The Service Plan & Goal Chain

Service plans have their own hierarchy:

```
Enrollment
  └── EnrollmentServicePlan (the plan itself: phase, begin/end dates)
        └── ServicePlanGoals (links plans to goals)
              └── Goal (the individual goal: type, set date, percent complete)
                    └── GoalType (the goal category description)
```

The `X_UVW_MostRecentHousingStabilityPlan` view navigates this chain to find:
- The latest plan per enrollment (by `PlanBeginDate`)
- The latest goal under that plan (by `SetDate`)
- Days since each was last updated

**What CaseWorthy does with this data:** The `X_Phase` column on `EnrollmentServicePlan` tracks where a client is in their housing stability journey. The `PercentComplete` on `Goal` tracks progress. The view calculates `DaysSinceLastHousingStabilityPlan` and `DaysSinceLastGoalUpdate` so forms can flag stale plans that need attention.

---

## Audit Columns: The Repeated Pattern

Every CaseWorthy table includes the same set of audit columns:

```
CreatedBy          int       → FK to Users.EntityID (who created it)
CreatedDate        datetime  → when it was created
CreatedFormID      int       → which CaseWorthy form created it
LastModifiedBy     int       → who last edited it
LastModifiedDate   smalldatetime → when it was last edited
LastModifiedFormID int       → which form was used
DeletedBy          int       → who deleted it (if soft-deleted)
DeletedDate        date      → when it was deleted (NULL = active)
OwnedByOrgID       int       → which organization owns this record
OrgGroupID         int       → read-access org group
WriteOrgGroupID    int       → write-access org group
```

**What's useful about this:** `LastModifiedDate` is used in the referral view to estimate when a referral was closed (since there's no explicit close-date field). `CreatedDate` on `Files` is used as the document upload date. These audit fields are reliable timestamps even when the business-specific date fields are missing.

**What CaseWorthy doesn't do:** There's no built-in change history. `LastModifiedDate` tells you WHEN something changed but not WHAT changed. If someone edits a client's veteran status, you'll see the modification timestamp update, but you won't know what the previous value was. CaseWorthy does not maintain a field-level audit trail accessible through SQL.

---

## Naming Convention Summary

| Convention | Pattern | Examples |
|------------|---------|---------|
| Native tables | PascalCase, no prefix | `Client`, `Enrollment`, `Assessment`, `Family` |
| Custom tables | `X` prefix (inconsistent casing) | `XSVdPReferral`, `XAssessEntry`, `Xacuityscale` |
| Custom fields | `X_` prefix | `X_SOAR`, `X_Phase`, `X_ReferralStatus` |
| Custom views | `x_uvw_` or `X_UVW_` prefix | `x_uvw_LatestUserByJobType` |
| Native views | `UVW_` prefix | `UVW_DocumentFile`, `UVW_LatestCaseManager` |
| Extension tables | Named after what they extend | `EnrollmentHMIS`, `AssessHUDProgram`, `CaseNotesExtension` |
| HUD-specific tables | `AssessHUD` prefix | `AssessHUDProgram`, `AssessHUDUniversal` |

**The inconsistency:** Casing is not standardized across custom tables. You'll see `X_UVW_Latest90DayRecertWEnroll` (uppercase X_UVW) alongside `x_uvw_LatestUserByJobType` (lowercase x_uvw). Column names within custom tables also vary — `X_Whattypeofduringassessment` is lowercase-run-together while `X_ReferralStatus` is PascalCase. When writing SQL, always verify exact names from the schema reference.

---

## Key Takeaways for Learning SQL with CaseWorthy

### Things CaseWorthy does that help you learn

1. **Consistent CTE pattern** — Every view uses the same WITH/CTE → ROW_NUMBER → WHERE rn = 1 structure. Learn it once, read any view.

2. **Clear table separation** — Client data, enrollment data, assessment data, and service data are cleanly separated. You always know which table to go to.

3. **Extension table pattern** — The 1:1 extension model (Assessment → AssessHUDProgram, Enrollment → EnrollmentHMIS) is a real-world database design pattern you'll encounter everywhere.

4. **Real soft-delete implementation** — Understanding CaseWorthy's soft-delete pattern teaches you a production pattern used across the industry.

### Things CaseWorthy does that can trip you up

1. **Two soft-delete conventions** — NULL vs '12/31/9999' coexist. No way to predict which without checking.

2. **WorkHistory.ClientID means staff** — The naming breaks the convention every other table follows.

3. **Client → Enrollment requires two JOINs** — The EnrollmentMember intermediary is necessary for household enrollments but adds complexity to every query.

4. **No direct "case manager" field** — You need to chain through CaseManagerAssignment → Users → WorkHistory to get a case manager's name and job type.

5. **ListItem IDs everywhere** — Most dropdown values are stored as meaningless integers. You need the ListItem reference or a CASE statement to make them readable.

6. **Inconsistent naming** — Table prefixes, column casing, and abbreviations vary. Always verify against the schema.

### The five queries every CaseWorthy admin should know

1. **Active client list** — `SELECT FROM Client WHERE DeletedDate IS NULL`
2. **Client enrollment lookup** — Client → EnrollmentMember → Enrollment three-table JOIN
3. **Latest assessment per enrollment** — CTE with ROW_NUMBER PARTITION BY EnrollmentID
4. **Case manager for an enrollment** — CaseManagerAssignment → Users JOIN
5. **Document compliance check** — CROSS JOIN document types with LEFT JOIN to uploaded files

---

*This article is part of the SVDP CaseWorthy SQL documentation. For hands-on practice, see `SQL_30Day_Learning_Plan.md`. For reference, see `SQL_Guide_CaseWorthy.md` and `../Schema/CaseWorthy_Database_Schema_Reference.md`.*
