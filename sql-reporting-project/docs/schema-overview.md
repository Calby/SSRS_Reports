# Schema Overview

Reference document for the CaseWorthy (ClientTrack) and ServTracker databases.
Update this file when new tables, views, or relationships are confirmed.

Last updated: [YYYY-MM-DD]

---

## CaseWorthy (ClientTrack)

### Client & Demographics
```
Client
  ├── ClientID (PK)
  ├── FirstName, LastName, NameSuffix
  ├── SSN (partial/full)
  └── [other base fields]

ClientDemographic
  ├── ClientDemographicID (PK)
  ├── ClientID (FK → Client)
  ├── DateOfBirth
  ├── Gender, Race, Ethnicity
  ├── VeteranStatus
  └── DisablingCondition
```

### Enrollment & Program
```
Program
  ├── ProgramID (PK)
  ├── ProgramName
  ├── ProgramType        -- maps to HMIS program type (ES, TH, PSH, RRH, etc.)
  └── SiteID (FK → Site)

Enrollment
  ├── EnrollmentID (PK)
  ├── ClientID (FK → Client)
  ├── ProgramID (FK → Program)
  ├── EnrollmentDate
  ├── ExitDate           -- NULL if still active
  └── [other enrollment fields]

EnrollmentExit
  ├── ExitID (PK)
  ├── EnrollmentID (FK → Enrollment)
  ├── ExitDate
  ├── ExitDestination    -- HUD Element 3.12 coded value
  └── ExitReason
```

### Assessments
```
Assessment
  ├── AssessmentID (PK)
  ├── ClientID (FK → Client)
  ├── EnrollmentID (FK → Enrollment)
  ├── AssessmentType     -- Entry, Annual, Exit, Update
  ├── AssessmentDate
  └── CompletedByUserID

AssessmentQuestion
  ├── AssessmentQuestionID (PK)
  ├── AssessmentID (FK → Assessment)
  ├── QuestionCode       -- HMIS data element code
  └── ResponseValue

AssessmentSignOff
  ├── SignOffID (PK)
  ├── AssessmentID (FK → Assessment)
  ├── SignedOffByUserID
  ├── SignOffDate
  └── SignOffStatus
```

### Services
```
Services
  ├── ServiceID (PK)
  ├── ClientID (FK → Client)
  ├── EnrollmentID (FK → Enrollment)
  ├── ServiceTypeID (FK → ServiceType)
  ├── ServiceDate
  ├── Amount
  └── Units

ServiceType
  ├── ServiceTypeID (PK)
  └── ServiceTypeName
```

### Staff & Sites
```
AppUser
  ├── UserID (PK)
  ├── FirstName, LastName
  ├── Email
  └── SiteID (FK → Site)

Site
  ├── SiteID (PK)
  ├── SiteName
  └── [location fields]
```

---

## ServTracker

> ServTracker is a separate database for aging services programs (SRVTRK prefix).
> Schema structure differs from CaseWorthy. Cross-system integration is in progress.
> Update this section as you learn more about the ServTracker schema.

```
Participant             -- equivalent of Client in CaseWorthy
  ├── ParticipantID (PK)
  └── [demographic fields — confirm field names]

[Additional ServTracker tables — to be documented]
```

---

## Custom Views (x_uvw_)

All custom views follow the x_uvw_ naming convention. Source files are in queries/views/.

| View                               | Base Tables                          | Notes                          |
|------------------------------------|--------------------------------------|--------------------------------|
| x_uvw_ActiveEnrollmentsByProgram   | Enrollment, Program, Client          | Active and exited              |
| x_uvw_SSVFServiceSummary           | Services, Enrollment, ServiceType    | SSVF grant year logic          |
| x_uvw_AssessmentSignOffStatus      | Assessment, AssessmentSignOff, AppUser | Includes backlog flag         |
| x_uvw_GPDExitDestinations          | Enrollment, EnrollmentExit, Program  | GPD only                       |

---

## Notes on Base CaseWorthy Tables
- Do NOT modify base CaseWorthy tables or views (no x_ prefix)
- Always create new objects with the x_uvw_ or x_usp_ prefix
- CaseWorthy upgrades may alter base table structure — pin your custom views to
  stable columns and test after every system upgrade
