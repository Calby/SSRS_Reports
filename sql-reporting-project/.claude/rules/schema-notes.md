# Schema Notes — Key Tables & Join Patterns

> This file documents the tables most commonly used in report and view development.
> Update this file whenever you discover a new key table or join pattern.
> Last updated: 2026-04-05

---

## CaseWorthy (ClientTrack) Core Tables

### Entity (Root Table)
| Table            | What It Holds                                      |
|------------------|----------------------------------------------------|
| Entity           | Universal record for every person/org — EntityID is the system-wide PK |

**Key insight:** `ClientID` in most tables is an `EntityID`. Staff `UserID` is also
an `EntityID`. They share the same numbering system.

### Clients / Demographics
| Table            | What It Holds                                      |
|------------------|----------------------------------------------------|
| Client           | Extends Entity — EntityID is the PK (not "ClientID") |
| ClientDemographic | DOB, gender, race, ethnicity, veteran status       |

**Common join:** `Client c JOIN ClientDemographic d ON c.EntityID = d.ClientID`

---

### Enrollment / Program Activity
| Table            | What It Holds                                      |
|------------------|----------------------------------------------------|
| Enrollment       | One row per enrollment (household-level)            |
| EnrollmentMember | Links individual clients to enrollments (supports households) |
| EnrollmentHMIS   | HUD/HMIS fields (MoveInDate, etc.)                 |
| EnrollmentExit   | Exit information — joined to Enrollment on EnrollmentID |
| Program          | Program lookup table — ProgramID, ProgramName, ProgramType |

**Client → Enrollment requires TWO joins** (the EnrollmentMember intermediary
supports household enrollments where multiple clients share one Enrollment):
```sql
FROM Client c
INNER JOIN EnrollmentMember em ON em.ClientID = c.EntityID
INNER JOIN Enrollment e        ON e.EnrollmentID = em.EnrollmentID
```

**Active enrollment filter (CaseWorthy uses far-future dates, not NULL):**
```sql
WHERE em.EndDate = '9999-12-31'       -- active member
  AND em.DeletedDate IS NULL          -- not soft-deleted
  AND e.DeletedDate = '12/31/9999'    -- enrollment not soft-deleted
```

**Enrollment in date range (standard HMIS overlap logic):**
```sql
WHERE em.BeginDate <= @EndDate
  AND (em.EndDate = '9999-12-31' OR em.EndDate >= @StartDate)
```

---

### Assessments (Parent-Extension Pattern)
| Table               | What It Holds                                   |
|---------------------|-------------------------------------------------|
| Assessment          | Assessment header — AssessmentEvent: 1=Entry, 2=During, 3=Exit |
| AssessHUDUniversal  | HUD universal assessment data (housing, chronic homelessness) |
| AssessHUDProgram    | HUD program data (exit destination, SOAR, DV)   |
| XAssessEntry        | Custom entry/during data (VI-SPDAT, referral source) |
| Xacuityscale        | Acuity scoring (11 sections)                    |
| AssessmentSignOff   | Sign-off status and date per assessment         |

All extension tables join **1:1 on AssessmentID**.

**Assessment + extension join:**
```sql
FROM Assessment a
LEFT JOIN AssessHUDProgram ahp ON a.AssessmentID = ahp.AssessmentID
WHERE a.DeletedDate = '12/31/9999'
  AND a.AssessmentEvent = 1  -- Entry only (change as needed)
```

**Sign-off join:**
```sql
LEFT JOIN AssessmentSignOff aso ON a.AssessmentID = aso.AssessmentID
```

---

### Services
| Table      | What It Holds                                          |
|------------|--------------------------------------------------------|
| Services   | Individual service transactions — ServiceID, ClientID, Amount, ServiceDate |
| ServiceType | Lookup for service categories                         |

**Services in date range:**
```sql
WHERE s.ServiceDate BETWEEN @StartDate AND @EndDate
```

---

### Staff / Users / Case Manager Assignment
| Table                  | What It Holds                                         |
|------------------------|-------------------------------------------------------|
| Entity                 | Universal record — EntityName for display name         |
| Users                  | Staff login, role, supervisor (extends Entity)         |
| WorkHistory            | Staff job types — **ClientID here = the staff member** |
| CaseManagerAssignment  | Links staff to enrollments                             |

**Case manager lookup chain** (no single "case manager" field exists):
```
EnrollmentMember → CaseManagerAssignment (UserID = staff)
  → WorkHistory (ClientID = staff EntityID) → ProgramJobTypeID
```

Use `x_uvw_LatestUserByJobType` view to avoid re-building this chain.

---

### Offices / Sites
| Table  | What It Holds                              |
|--------|--------------------------------------------|
| Site   | Office/site lookup — SiteID, SiteName      |

SVDP has 17+ Florida offices + Puerto Rico. Always use SiteID for filtering,
not SiteName (names can vary in formatting).

---

## ServTracker Core Tables

> ServTracker is a separate database/system for aging services programs.
> It does not share a schema with CaseWorthy — queries must target the
> correct database context.

| Table               | What It Holds                                       |
|---------------------|-----------------------------------------------------|
| Participant         | Master record (equivalent of Client in CaseWorthy)  |
| Enrollment (SRVTRK) | Program enrollment — different schema than CW       |
| Services (SRVTRK)   | Service delivery records                            |

**Cross-database queries** (CaseWorthy + ServTracker):
Use fully qualified names: [DatabaseName].[schema].[TableName]
Integration between the two systems is an active ongoing project — flag any
cross-system joins for review before deploying.

---

## Soft-Delete Conventions

CaseWorthy never truly deletes data. Two conventions coexist — **you must check
which convention each table uses**:

| Convention                    | Meaning       | Tables                                                 |
|-------------------------------|---------------|--------------------------------------------------------|
| `DeletedDate IS NULL`         | Active record | Client, EnrollmentMember, XSVdPReferral, Program       |
| `DeletedDate = '12/31/9999'`  | Active record | Enrollment, Assessment, WorkHistory, CaseManagerAssignment |

**Every table in every join needs a soft-delete filter.** Miss one and deleted
records will silently inflate your counts.

---

## ListItem Lookup Pattern

Most dropdown fields store an integer ListItemID. Always include the
`ListItemCategoryID` guard to prevent cross-category collisions:

```sql
LEFT JOIN ListItem li
    ON field = li.ListItemID
    AND li.ListItemCategoryID = {confirmed ID}
```

See docs/caseworthy-listitem-reference.md for confirmed values.

---

## Common Join Patterns

### Client + Enrollment + Program (most common base)
```sql
FROM Client c
INNER JOIN EnrollmentMember em ON em.ClientID = c.EntityID
INNER JOIN Enrollment e        ON e.EnrollmentID = em.EnrollmentID
INNER JOIN Program p           ON e.ProgramID = p.ProgramID
LEFT JOIN  EnrollmentExit ex   ON e.EnrollmentID = ex.EnrollmentID
WHERE c.DeletedDate IS NULL
  AND em.DeletedDate IS NULL
  AND e.DeletedDate = '12/31/9999'
  AND p.DeletedDate IS NULL
```

### Assessment + Extension + Sign-Off
```sql
FROM Assessment a
LEFT JOIN AssessHUDProgram ahp   ON a.AssessmentID = ahp.AssessmentID
LEFT JOIN AssessmentSignOff aso  ON a.AssessmentID = aso.AssessmentID
WHERE a.DeletedDate = '12/31/9999'
```

### Services + Enrollment
```sql
FROM Services s
INNER JOIN Enrollment e ON s.EnrollmentID = e.EnrollmentID
WHERE e.DeletedDate = '12/31/9999'
```

### Assigned Staff (via custom view)
```sql
LEFT JOIN (
    SELECT ujt.ClientID, ujt.EnrollmentID,
           ent.EntityName AS CaseManager
    FROM x_uvw_LatestUserByJobType ujt
    INNER JOIN Entity ent ON ujt.UserID = ent.EntityID AND ent.DeletedDate IS NULL
    WHERE ujt.ProgramJobTypeID IN (122, 123, 205, 207, 213)
) lcm ON em.ClientID = lcm.ClientID AND em.EnrollmentID = lcm.EnrollmentID
```

---

## Key Custom Views (x_uvw_)

These are CaseWorthy-custom views with the x_uvw_ prefix. They pre-join
common table combinations and can be used as base tables in report queries.

| View                                  | Join Keys               | What It Returns                           |
|---------------------------------------|-------------------------|-------------------------------------------|
| x_uvw_LatestUserByJobType             | ClientID + EnrollmentID | Most recent staff by job type per enrollment |
| x_uvw_LatestCaseManager              | ClientID + EnrollmentID | Most recent case manager (any type)        |
| X_UVW_Latest90DayRecertWEnroll       | ClientID + EnrollmentID | Last recert date + DaysSinceLastRecert     |
| x_uvw_ActiveEnrollmentsByProgram     | EnrollmentID            | Active and exited enrollments              |
| x_uvw_AssessmentSignOffStatus        | AssessmentID            | Sign-off status with backlog flag          |

All custom views use the **CTE + ROW_NUMBER() + WHERE rn = 1** pattern to
return "latest record" results. Prefer joining to these over re-building
the same logic from scratch.

See docs/schema-overview.md for the full list of active custom views.
