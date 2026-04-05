# CaseWorthy Database Conventions — SVDP CARES

## Active Record Filters

| Convention | Meaning | Usage |
|---|---|---|
| `DeletedDate IS NULL` | Record is active / not soft-deleted | Most tables |
| `EndDate = '9999-12-31'` | Enrollment or membership is currently open | EnrollmentMember, some assignment tables |
| `EndDate IS NULL` | Legacy — not used; do not filter on NULL | Avoid |

**Rule**: Always filter `DeletedDate IS NULL` on every table join. Always filter `EndDate = '9999-12-31'` for active enrollment members. Never assume NULL end date = active.

---

## Naming Conventions

| Prefix | Meaning |
|---|---|
| `X_` | Custom SVDP field on a standard CW table |
| `x_` (table) | Custom SVDP table |
| `x_uvw_` | Custom SVDP view |
| `vw_` | Standard CaseWorthy view |
| No prefix | Standard CaseWorthy table |

---

## Universal Identifiers

- `EntityID` — Universal person/org identifier used across all tables
- `ClientID` — Same as EntityID in most contexts; used in enrollment tables
- `EnrollmentID` — Unique per enrollment; used to join enrollment-scoped tables
- `AssessmentID` — Unique per assessment event

---

## Assessment Event Types

| Value | Meaning |
|---|---|
| 1 | Entry assessment |
| 2 | During / Update assessment |
| 3 | Exit assessment |

When pulling "entry" or "exit" data, always filter `AssessmentEvent = 1` or `= 3` respectively.

---

## ListItem / ListItemCategory System

All dropdown/lookup values are stored in `ListItem`, categorized by `ListItemCategory`.

```sql
-- Find a category by name
SELECT ListItemCategoryID, CategoryName
FROM ListItemCategory
WHERE CategoryName LIKE '%keyword%'

-- View all values in a category
SELECT ListItemID, ListItemText, SortOrder
FROM ListItem
WHERE ListItemCategoryID = {ID}
  AND DeletedDate IS NULL
ORDER BY SortOrder
```

**Always add `ListItemCategoryID` guard on joins** to prevent cross-category collisions:
```sql
LEFT JOIN ListItem li
    ON  field = li.ListItemID
    AND li.ListItemCategoryID = {confirmed ID}
```

### Confirmed List IDs

| ListItemCategoryID | List Name | Used For |
|---|---|---|
| 1000000403 | ClientOfficeList | Client.X_Office — office location |
| 37 | YesNoDontKnowWontAnswer | SOAR, HUD yes/no fields |

Values for YesNoDontKnowWontAnswer (ID 37):
- 1 = Yes
- 2 = No
- 3 = Client doesn't know
- 4 = Client Prefers Not to Answer
- 99 = Data Not Collected

### Office Locations (ClientOfficeList, ID 1000000403)

| ListItemID | Office |
|---|---|
| 1 | Lake Office |
| 2 | Citrus Office |
| 3 | Orlando Office |
| 4 | Lakeland Office |
| 5 | New Port Richey Office |
| 6 | Pasco-PSH |
| 7 | Sarasota Office |
| 8 | Sarasota-PSH |
| 9 | Tampa Office-SSVF |
| 10 | Tampa Office-Non Veteran |
| 11 | Clearwater Office SSVF |
| 12 | Clearwater Office-Non Veteran |
| 13 | Pinellas Center of Hope Office |
| 14 | Pinellas Care Center Shelter |
| 15 | Sebring Office |
| 16 | Port Charlotte Office |
| 17 | Port Charlotte Care Center Shelter |
| 18 | Fort Myers Office |
| 19 | San Juan Office |
| 99 | Admin |

---

## Key Tables

| Table | Purpose | Key Fields |
|---|---|---|
| `Client` | Core client record | EntityID, FirstName, LastName, X_Office, X_ShallowSubsidyStatus, X_ReferredFromHUDVASH, LastModifiedDate |
| `Enrollment` | Program enrollment header | EnrollmentID, ProgramID, OrganizationID |
| `EnrollmentMember` | Individual within an enrollment | EnrollmentID, ClientID, BeginDate, EndDate, DeletedDate |
| `EnrollmentHMIS` | HUD/HMIS fields for enrollment | EnrollmentID, MoveInDate |
| `Program` | Program definitions | ProgramID, ProgramName, OrganizationID |
| `Entity` | All persons/orgs | EntityID, EntityName |
| `ListItem` | All dropdown values | ListItemID, ListItemText, ListItemCategoryID |
| `ListItemCategory` | Dropdown categories | ListItemCategoryID, CategoryName |
| `AssessHUDProgram` | HUD program-level assessment fields | EnrollmentID, ClientID, AssessmentEvent, ConnectionWithSOAR |
| `XLegalServiceReferral` | Legal referral records | XLegalServiceReferralID, ClientID, EnrollmentID, X_ReferralStatus |

### Legal Referral Status Values (XLegalServiceReferral.X_ReferralStatus)

| Value | Label |
|---|---|
| 1 | Referred |
| 2 | Acknowledged (Pending Acceptance) |
| 3 | Accepted (Pending Approval) |
| **4** | **Approved** ← use this for "received legal assistance" |
| 5 | Turned Away |
| 7 | Ineligible |
| 8 | Client Turned Down Referral |
| 99 | Client Did Not Follow Up |

---

## Key Custom Views

| View | Purpose | Join Keys | Notable Columns |
|---|---|---|---|
| `x_uvw_LatestUserByJobType` | Most recent staff assignment by job type | ClientID + EnrollmentID | ProgramJobTypeID, UserID |
| `x_uvw_LatestCaseManager` | Most recent case manager (any type) | ClientID + EnrollmentID | UserID, CaseManager |
| `X_UVW_Latest90DayRecertWEnroll` | Most recent 90-day recertification per enrollment | ClientID + EnrollmentID | AssessmentDate, DaysSinceLastRecert |

### 90-Day Recert View Behavior
- `DaysSinceLastRecert` is a running integer counter starting at 0 when a recert is completed
- It increments daily and never resets until another recert assessment is completed
- Value of 700 = client has not had a recert in ~2 years
- `NULL` only occurs if no row exists in the view (no recert ever recorded for that enrollment)
- This view covers both active enrollments and exits — it is not named well; confirm scope with user

### ProgramJobTypeID Reference (Case Manager Types)

| ID | Title | Category |
|---|---|---|
| 122 | Case Manager | Case Manager |
| 123 | SOAR-Case Manager IV | Case Manager |
| 126 | Lead Navigator | COH/Care Center Operations |
| 130 | Navigator | COH/Care Center Operations |
| 163 | Healthcare Navigator | Healthcare/Suicide Prevention |
| 164 | Housing Locator | Housing |
| 165 | Housing Specialist | Housing |
| 181 | Peer Mentor | Peer & Outreach |
| 182 | Peer Mentor/Outreach II | Peer & Outreach |
| 183 | Rapid Resolution Specialist I | Rapid Resolution |
| 203 | Housing Navigator | Housing |
| 205 | Aftercare Coordinator | Healthcare/Suicide Prevention |
| 207 | SOAR Benefits Specialist | Case Manager |
| 213 | Case Manager IV | Case Manager |

**Default case manager filter for caseload reports**: `IN (122, 123, 205, 207, 213)`
Always confirm with user whether additional types apply for the specific report.

---

## Standard dsOfficeList Dataset

Include this in every report. Populates the @OfficeLocation parameter dropdown.

```sql
SELECT
    ListItemID   AS [Value],
    ListItemText AS [Label]
FROM ListItem
WHERE ListItemCategoryID = 1000000403
  AND DeletedDate IS NULL
ORDER BY SortOrder ASC;
```

In Report Builder: bind to @OfficeLocation parameter with Value = Value, Label = Label.
