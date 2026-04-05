# Schema Overview

Reference document for the CaseWorthy (ClientTrack) and ServTracker databases.
Update this file when new tables, views, or relationships are confirmed.

Last updated: 2026-04-05

---

## CaseWorthy (ClientTrack)

### Core Concept: Everything Is an Entity

The `Entity` table is the root of CaseWorthy. Every person and organization —
clients, staff, providers — starts as an Entity with a universal `EntityID`.
Specialized tables extend it:

```
Entity (EntityID)
  ├── Client      (demographics, DOB, SSN, veteran status)
  ├── Users       (login, role, supervisor, active status)
  ├── Provider    (provider name, address)
  └── Organization (org name, structure)
```

**Key insight:** `ClientID` in most tables is actually an `EntityID`. Staff
members are also entities — `WorkHistory.ClientID` refers to the staff member,
not a client being served.

### Client & Demographics
```
Client
  ├── EntityID (PK — same as Entity.EntityID)
  ├── FirstName, LastName, NameSuffix
  ├── SSN (partial/full)
  ├── VeteranStatus
  ├── X_Office              -- custom SVDP field (ListItem → 1000000403)
  ├── X_ShallowSubsidyStatus
  ├── X_ReferredFromHUDVASH
  └── [audit columns: DeletedDate, CreatedDate, LastModifiedDate, etc.]

ClientDemographic
  ├── ClientDemographicID (PK)
  ├── ClientID (FK → Entity.EntityID)
  ├── DateOfBirth
  ├── Gender, Race, Ethnicity
  ├── VeteranStatus
  └── DisablingCondition
```

### Enrollment & Program

Clients connect to programs through a **three-table chain** that supports
household enrollments:
```
Client → EnrollmentMember → Enrollment → Program
```

```
Program
  ├── ProgramID (PK)
  ├── ProgramName
  ├── ProgramType        -- maps to HMIS program type (ES, TH, PSH, RRH, etc.)
  ├── OrganizationID
  └── SiteID (FK → Site)

Enrollment
  ├── EnrollmentID (PK)
  ├── ProgramID (FK → Program)
  ├── FamilyID            -- groups household members
  ├── BeginDate
  ├── EndDate             -- '12/31/9999' means still active (not NULL)
  ├── Status
  └── DeletedDate         -- '12/31/9999' = active

EnrollmentMember
  ├── EnrollmentID (FK → Enrollment)
  ├── ClientID (FK → Entity.EntityID)
  ├── BeginDate
  ├── EndDate             -- '9999-12-31' = active
  ├── RelationshipToHoH
  └── DeletedDate         -- NULL = active

EnrollmentHMIS
  ├── EnrollmentID (FK → Enrollment)
  ├── MoveInDate          -- NULL = not housed
  └── DeletedDate

EnrollmentExit
  ├── ExitID (PK)
  ├── EnrollmentID (FK → Enrollment)
  ├── ExitDate
  ├── ExitDestination    -- HUD Element 3.12 coded value
  └── ExitReason
```

### Assessments (Parent-Extension Pattern)

One core `Assessment` table with 1:1 extension tables for specific data:

```
Assessment
  ├── AssessmentID (PK)
  ├── ClientID (FK → Entity.EntityID)
  ├── EnrollmentID (FK → Enrollment)
  ├── AssessmentEvent    -- 1=Entry, 2=During/Update, 3=Exit
  ├── BeginAssessment
  └── DeletedDate        -- '12/31/9999' = active

Extension tables (join 1:1 on AssessmentID):
  ├── AssessHUDUniversal  (housing status, prior residence, chronic homelessness)
  ├── AssessHUDProgram    (exit destination, disabling condition, DV, SOAR)
  ├── XAssessEntry        (client type, referral source, VI-SPDAT, income)
  ├── Xacuityscale        (11-section acuity scoring)
  ├── XRiskAssess         (self-harm, safety)
  ├── XBarrierAssess      (barrier scoring)
  ├── XClientHousing      (housing preferences)
  └── XHouseholdBudget    (budget data)

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
  ├── ClientID (FK → Entity.EntityID)
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
Entity
  ├── EntityID (PK)
  └── EntityName            -- display name for any person/org

Users (extends Entity)
  ├── EntityID (PK/FK → Entity)
  ├── Login, Role, ActiveStatus
  └── SupervisorID

WorkHistory
  ├── ClientID (FK → Entity.EntityID)  -- "ClientID" here = the staff member
  ├── ProgramJobTypeID
  ├── BeginDate, EndDate
  └── DeletedDate           -- '12/31/9999' = active

CaseManagerAssignment
  ├── EnrollmentID
  ├── UserID (FK → Entity.EntityID)
  ├── BeginDate, EndDate
  └── DeletedDate           -- '12/31/9999' = active

Site
  ├── SiteID (PK)
  ├── SiteName
  └── [location fields]
```

### Dropdown Values: ListItem System

Most dropdown fields store an integer ID pointing to the `ListItem` table:

```
ListItemCategory
  ├── ListItemCategoryID (PK)
  └── CategoryName

ListItem
  ├── ListItemID (PK)
  ├── ListItemCategoryID (FK)
  ├── ListItemText
  └── SortOrder
```

See docs/caseworthy-listitem-reference.md for confirmed ListItem values.

### Soft-Delete Conventions

CaseWorthy never truly deletes data. Two conventions coexist:

| Convention               | Meaning        | Tables That Use It                                    |
|--------------------------|----------------|-------------------------------------------------------|
| `DeletedDate IS NULL`    | Active record  | Client, EnrollmentMember, XSVdPReferral, and others   |
| `DeletedDate = '12/31/9999'` | Active record  | Enrollment, Assessment, WorkHistory, CaseManagerAssignment |

**Every table in every query must include a soft-delete filter.** See
.claude/rules/schema-notes.md for join patterns with correct filters.

### Audit Columns (present on every table)

```
CreatedBy, CreatedDate, CreatedFormID
LastModifiedBy, LastModifiedDate, LastModifiedFormID
DeletedBy, DeletedDate
OwnedByOrgID, OrgGroupID, WriteOrgGroupID
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
