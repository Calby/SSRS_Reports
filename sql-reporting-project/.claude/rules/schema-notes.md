# Schema Notes — Key Tables & Join Patterns

> This file documents the tables most commonly used in report and view development.
> Update this file whenever you discover a new key table or join pattern.
> Last updated: [YYYY-MM-DD]

---

## CaseWorthy (ClientTrack) Core Tables

### Clients / Demographics
| Table            | What It Holds                                      |
|------------------|----------------------------------------------------|
| Client           | Master client record — ClientID is the primary key |
| ClientDemographic | DOB, gender, race, ethnicity, veteran status       |

**Common join:** Client c JOIN ClientDemographic d ON c.ClientID = d.ClientID

---

### Enrollment / Program Activity
| Table            | What It Holds                                      |
|------------------|----------------------------------------------------|
| Enrollment       | One row per client per program enrollment          |
| EnrollmentExit   | Exit information — joined to Enrollment on EnrollmentID |
| Program          | Program lookup table — ProgramID, ProgramName, ProgramType |

**Active enrollment filter:**
```sql
WHERE e.ExitDate IS NULL
   OR e.ExitDate >= @StartDate
```

**Enrollment in date range (standard HMIS overlap logic):**
```sql
WHERE e.EnrollmentDate <= @EndDate
  AND (e.ExitDate IS NULL OR e.ExitDate >= @StartDate)
```

---

### Assessments
| Table               | What It Holds                                   |
|---------------------|-------------------------------------------------|
| Assessment          | Assessment header — one row per assessment event|
| AssessmentQuestion  | Individual question responses                   |
| AssessmentSignOff   | Sign-off status and date per assessment         |

**Sign-off join:**
```sql
JOIN AssessmentSignOff aso ON a.AssessmentID = aso.AssessmentID
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

### Staff / Users
| Table    | What It Holds                       |
|----------|-------------------------------------|
| AppUser  | Staff user accounts — UserID, Name  |
| UserRole | Role assignments per user           |

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

## Common Join Patterns

### Client + Enrollment + Program (most common base)
```sql
FROM Client c
INNER JOIN Enrollment e       ON c.ClientID = e.ClientID
INNER JOIN Program p          ON e.ProgramID = p.ProgramID
LEFT JOIN  EnrollmentExit ex  ON e.EnrollmentID = ex.EnrollmentID
```

### Assessment + Sign-Off
```sql
FROM Assessment a
LEFT JOIN AssessmentSignOff aso ON a.AssessmentID = aso.AssessmentID
```

### Services + Enrollment
```sql
FROM Services s
INNER JOIN Enrollment e ON s.EnrollmentID = e.EnrollmentID
```

---

## Notes on Custom Views (x_uvw_)
These are CaseWorthy-custom views with the x_uvw_ prefix. They pre-join
common table combinations and can be used as base tables in report queries.
See docs/schema-overview.md for the full list of active custom views.

When building report datasets, prefer joining to an existing x_uvw_ view
over re-writing the same base join logic from scratch.
