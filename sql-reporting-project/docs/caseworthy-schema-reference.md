# CaseWorthy Database Schema Reference

**Organization:** St. Vincent de Paul CARES (Society of St Vincent de Paul South Pinellas, Inc.)  
**System:** CaseWorthy — Homeless Services Case Management  
**Last Updated:** February 23, 2026  
**Status:** Working reference — compiled from conversations, form exports, SQL views, and internal documentation. Not a complete database dump.

---

## Global Conventions

All CaseWorthy tables share common patterns:

| Pattern | Description |
|---------|-------------|
| `DeletedDate` | Soft-delete marker. `NULL` = active record. `12/31/9999` = NOT deleted (legacy convention). Filter with `WHERE DeletedDate IS NULL`. |
| `CreatedDate` | Timestamp when record was created |
| `LastModifiedDate` | Timestamp of most recent edit (any field change updates this) |
| `CreatedBy` / `LastModifiedBy` | User ID of who created/last edited the record |
| `EntityID` | Foreign key to the client/person entity (used across most tables) |
| `X_` prefix | Custom fields added by SVDP (not native CaseWorthy fields) |
| `x_uvw_` prefix | Custom SQL views created by SVDP |
| `vw_` prefix | Custom SQL views (alternate naming) |
| `ListItem` / `ListItemCategory` | Lookup tables that drive dropdown values system-wide |

---

## Core Tables

### Entity

The root-level identity record in CaseWorthy. Every person (client, staff, provider, organization) exists as an Entity first. `EntityID` is the universal identifier referenced across virtually all other tables.

| Column | Type | Description |
|--------|------|-------------|
| EntityID* | int (PK) | Universal person/entity identifier; referenced as FK throughout the system |
| EntityName | nvarchar | Display name for the entity (may be auto-generated from first/last name) |
| EntityTypeID* | tinyint | Type of entity (e.g., Client, Provider, Organization, User) |
| UniqueID | uniqueidentifier | System-generated GUID for the entity record |
| X_EnrollmentID | bit | Custom SVDP flag; likely indicates whether the entity has an associated enrollment |
| CreatedBy | int | FK → Users.EntityID |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form that created this record |
| LastModifiedBy | int | FK → Users.EntityID |
| LastModifiedDate | smalldatetime | Last modification timestamp |
| LastModifiedFormID | int | Form that last modified this record |
| DeletedBy | int | FK → Users.EntityID; populated on soft-delete |
| DeletedDate | date | Soft-delete date; NULL = active record |
| OwnedByOrgID | int | FK → Organization; owning organization |

**Key relationships:**
- Entity → Client (EntityID, 1:0..1 — not all entities are clients)
- Entity → Users (EntityID, 1:0..1 — not all entities are users)
- Entity → Provider (EntityID, 1:0..1)
- Entity is the parent identity for all person-type records in the system

---

### EntityUser

User-type entity records — shares identical schema with Entity. Likely a view or form-level accessor that filters Entity records to user-type entities (EntityTypeID for users). Used when the form builder context requires linking to a user entity specifically.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK — universal person/entity identifier |
| EntityName | nvarchar | Display name for the entity |
| EntityTypeID | tinyint | Type of entity (filtered to user type) |
| UniqueID | uniqueidentifier | System-generated GUID |
| X_EnrollmentID | bit | Custom SVDP flag |
| CreatedBy | int | FK → Users.EntityID |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form that created this record |
| LastModifiedBy | int | FK → Users.EntityID |
| LastModifiedDate | smalldatetime | Last modification timestamp |
| LastModifiedFormID | int | Form that last modified this record |
| DeletedBy | int | FK → Users.EntityID |
| DeletedDate | date | Soft-delete date (NULL = active) |
| OwnedByOrgID | int | FK → Organization |

**Key relationships:** EntityUser shares schema with Entity (EntityID) — same columns, scoped to user-type entities.

---

### Client

Stores demographic and personal information for clients. Joins 1:1 to Entity on `EntityID`. This is the primary table for client-level data including name, DOB, SSN, veteran status, race/ethnicity, and all HUD-required universal data elements. Custom SVDP fields track program-specific statuses and referral flags.

| Column | Type | Description |
|--------|------|-------------|
| EntityID* | int (PK, FK) | FK → Entity.EntityID; also serves as the primary key |
| FirstName* | nvarchar | Client first name (required) |
| MiddleName | nvarchar | Client middle name |
| LastName* | nvarchar | Client last name (required) |
| Suffix | int | FK → ListItem.ListItemID; name suffix dropdown (Jr., Sr., etc.) |
| BirthDate | date | Date of birth |
| DOBDataQuality | tinyint | HUD data quality flag for DOB (1=Full, 2=Approximate, 8=Don't Know, 9=Refused, 99=Not Collected) |
| SSN | varchar | Social Security Number (stored encrypted or masked) |
| SSNDataQuality | tinyint | HUD data quality flag for SSN |
| NameDataQuality | int | HUD data quality flag for name |
| Gender | int | FK → ListItem.ListItemID; gender identity |
| HMISSex | int | FK → ListItem.ListItemID; HMIS sex field (HUD Data Standards 2024+) |
| SexAtBirth | int | FK → ListItem.ListItemID; sex assigned at birth |
| Pronouns | int | FK → ListItem.ListItemID; preferred pronouns |
| DifferentIdentityText | nvarchar | Free-text field for gender identity not captured by dropdown |
| Race | int | FK → ListItem.ListItemID; primary race |
| AdditionalRaceEthnicity | nvarchar | Additional race/ethnicity detail beyond primary selection |
| Ethnicity | tinyint | HUD ethnicity value |
| VeteranStatus | tinyint | HUD veteran status (0=No, 1=Yes, 8=Don't Know, 9=Refused, 99=Not Collected) |
| CitizenshipStatusID | tinyint | Citizenship status identifier |
| MaritalStatus | int | FK → ListItem.ListItemID; marital status |
| PrimaryLanguage | int | FK → ListItem.ListItemID; primary spoken language |
| Bilingual | int | FK → ListItem.ListItemID; bilingual indicator |
| EnglishProficiency | int | FK → ListItem.ListItemID; English proficiency level |
| LimitedEnglishProficient | int | FK → ListItem.ListItemID; LEP flag |
| HomePhone | varchar | Home phone number |
| CellPhone | varchar | Cell phone number |
| WorkPhone | varchar | Work phone number |
| Email | varchar | Email address |
| IsContact | bit | Whether this client record is a contact/non-client |
| isCustody | bit | Custody-related flag |
| Restriction | int | Access restriction level for the client record |
| LegacyID | nvarchar | ID from a previous/legacy system |
| ScanCardID | nvarchar | Scan card or badge identifier |
| BadgeTemplateID | tinyint | Badge template selection for printing |
| X_Abilities | nvarchar | Custom SVDP: free-text field for client abilities/skills |
| X_ActiveDuty | int | FK → ListItem.ListItemID; custom SVDP: active duty military status |
| X_Alias | nvarchar | Custom SVDP: client alias or alternate name |
| X_GuardReserveStatus | int | Custom SVDP: National Guard/Reserve status |
| X_InterestSA | int | FK → ListItem.ListItemID; custom SVDP: interest in substance abuse services |
| X_LegacyID2 | nvarchar | Custom SVDP: secondary legacy system ID |
| X_LegacyID3 | int | Custom SVDP: tertiary legacy system ID |
| X_LegalServices | int | FK → ListItem.ListItemID; custom SVDP: legal services interest/status |
| X_Office | int | FK → ListItem.ListItemID; custom SVDP: assigned office location |
| X_ReferredFromHUDVASH | int | FK → ListItem.ListItemID; custom SVDP: whether client was referred from HUD-VASH |
| X_SecuredAccess | int | FK → ListItem.ListItemID; custom SVDP: secured access level |
| X_ShallowSubsidyStatus | int | FK → ListItem.ListItemID; custom SVDP: shallow subsidy program status |
| X_SOAR | int | FK → ListItem.ListItemID; custom SVDP: SSI/SSDI Outreach, Access, and Recovery status |
| X_TranslationAssistance | int | FK → ListItem.ListItemID; custom SVDP: translation assistance needed |
| X_VASHstatus | int | FK → ListItem.ListItemID; custom SVDP: HUD-VASH voucher status |
| CreatedBy | int | FK → Users.EntityID |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form that created this record |
| LastModifiedBy | int | FK → Users.EntityID |
| LastModifiedDate | smalldatetime | Last modification timestamp |
| LastModifiedFormID | int | Form that last modified this record |
| DeletedBy | int | FK → Users.EntityID; populated on soft-delete |
| DeletedDate | date | Soft-delete date; NULL = active record |
| OwnedByOrgID | int | FK → Organization; owning organization |
| OrgGroupID | int | Organization group identifier |
| WriteOrgGroupID | int | Write-access organization group |

**Key relationships:**
- Client → Entity (EntityID, 1:1 — every Client is an Entity)
- Client → Enrollment (via EnrollmentMember.ClientID, 1:many)
- Client → Assessment (ClientID → Assessment.ClientID, 1:many)
- Client → ListItem (multiple FK columns for dropdown values)

---

### ClientAddress

Client address records with date ranges for tracking address history.

| Column | Type | Description |
|--------|------|-------------|
| AddressID | int | Primary key |
| ClientID | int | FK → Client.EntityID |
| AddressType | tinyint | Address type (home, mailing, etc.) |
| Address1 | nvarchar | Street address line 1 |
| Address2 | nvarchar | Street address line 2 |
| AddressExt | nvarchar | Address extension |
| BuildingApartmentDesc | nvarchar | Building/apartment description |
| City | varchar | City |
| State | char | State (2-letter code) |
| ZipCode | char | ZIP code |
| County | nvarchar | County |
| Country | int | FK to ListItem — country |
| Neighborhood | nvarchar | Neighborhood |
| Latitude | float | GPS latitude |
| Longitude | float | GPS longitude |
| BeginDate | date | Address effective start date |
| EndDate | date | Address effective end date |
| FamilyID | int | FK → Family.FamilyID (for family addresses) |
| IsUpdateFamily | bit | Whether to update family address |
| ColoniasResident | int | Colonias resident indicator |
| RuralAreaStatus | int | Rural area status |
| X_CurrentLocationNotes | nvarchar | Current location notes |
| X_LocationNotes | nvarchar | Location notes |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| Restriction | tinyint | Access restriction level |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

---

### ClientSummaryInfo

Summary information for clients — pregnancy, employment, death, and special identifiers.

| Column | Type | Description |
|--------|------|-------------|
| ClientID | int | PK/FK → Client.EntityID |
| AlternateSystemID | nvarchar | Alternate system identifier |
| MedicaidID | nvarchar | Medicaid ID |
| MedicareID | nvarchar | Medicare ID |
| RSRUniqueClientID | nvarchar | RSR unique client ID |
| HVRPGrantID | varchar | HVRP grant ID |
| DateOfDeath | datetime | Date of death |
| PregnancyStatus | int | Pregnancy status |
| DueDate | datetime | Pregnancy due date |
| Employed | int | Employment status |
| InRehab | int | In rehabilitation |
| SexOffender | int | Sex offender status |
| SexualOrientation | int | Sexual orientation |
| VetStatus | int | Veteran status |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |

---

### EntityContactPreference

Contact preferences and additional contact methods for entities.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK/FK → Entity.EntityID |
| HomePhone | nvarchar | Home phone |
| HomePhoneExt | int | Home phone extension |
| HomePhoneType | int | Home phone type |
| CellPhone | nvarchar | Cell phone |
| CellPhoneExt | int | Cell phone extension |
| CellPhoneType | int | Cell phone type |
| WorkPhone | nvarchar | Work phone |
| WorkPhoneExt | int | Work phone extension |
| WorkPhoneType | int | Work phone type |
| OtherPhone | nvarchar | Other phone |
| EmergencyPhone | nvarchar | Emergency phone |
| EmergencyPhoneType | int | Emergency phone type |
| FaxNumber | nvarchar | Fax number |
| Email | nvarchar | Primary email |
| SecondEmail | nvarchar | Secondary email |
| MailingAddress | nvarchar | Mailing address |
| LinkedIn | nvarchar | LinkedIn profile |
| SkypeAccount | nvarchar | Skype account |
| PhoneVoiceOptIn | int | Phone voice opt-in |
| PhoneTextOptIn | int | Phone text opt-in |
| SecondaryPhoneVoiceOptIn | int | Secondary phone voice opt-in |
| SecondaryPhoneTextOptIn | int | Secondary phone text opt-in |
| EmailOptIn | int | Email opt-in |
| SnailMailOptIn | bit | Physical mail opt-in |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

---

### Family

Family/household records — groups clients together.

| Column | Type | Description |
|--------|------|-------------|
| FamilyID | int | Primary key |
| FamilyName | nvarchar | Family display name |
| FamilyPrimaryLang | int | FK to ListItem — primary language |
| LegacyID | varchar | ID from legacy system |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |

**Key relationships:**
- Family → FamilyMember (FamilyID)
- Family → Enrollment (FamilyID)

---

### FamilyMember

Links clients to families with relationship information.

| Column | Type | Description |
|--------|------|-------------|
| FamilyMemberID | int | Primary key |
| FamilyID | int | FK → Family.FamilyID |
| ClientID | int | FK → Client.EntityID |
| RelationToHoH | int | FK to ListItem — relationship to Head of Household |
| SpecifyRelationship | int | Specific relationship type |
| IsDependent | bit | Whether member is a dependent |
| ISLivingWithHhld | bit | Currently living with household |
| DateAdded | datetime | When member was added to family |
| DateRemoved | datetime | When member was removed from family |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- FamilyMember → Family (FamilyID)
- FamilyMember → Client (ClientID)

---

### Enrollment

Represents a client household's enrollment into a specific program at a specific organization. Tracks start/end dates, enrollment status, and program assignment. Individual household members are linked through `EnrollmentMember`. The `FamilyID` groups related enrollments for the same household.

| Column | Type | Description |
|--------|------|-------------|
| EnrollmentID* | int (PK) | Unique enrollment identifier |
| ProgramID* | int (FK) | FK → Program.ProgramID; the program the household is enrolled in |
| OrganizationID* | int | FK → Organization; the organization administering the enrollment |
| AccountID | int | Associated account identifier |
| FamilyID* | int (FK) | FK → Family; groups all enrollments for the same household unit |
| FamilyOrIndividual | int | Indicates whether this is a family or individual enrollment |
| BeginDate* | date | Enrollment start date (project entry date) |
| EndDate* | date | Enrollment end date; set to 12/31/9999 while active |
| ExitTimeStamp | date | Timestamp when the exit was processed |
| Status* | tinyint | Enrollment status (e.g., Active, Exited, Pending) |
| SubStatus | int | Sub-status for more granular tracking |
| DeniedReason | nvarchar | Reason for enrollment denial, if applicable |
| LegacyID | varchar | ID from a previous/legacy system |
| X_AcuityTotal | int | FK → ListItem.ListItemID; custom SVDP: total acuity score for prioritization |
| X_IsApproved | bit | Custom SVDP: whether the enrollment has been approved |
| X_OldProgramID | int | Custom SVDP: previous program ID (used for program transfers) |
| X_Xacuityquestionslivingsituation | int | FK → ListItem.ListItemID; custom SVDP: acuity question — living situation component |
| CreatedBy | int | FK → Users.EntityID |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form that created this record |
| LastModifiedBy | int | FK → Users.EntityID |
| LastModifiedDate | smalldatetime | Last modification timestamp |
| LastModifiedFormID | int | Form that last modified this record |
| DeletedBy | int | FK → Users.EntityID; populated on soft-delete |
| DeletedDate | date | Soft-delete date; NULL = active record |
| OwnedByOrgID | int | FK → Organization; owning organization |
| OrgGroupID | int | Organization group identifier |
| WriteOrgGroupID | int | Write-access organization group |

**Key relationships:**
- Enrollment → Program (ProgramID, many:1)
- Enrollment → Family (FamilyID, many:1)
- Enrollment → EnrollmentMember (EnrollmentID, 1:many — one row per household member)
- Enrollment → Assessment (EnrollmentID, 1:many)
- Enrollment → Organization (OrganizationID, many:1)

---

### EnrollmentMember

Links individual clients to a household enrollment. Each row represents one person's participation in an enrollment. Tracks individual begin/end dates, relationship to head of household, and exit details. A single Enrollment can have multiple EnrollmentMembers (one per household member).

| Column | Type | Description |
|--------|------|-------------|
| MemberID* | int (PK) | Unique enrollment member identifier |
| EnrollmentID* | int (FK) | FK → Enrollment.EnrollmentID; the parent enrollment |
| ClientID* | int (FK) | FK → Client.EntityID; the individual client |
| ProviderID* | int (FK) | FK → Provider.EntityID; the assigned provider/case manager |
| BeginDate* | date | Member's enrollment start date (may differ from household enrollment date) |
| EndDate* | date | Member's enrollment end date; set to 12/31/9999 while active |
| ExitTimeStamp | datetime | Timestamp when the member's exit was processed |
| ExitType | tinyint | Type of exit (e.g., completed, terminated, deceased) |
| ExitDaysDiff | int | Difference in days between member exit and enrollment exit |
| RelationToHoH | tinyint | Relationship to Head of Household (1=Self/HoH, 2=Spouse, 3=Child, etc.) |
| AuthorizationDate | datetime | Date the enrollment was authorized |
| AuthorizationReference | nvarchar | Authorization reference number or identifier |
| AssessmentsComplete | bit | Flag indicating whether all required assessments are complete (required, defaults) |
| AssessmentsCopiedFlag | bit | Flag indicating assessments were copied from another enrollment |
| Restriction* | int | Access restriction level for this member record |
| LegacyID | nvarchar | ID from a previous/legacy system |
| CreatedBy | int | FK → Users.EntityID |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form that created this record |
| LastModifiedBy | int | FK → Users.EntityID |
| LastModifiedDate | smalldatetime | Last modification timestamp |
| LastModifiedFormID | int | Form that last modified this record |
| DeletedBy | int | FK → Users.EntityID; populated on soft-delete |
| DeletedDate | date | Soft-delete date; NULL = active record |
| OwnedByOrgID | int | FK → Organization; owning organization |
| OrgGroupID | int | Organization group identifier |
| WriteOrgGroupID | int | Write-access organization group |

**Key relationships:**
- EnrollmentMember → Enrollment (EnrollmentID, many:1)
- EnrollmentMember → Client (ClientID → Entity.EntityID, many:1)
- EnrollmentMember → Provider (ProviderID → Entity.EntityID, many:1 — the assigned case manager)
- RelationToHoH = 1 identifies the Head of Household for HUD reporting purposes

---

### EnrollmentHMIS

Enrollment HMIS extension — stores HMIS-specific enrollment data including move-in date. Joins 1:1 to `Enrollment` on `EnrollmentID`.

| Column | Type | Description |
|--------|------|-------------|
| EnrollmentID | int | PK/FK to Enrollment.EnrollmentID |
| MoveInDate | date | HMIS move-in date for the enrollment |
| CreatedBy | int | User ID who created the record |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form used to create the record |
| LastModifiedBy | int | User ID who last modified the record |
| LastModifiedDate | datetime | Last modification timestamp |
| LastModifiedFormID | int | Form used for last modification |
| LegacyID | varchar | Legacy system identifier for data migration |

**Key relationships:** EnrollmentHMIS → Enrollment (EnrollmentID, 1:1)

---

### XEnrollmentReview

Enrollment review — PQI (Performance Quality Improvement) and peer review tracking for enrollments. Custom SVDP table for quality assurance workflows.

| Column | Type | Description |
|--------|------|-------------|
| XEnrollmentReviewID | int | PK, identity |
| EnrollmentID | int | FK to Enrollment.EnrollmentID (required) |
| X_NotifySM | int | Service manager notification flag |
| X_NotifySMName | nvarchar | Service manager name for notification |
| X_PeerReview | int | FK to ListItem.ListItemID — peer review status |
| X_PQIReview | int | FK to ListItem.ListItemID — PQI review status |
| X_PQIReviewed | bit | Whether PQI review has been completed |
| X_PQIReviewNote | nvarchar | PQI review notes/comments |
| X_ReviewPositionType | int | FK to ListItem.ListItemID — position type of reviewer |
| X_ReviewStatus | int | FK to ListItem.ListItemID — overall review status |
| X_ReviewType | int | FK to ListItem.ListItemID — type of review conducted |
| CreatedBy | int | User ID who created the record |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form used to create the record |
| DeletedBy | int | User ID who soft-deleted the record |
| DeletedDate | date | Soft-delete timestamp (NULL = active) |
| LastModifiedBy | int | User ID who last modified the record |
| LastModifiedDate | datetime | Last modification timestamp |
| LastModifiedFormID | int | Form used for last modification |
| OwnedByOrgID | int | Owning organization ID |

**Key relationships:** XEnrollmentReview → Enrollment (EnrollmentID, M:1), XEnrollmentReview → ListItem (X_PeerReview, X_PQIReview, X_ReviewPositionType, X_ReviewStatus, X_ReviewType)

---

### CaseManagerAssignment

Tracks case manager assignments to clients and enrollments.

| Column | Type | Description |
|--------|------|-------------|
| AssignmentID | int | Primary key |
| UserID | int | FK → Users.UserID (the case manager) |
| ClientID | int | FK → Client.EntityID |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| ContextTypeID | int | Context type for assignment |
| ContextID | int | Context ID reference |
| RelationshipID | int | Relationship type ID |
| ApprovalGroupID | int | Approval group reference |
| BeginDate | datetime | Assignment start date |
| EndDate | datetime | Assignment end date |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| Restriction | int | Access restriction level |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- CaseManagerAssignment → Users (UserID = case manager)
- CaseManagerAssignment → Client (ClientID)
- CaseManagerAssignment → Enrollment (EnrollmentID)

---

### Assessment

Records assessment events tied to an enrollment. Each assessment has an event type: Entry (1), During/Update (2), or Exit (3). Assessments serve as the parent record for all assessment extension tables (e.g., XBarrierAssess, XClientHousing, XIncome) which join 1:1 on `AssessmentID`. Custom SVDP fields support supervisor review workflows.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID* | int (PK) | Unique assessment identifier |
| EnrollmentID* | int (FK) | FK → Enrollment.EnrollmentID; the enrollment this assessment belongs to |
| ClientID* | int (FK) | FK → Client.EntityID; the client being assessed |
| AssessmentBy* | int (FK) | FK → Users.EntityID; the staff member who conducted the assessment |
| AssessmentEvent* | tinyint | Assessment event type: 1 = Entry, 2 = During/Update, 3 = Exit |
| BeginAssessment* | datetime | Assessment start date/time |
| EndAssessment* | datetime | Assessment end date/time |
| Restriction* | tinyint | Access restriction level for this assessment |
| LegacyID | varchar | ID from a previous/legacy system |
| X_FedProgPartID | int | Custom SVDP: federal program participation identifier |
| X_IsSupApproved | bit | Custom SVDP: whether the assessment has been supervisor-approved |
| X_NotifySM | int | Custom SVDP: notify service manager flag/identifier |
| X_NotifySMName | nvarchar | Custom SVDP: name of the service manager to notify |
| X_ReviewStatus | int | FK → ListItem.ListItemID; custom SVDP: supervisor review status (e.g., Pending, Approved, Returned) |
| X_TypeOfDuringAssessment | int | Custom SVDP: sub-type for During assessments (e.g., 90-day recertification, annual) |
| CreatedBy | int | FK → Users.EntityID |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form that created this record |
| LastModifiedBy | int | FK → Users.EntityID |
| LastModifiedDate | smalldatetime | Last modification timestamp |
| LastModifiedFormID | int | Form that last modified this record |
| DeletedBy | int | FK → Users.EntityID; populated on soft-delete |
| DeletedDate | date | Soft-delete date; NULL = active record |
| OwnedByOrgID | int | FK → Organization; owning organization |
| OrgGroupID | int | Organization group identifier |
| WriteOrgGroupID | int | Write-access organization group |

**Key relationships:**
- Assessment → Enrollment (EnrollmentID, many:1)
- Assessment → Client (ClientID → Entity.EntityID, many:1)
- Assessment → Users (AssessmentBy → Users.EntityID, many:1)
- Assessment → XBarrierAssess (AssessmentID, 1:0..1 — extension table)
- Assessment → XClientHousing (AssessmentID, 1:0..1 — extension table)
- Assessment → XIncome (AssessmentID, 1:0..1 — extension table)
- Assessment → XVeteranInfo (AssessmentID, 1:0..1 — extension table)
- AssessmentEvent values: 1 = Entry, 2 = During/Update, 3 = Exit

---

### XAssessEntry

Extended assessment entry data — stores SVDP-specific fields collected at enrollment entry assessments. Captures client type classification, literal homelessness status, referral source, VI-SPDAT scores, housing assessment flags, pet/service animal details, income verification and self-certification, and during-assessment type. One record per assessment.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_ClientType | int | Client Classification — FK to ListItem — client type (e.g., individual, family) |
| X_LiterallyHomeless | int | Client Classification — FK to ListItem — literally homeless indicator |
| X_HOHReferralSource | int | Referral — FK to ListItem — head of household referral source |
| X_HOHReferralSourceOther | nvarchar | Referral — other referral source text |
| X_ReferralToSpecProg | int | Referral — FK to ListItem — referral to special program |
| X_TargetReferralProg | int | Referral — FK to ListItem — target referral program |
| X_TargetReferralLoc | int | Referral — FK to ListItem — target referral location |
| X_HasVISPDAT | int | VI-SPDAT — FK to ListItem — has VI-SPDAT on file |
| X_IndividualVISPDATScore | int | VI-SPDAT — individual VI-SPDAT score |
| X_FamilyVISPDATScore | int | VI-SPDAT — family VI-SPDAT score |
| X_CompleteUpdatehousingassessmentsatthistime | int | Housing — FK to ListItem — complete/update housing assessments at this time |
| X_NameofShelterHotel | int | Housing — FK to ListItem — shelter/hotel name (list-driven) |
| X_NameShelterHotel | nvarchar | Housing — shelter/hotel name text (free-form) |
| X_PetOrServiceAnimal | int | Pet/SA — FK to ListItem — has pet or service animal |
| X_TypeOfPetOrSA | int | Pet/SA — FK to ListItem — type of pet or service animal |
| X_PetTypeOther | nvarchar | Pet/SA — other pet type text |
| X_HowMenyPet | int | Pet/SA — number of pets |
| X_HowMenySA | int | Pet/SA — number of service animals |
| X_HowMenyOther | int | Pet/SA — number of other animals |
| X_ProjectedRoomMatNumber | int | Housing — projected roommate number |
| X_RoomMatNumber | nvarchar | Housing — roommate number text |
| X_ClientCertifyIncome | bit | Income Verification — client certifies income |
| X_ClientCertifyNoIncome | bit | Income Verification — client certifies no income |
| X_IncomeVerificationorDeclarationType | int | Income Verification — FK to ListItem — income verification/declaration type |
| X_AddEligibilityIncomeSource | int | Income Verification — FK to ListItem — additional eligibility income source |
| X_IncomeVerificationorDeclarationType20 | int | Income Verification — FK to ListItem — secondary income verification type |
| X_AddEligibilityIncomeSource20 | int | Income Verification — FK to ListItem — secondary eligibility income source |
| X_SelfCertificationQ1 | int | Self-Certification — FK to ListItem — self-cert question 1 |
| X_SelfCertificationQ2 | int | Self-Certification — FK to ListItem — self-cert question 2 |
| X_SelfCertificationQ3 | nvarchar | Self-Certification — self-cert question 3 response (free text) |
| X_SelfOnlyICertify | int | Self-Certification — self-only "I certify" acknowledgment |
| X_StaffCertification | bit | Certification — staff certification completed |
| X_StaffICertifyUpload3rdParty | int | Certification — staff certify with 3rd party document upload |
| X_VerbalConsent | bit | Certification — verbal consent obtained |
| X_Whattypeofduringassessment | int | Assessment Type — FK to ListItem — what type of during assessment. Join condition: `InList([1,3,4,5], 'XAssessEntry.X_Whattypeofduringassessment')` |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XAssessEntry → Assessment (AssessmentID, 1:1); all int FK fields → ListItem.ListItemID

---

### XCompletedSSVFSurvey

SSVF satisfaction survey completion tracking — records whether the SSVF (Supportive Services for Veteran Families) satisfaction survey was completed for a given assessment, with a link to the survey and an explanation field if the survey was not completed.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_SSVFSatisfactionSurvey | int | Survey — FK to ListItem — survey completion status |
| X_SSVFsatisfactionSurveyLINK | int | Survey — link/reference to satisfaction survey |
| X_IfNoSSVFsatisfactionSurveyExplanation | nvarchar | Survey — explanation if survey was not completed |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XCompletedSSVFSurvey → Assessment (AssessmentID, 1:1); X_SSVFSatisfactionSurvey → ListItem.ListItemID

---

### Xacuityscale

Acuity assessment scoring — tracks client acuity levels across multiple life domains for case management prioritization. The tool scores 11 sections (living situation, basic needs, family, transportation, financial, mental health, physical health, substance use, legal, language, domestic violence) plus additional modifiers (distance, household/SO, minor dependents). Section subtotals roll up into a composite acuity total that determines acuity level (Low/Medium/High/Very High). All domain score fields store ListItemID values that map to scored responses.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_1Total | int | Section Subtotals — section 1 subtotal score |
| X_2Total | int | Section Subtotals — section 2 subtotal score |
| X_3Total | int | Section Subtotals — section 3 subtotal score |
| X_4Total | int | Section Subtotals — section 4 subtotal score |
| X_5Total | int | Section Subtotals — section 5 subtotal score |
| X_6Total | int | Section Subtotals — section 6 subtotal score |
| X_7Total | int | Section Subtotals — section 7 subtotal score |
| X_8Total | int | Section Subtotals — section 8 subtotal score |
| X_9Total | int | Section Subtotals — section 9 subtotal score |
| X_10Total | int | Section Subtotals — section 10 subtotal score |
| X_11Total | int | Section Subtotals — section 11 subtotal score |
| X_acuityquestionslivingsituation | int | Domain Scores — FK to ListItem — living situation score |
| X_acuityquestionsbasicneeds | int | Domain Scores — FK to ListItem — basic needs score |
| X_acuityquestionsFamily | int | Domain Scores — FK to ListItem — family score |
| X_acuityquestionstransportation | int | Domain Scores — FK to ListItem — transportation score |
| X_acuityfinancial | int | Domain Scores — FK to ListItem — financial score |
| X_acuitymental | int | Domain Scores — FK to ListItem — mental health score |
| X_acuityphysicalhealth | int | Domain Scores — FK to ListItem — physical health score |
| X_acuitysubstanceuse | int | Domain Scores — FK to ListItem — substance use score |
| X_acuitylegal | int | Domain Scores — FK to ListItem — legal issues score |
| X_acuitylanguage | int | Domain Scores — FK to ListItem — language barriers score |
| X_acuitydomesticviolence | int | Domain Scores — FK to ListItem — domestic violence score |
| X_acuity_distance | int | Domain Scores — FK to ListItem — distance/geography score |
| X_acuity_hh_SO | int | Domain Scores — FK to ListItem — household/significant other score |
| X_acuity_minor_dependents | int | Domain Scores — FK to ListItem — minor dependents score |
| X_AcuityTotal | int | Summary — FK to ListItem — total acuity score |
| X_AcuityTotalold | int | Summary — previous total acuity score (before recalculation) |
| X_AcuityLevel | nvarchar | Summary — acuity level text (Low/Medium/High/Very High) |
| X_LMHVHTotal | int | Summary — FK to ListItem — Low/Medium/High/Very High total |
| X_IFYESTotal | int | Summary — IF YES total (crisis modifier sum) |
| X_IfYesThenYes | int | Summary — FK to ListItem — if yes then yes indicator |
| X_IfYesThenCrisis | int | Summary — FK to ListItem — if yes then crisis indicator |
| X_SVDPAssessmentStatus | int | Summary — FK to ListItem — SVDP assessment status |
| X_AcuityButton | nvarchar | UI Control — acuity calculation button state |
| X_SSButton | nvarchar | UI Control — SS calculation button state |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** Xacuityscale → Assessment (AssessmentID, 1:1); all domain score int fields → ListItem.ListItemID

---

### XCMAssessTool

Case Management Assessment Tool — comprehensive client assessment tracking benefits, safety, and functional domains.

| Column | Type | Description |
|--------|------|-------------|
| XCMAssessToolID | int | Primary key |
| ClientID | int | FK → Client.EntityID |
| X_EnrollmentID | int | FK → Enrollment.EnrollmentID |
| **Benefits/Resources** | | |
| X_SSI | int | FK to ListItem — SSI status |
| X_SSD | int | FK to ListItem — SSD status |
| X_SSA | int | FK to ListItem — SSA status |
| X_TANF | int | FK to ListItem — TANF status |
| X_ChildSupp | int | FK to ListItem — child support status |
| X_VetBenefit | int | FK to ListItem — veteran benefits status |
| X_Retire | int | FK to ListItem — retirement benefits |
| X_OtherEcoResource | int | FK to ListItem — other economic resources |
| X_Medicaid | int | FK to ListItem — Medicaid status |
| X_Medicare | int | FK to ListItem — Medicare status |
| X_PrivInsur | int | FK to ListItem — private insurance status |
| **Substance Use** | | |
| X_Alcohol | int | FK to ListItem — alcohol use |
| X_Drugs | int | FK to ListItem — drug use |
| X_Tobacco | int | FK to ListItem — tobacco use |
| X_Treatment | int | FK to ListItem — treatment status |
| **Safety Assessment** | | |
| X_Safe | int | FK to ListItem — safety status |
| X_SafetyAdd | int | FK to ListItem — additional safety concerns |
| X_Violence | int | FK to ListItem — violence exposure |
| X_ViolenceDate | date | Violence incident date |
| X_Harming | int | FK to ListItem — harming self/others |
| X_HarmingExplain | nvarchar | Harming explanation |
| X_HarmingPlan | int | FK to ListItem — harming plan |
| X_Hopeful | int | FK to ListItem — hopefulness level |
| X_Fear | int | FK to ListItem — fear level |
| X_FearExplain | nvarchar | Fear explanation |
| **Domain Notes** | | |
| X_Housing | nvarchar | Housing notes |
| X_Financial | nvarchar | Financial notes |
| X_Legal | nvarchar | Legal notes |
| X_Medical | nvarchar | Medical notes |
| X_MentalHealth | nvarchar | Mental health notes |
| X_SubAbuse | nvarchar | Substance abuse notes |
| X_OtherSub | nvarchar | Other substance notes |
| X_EmpVoc | nvarchar | Employment/vocational notes |
| X_BasicEduSkills | nvarchar | Basic education skills notes |
| X_DailyLiving | nvarchar | Daily living notes |
| X_Social | nvarchar | Social notes |
| X_DVS | nvarchar | Domestic violence services notes |
| X_Language | nvarchar | Language notes |
| X_Leisure | nvarchar | Leisure notes |
| X_Mobility | nvarchar | Mobility notes |
| X_RepPhoneNumber | nvarchar | Representative phone number |
| Restriction | int | Access restriction level |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- XCMAssessTool → Client (ClientID)
- XCMAssessTool → Enrollment (X_EnrollmentID)

---

### XRiskAssess

Risk assessment — safety screening and crisis intervention documentation. Captures yes/no indicators and narrative explanations for feeling unsafe, self-harm risk, trauma history, and hopelessness. Includes safety plan fields for documenting protective actions, support people, and danger descriptions. Used by case managers for crisis screening during assessments.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_YesNoFeelUnsafe | int | Safety Screening — FK to ListItem — feels unsafe (yes/no) |
| X_FeelUnsafe | nvarchar | Safety Screening — feels unsafe narrative explanation |
| X_YesNoSelfHarm | int | Safety Screening — FK to ListItem — self-harm risk (yes/no) |
| X_SelfHarm | nvarchar | Safety Screening — self-harm risk narrative explanation |
| X_YesNoTrauma | int | Safety Screening — FK to ListItem — trauma history (yes/no) |
| X_Trauma | nvarchar | Safety Screening — trauma history narrative explanation |
| X_YesNoHope | int | Safety Screening — FK to ListItem — hopelessness indicator (yes/no) |
| X_Hope | nvarchar | Safety Screening — hopelessness narrative explanation |
| X_DangerDescription | nvarchar | Safety Plan — description of danger/threat |
| X_Safety | nvarchar | Safety Plan — safety plan details |
| X_SafetyActions | nvarchar | Safety Plan — safety actions to take |
| X_WhoSafetyActions | nvarchar | Safety Plan — who will help execute safety actions |
| X_WhoCanHelp | nvarchar | Safety Plan — who can help in crisis |
| X_Narrative | nvarchar | Summary — risk assessment narrative |
| X_Rec | nvarchar | Summary — recommendations |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XRiskAssess → Assessment (AssessmentID, 1:1); yes/no int fields → ListItem.ListItemID

---

### XAssessExit

Exit assessment extension — captures exit disposition, program destination, office-specific program referrals, and pre-enrollment exit reasons. Used when clients exit or are transferred between SVDP programs. Office-specific program fields correspond to the various SVDP regional offices across Florida, allowing tracking of internal transfers by location.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_Disposition | int | Exit Disposition — FK to ListItem — exit disposition |
| X_PreEnrollmentExitDestination | int | Exit Disposition — FK to ListItem — pre-enrollment exit destination |
| X_PreEnrollmentExitReason | int | Exit Disposition — FK to ListItem — pre-enrollment exit reason |
| X_ProgramEligibilityDetermination | int | Exit Disposition — FK to ListItem — program eligibility determination |
| X_ReasonNotEligiblePreEnrollment | int | Exit Disposition — FK to ListItem — reason not eligible at pre-enrollment |
| X_ReasonNotEligiblePreEnrollmentOther | nvarchar | Exit Disposition — other reason not eligible text |
| X_DiversionDestinations | int | Exit Disposition — FK to ListItem — diversion destinations |
| X_ExternalReferralDestination | int | Exit Disposition — FK to ListItem — external referral destination |
| X_OtherExternalReferral | nvarchar | Exit Disposition — other external referral text |
| X_InternalReferralAndEnrollment | int | Internal Transfer — internal referral and enrollment flag |
| X_OfficeDestination | int | Internal Transfer — destination office identifier |
| X_ProgramDestination | int | Internal Transfer — FK to ListItem — primary program destination |
| X_SecondProgram | int | Internal Transfer — FK to ListItem — second program destination |
| X_ThirdProgram | int | Internal Transfer — FK to ListItem — third program destination |
| X_2ProgramDestination | int | Internal Transfer — second program destination (raw ID) |
| X_3ProgramDestination | int | Internal Transfer — third program destination (raw ID) |
| X_StPeteSSVFRRHPrograms | int | Office Programs — FK to ListItem — St. Pete SSVF/RRH programs |
| X_TampaOfficePrograms | int | Office Programs — FK to ListItem — Tampa office programs |
| X_ClearwaterOfficePrograms | int | Office Programs — FK to ListItem — Clearwater office programs |
| X_LakelandOfficePrograms | int | Office Programs — FK to ListItem — Lakeland office programs |
| X_SarasotaOfficePrograms | int | Office Programs — FK to ListItem — Sarasota office programs |
| X_FortMyersOfficePrograms | int | Office Programs — FK to ListItem — Fort Myers office programs |
| X_NewPortRicheyOfficePrograms | int | Office Programs — FK to ListItem — New Port Richey office programs |
| X_SebringOfficePrograms | int | Office Programs — FK to ListItem — Sebring office programs |
| X_InvernessOfficePrograms | int | Office Programs — FK to ListItem — Inverness office programs |
| X_COHCARECenterPrograms | int | Office Programs — FK to ListItem — COH CARE Center programs |
| X_BriefSum | nvarchar | Narrative — brief exit summary |
| X_HOHReferralSourceOther | varchar | Narrative — other HoH referral source text |
| X_NotifySM | int | Notification — notify service manager flag |
| X_NotifySMName | nvarchar | Notification — service manager name to notify |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XAssessExit → Assessment (AssessmentID, 1:1); all int FK fields → ListItem.ListItemID

---

### XAssessmentReview

Assessment Review — supervisor review notes for assessments.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_SMReviewNote | nvarchar | Service manager review notes |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |

**Key relationships:** XAssessmentReview → Assessment (AssessmentID, 1:1)

---

### WorkHistory

Employment and work history tracking — used for both client employment history and staff job assignments.

| Column | Type | Description |
|--------|------|-------------|
| WorkHistoryID | int | Primary key |
| ClientID | int | FK → Entity.EntityID |
| EmployerID | int | FK → Provider (employer) |
| EmployerContact | int | Employer contact reference |
| **Employment Details** | | |
| JobTitle | nvarchar | Job title |
| EmploymentTypeID | int | Employment type |
| EmploymentTypeOther | int | Other employment type |
| BeginDate | date | Employment start date |
| EndDate | date | Employment end date |
| **Pay Information** | | |
| PaymentRate | money | Payment rate |
| PaymentIntervalID | int | Payment interval |
| PaymentTypeID | int | Payment type |
| PayRate | money | Pay rate |
| EndPaymentRate | money | End payment rate |
| EndPaymentIntervalID | int | End payment interval |
| YearlySalary | money | Yearly salary |
| AvgHoursPerWeek | money | Average hours per week |
| HealthBenefits | bit | Has health benefits |
| WorkerPaysBenefits | bit | Worker pays benefits |
| **Classification** | | |
| NAICSTypeID | int | NAICS industry code |
| ONETID | int | O*NET occupation code |
| SICTypeID | int | SIC code |
| SOCTypeID | int | SOC code |
| Qualifications | int | Qualifications |
| **Program/Placement** | | |
| ProgramJobTypeID | int | Links to job type within program |
| ProgramFundingPercent | int | Program funding percentage |
| Placement | bit | Is a placement |
| PlacementBy | int | Placed by |
| PlacementDate | date | Placement date |
| PlacementVerificationMethod | tinyint | Placement verification method |
| ProviderID | int | FK → Provider.EntityID |
| **Exit Information** | | |
| ExitReasonID | int | Exit reason |
| TerminationReasonID | int | Termination reason |
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| X_HomeSageDepartment | int | FK to ListItem — home Sage department |
| Restriction | tinyint | Access restriction level |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- WorkHistory → Entity (ClientID)
- WorkHistory → Provider (EmployerID, ProviderID)
- WorkHistory → CaseNotes (CaseNoteID)

---

### Users

Stores user account information for CaseWorthy staff/administrators. Joins 1:1 to Entity on `EntityID`. Contains authentication credentials, role assignments, login tracking, feature access flags, and supervisor relationships. Custom SVDP fields track staff training dates and program-specific assignments.

| Column | Type | Description |
|--------|------|-------------|
| EntityID* | int (PK, FK) | FK → Entity.EntityID; also serves as the primary key |
| UserName* | varchar | Login username (unique) |
| Password | binary | Hashed password (binary storage) |
| UserTypeID* | tinyint | User type classification |
| FirstName | nvarchar | User's first name (display) |
| MiddleName | varchar | User's middle name |
| LastName | nvarchar | User's last name (display) |
| EmailAddress | nvarchar | User's email address |
| CellPhone | varchar | Cell phone number |
| OfficePhone | varchar | Office phone number |
| PhoneExt | varchar | Phone extension |
| GmailAccount | varchar | Gmail account for calendar integration |
| GmailPassword | nvarchar | Gmail password (encrypted) for calendar sync |
| isActive* | bit | Whether the user account is active |
| isSupervisor | bit | Whether the user is a supervisor |
| SupervisorUserID | int | FK → Users.EntityID; the user's direct supervisor |
| DefaultRoleID* | int (FK) | FK → RoleDefinition; the user's default security role |
| RoleID | int | Alternate/current role assignment |
| DefaultOrganizationID* | int | FK → Organization; user's default organization |
| OrganizationID | int | Current/alternate organization assignment |
| DefaultProviderID* | int | FK → Provider.EntityID; user's default provider |
| ProviderID | int | Current/alternate provider assignment |
| DefaultPortalRoleID | int | Default role for portal access |
| PortalRoleID | int | Current portal role |
| IsPortalFullAccess | bit | Full portal access flag |
| IsPortalJobClubAccess | bit | Portal Job Club access flag |
| PortalTermsAccepted | bit | Whether user accepted portal terms of service |
| AccountLockOut* | bit | Whether the account is currently locked |
| LoginFailedCount* | tinyint | Number of consecutive failed login attempts |
| LastLoginDate | smalldatetime | Timestamp of the user's most recent login |
| LastFailedLoginDate | smalldatetime | Timestamp of the last failed login attempt |
| IsChangePW | bit | Whether the user must change password on next login |
| IsTwoFactAccess* | bit | Whether two-factor authentication is enabled |
| MFAState | nvarchar | Multi-factor authentication state/configuration |
| OTP | nvarchar | One-time password value (temporary) |
| PassToken | nvarchar | Password reset token |
| UserToken | nvarchar | Session/authentication token |
| SecurityQuestion | nvarchar | Security question for account recovery |
| SecurityAnswer | nvarchar | Security answer (encrypted) |
| Auth0UserID | nvarchar | Auth0 integration user identifier |
| AllowExcel* | bit | Whether the user can export data to Excel |
| AllowPrint* | bit | Whether the user can print reports |
| EnableTimeLogging* | bit | Whether time logging is enabled for this user |
| SyncToOutlook* | bit | Whether calendar syncs to Outlook |
| GoogleCalendarLastSync | datetime | Last Google Calendar sync timestamp |
| DisclaimerAcceptedDate | date | Date the user accepted the system disclaimer |
| EmploymentStartDate | date | Staff employment start date |
| EmploymentEndDate | date | Staff employment end date |
| AltReferenceID | varchar | Alternate reference/employee ID |
| AnnualSalesGoal | money | Annual sales/performance goal (workforce module) |
| ActivityNotification | bit | Whether activity notifications are enabled |
| EntityRelated | int | Related entity identifier |
| IsJobClubGroupBan | bit | Whether the user is banned from Job Club groups |
| TimeZonePreferenceID | int | User's preferred time zone |
| LegacyID | varchar | ID from a previous/legacy system |
| X_DatabindJobType | int | FK → ListItem.ListItemID; custom SVDP: job type for data binding |
| X_EUADate | date | Custom SVDP: Enterprise User Agreement acceptance date |
| X_FinanceStaff | int | FK → ListItem.ListItemID; custom SVDP: finance staff designation |
| X_SSVF | int | FK → ListItem.ListItemID; custom SVDP: SSVF program assignment |
| X_TrainedDate | date | Custom SVDP: date the user completed CaseWorthy training |
| CreatedBy | int | FK → Users.EntityID |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form that created this record |
| LastModifiedBy | int | FK → Users.EntityID |
| LastModifiedDate | smalldatetime | Last modification timestamp |
| LastModifiedFormID | int | Form that last modified this record |
| DeletedBy | int | FK → Users.EntityID; populated on soft-delete |
| DeletedDate | date | Soft-delete date; NULL = active record |
| OwnedByOrgID | int | FK → Organization; owning organization |
| OrgGroupID | int | Organization group identifier |
| WriteOrgGroupID | int | Write-access organization group |

**Key relationships:**
- Users → Entity (EntityID, 1:1 — every User is an Entity)
- Users → RoleDefinition (DefaultRoleID, many:1)
- Users → Organization (DefaultOrganizationID, many:1)
- Users → Provider (DefaultProviderID, many:1)
- Users → Users (SupervisorUserID → EntityID, many:1 — self-referencing supervisor hierarchy)
- Users → WorkHistory (WorkHistory.ClientID = Users.EntityID — note: WorkHistory.ClientID refers to staff, not clients)
- Users → Assessment (Assessment.AssessmentBy → Users.EntityID, 1:many)
- Users → ListItem (X_DatabindJobType, X_FinanceStaff, X_SSVF — dropdown values)

---

### ApprovalGroup

Defines approval groups used for case manager assignment workflows and organizational hierarchy. Groups can function as communication hubs and control account modification permissions.

| Column | Type | Description |
|--------|------|-------------|
| ApprovalGroupID | int | Primary key |
| GroupName | nvarchar | Name of the approval group |
| GroupType | tinyint | Type of group |
| BeginDate | datetime | When the group became active |
| EndDate | datetime | When the group was deactivated |
| IsCommHub | bit | Whether group serves as a communication hub |
| ISModifyAccount | bit | Whether group can modify accounts |
| PhoneNumber | nvarchar | Contact phone number for the group |
| OrgGroupID | int | Organization group scope |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker (NULL = active) |
| WriteOrgGroupID | int | Write-access organization group |

**Key relationships:** CaseManagerAssignment.ApprovalGroupID → ApprovalGroup.ApprovalGroupID

---

## HUD Program Data Tables

### Program

Defines a program within CaseWorthy (e.g., SSVF, GPD, RRH, PSH, EHA). Contains program configuration including enrollment rules, auto-exit settings, workflow assignments, and assessment scheduling. Each Enrollment references a Program. Workflow IDs link to the form workflows triggered at entry, during, and exit assessment events.

| Column | Type | Description |
|--------|------|-------------|
| ProgramID* | int (PK) | Unique program identifier |
| ProgramName* | nvarchar | Display name for the program (e.g., "SSVF - Rapid Re-Housing") |
| ProgramDetail | varchar | Additional program description or detail text |
| BeginDate | date | Program effective start date |
| EndDate | datetime | Program end date; NULL or far-future if still active |
| EnrollmentsEnabled* | bit | Whether new enrollments are allowed for this program |
| EnrollmentStatusOverride | int | Override value for enrollment status logic |
| FamilyOrIndividual | int | Whether the program serves families, individuals, or both |
| FamilyAMIMethod | int | Method used to calculate Area Median Income for families |
| DoNotAutoEnroll | bit | Flag to prevent automatic enrollment |
| IsExitEnroll | bit | Whether the program supports exit-to-enrollment transfers |
| EligibleRuleID | int | FK → eligibility rule configuration |
| IsCalcFieldsInEligibility | bit | Whether calculated fields are used in eligibility determination |
| FinalApprovalOptions | int | Configuration for final enrollment approval workflow |
| DuringFamilyWorkflowID | int | FK → Workflow; workflow triggered for family During assessments |
| DuringIndividualWorkflowID | int | FK → Workflow; workflow triggered for individual During assessments |
| ExitFamilyWorkflowID | int | FK → Workflow; workflow triggered for family Exit assessments |
| ExitIndividualWorkflowID | int | FK → Workflow; workflow triggered for individual Exit assessments |
| AutoExitDays* | int | Number of days after which the system auto-exits inactive clients |
| AutoExitCaseManager | int | FK → Users.EntityID; case manager assigned on auto-exit |
| AutoExitFollowUp | int | Follow-up configuration for auto-exit events |
| NotifyOnAutoExit | int | Notification setting when auto-exit occurs |
| EmailBeforeDays | int | Days before auto-exit to send a warning email |
| MaxDays | int | Maximum enrollment duration in days |
| MinDays | int | Minimum enrollment duration in days |
| ReopenDays* | int | Number of days within which an exited enrollment can be reopened |
| PostExitAssessment | int | Whether post-exit assessments are configured |
| PostExitDays | int | Days after exit to schedule post-exit assessment |
| PostExitTimes | int | Number of post-exit assessment cycles |
| SerReq | bit | Whether service requirements are enforced for this program |
| ServiceMethod | int | Method of service delivery configuration |
| LegacyID | varchar | ID from a previous/legacy system |
| CreatedBy | int | FK → Users.EntityID |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form that created this record |
| LastModifiedBy | int | FK → Users.EntityID |
| LastModifiedDate | smalldatetime | Last modification timestamp |
| LastModifiedFormID | int | Form that last modified this record |
| DeletedBy | int | FK → Users.EntityID; populated on soft-delete |
| DeletedDate | date | Soft-delete date; NULL = active record |
| OwnedByOrgID | int | FK → Organization; owning organization |
| OrgGroupID | int | Organization group identifier |
| WriteOrgGroupID | int | Write-access organization group |

**Key relationships:**
- Program → Enrollment (ProgramID, 1:many)
- Program → Organization (OwnedByOrgID, many:1)
- Program → Workflow (DuringFamilyWorkflowID, DuringIndividualWorkflowID, ExitFamilyWorkflowID, ExitIndividualWorkflowID — many:1 each)
- Program → Users (AutoExitCaseManager, many:1)

---

### ProgramHMIS

HMIS-specific program configuration — stores HUD program type, bed inventory, and coverage settings.

| Column | Type | Description |
|--------|------|-------------|
| ProgramID | int | PK/FK → Program.ProgramID |
| ProgramIdentifier | nvarchar | HMIS program identifier |
| ProgramType | int | HUD program type code |
| HMISParticipationBeginDate | date | HMIS participation start date |
| HMISParticipationEndDate | date | HMIS participation end date |
| HMISCoverageType | int | HMIS coverage type |
| HMISCoverageStartDate | date | HMIS coverage start date |
| HMISCoveredBeds | int | Number of HMIS-covered beds |
| BedInventory | int | Total bed inventory |
| UnitInventory | int | Total unit inventory |
| InventoryStartDate | date | Inventory start date |
| InventoryTypeCode | int | Inventory type code |
| SiteInformation | int | Site information |
| OccupancyModel | int | Occupancy model |
| HousingType | int | Housing type |
| HousingStatusException | int | Housing status exception |
| TargetPopulationA | int | Target population A |
| TargetPopulationB | int | Target population B |
| VictimServicesProvider | int | Victim services provider flag |
| ParticipatesInHMIS | bit | Participates in HMIS |
| RRHSubtype | int | RRH subtype |
| CEProgram | int | Coordinated entry program |
| ContinuumProject | int | Continuum project |
| DirectServiceCode | bit | Direct service code |
| MedicalAsstFacility | int | Medical assistance facility |
| SSOResidentialAffiliation | int | SSO residential affiliation |
| PATHType | tinyint | PATH program type |
| HPRPType | int | HPRP type |
| HOPWAType | int | HOPWA type |
| ExcludeAMICalculations | int | Exclude from AMI calculations |
| HideExtraVetFields | int | Hide extra veteran fields |
| AssessmentTypeDV | nvarchar | DV assessment type |
| AssessmentLevelDV | nvarchar | DV assessment level |
| AssessmentLocationDV | nvarchar | DV assessment location |
| PrioritizationStatusDV | nvarchar | DV prioritization status |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |

**Key relationships:** ProgramHMIS → Program (ProgramID, 1:1)

---

### Account

Financial accounts/grants — tracks funding sources for programs.

| Column | Type | Description |
|--------|------|-------------|
| AccountID | int | Primary key |
| AccountName | nvarchar | Account display name |
| FunderName | nvarchar | Funder name |
| FederalPartnerComponentID | int | Federal partner component |
| FiscalYearStart | date | Fiscal year start date |
| FiscalYearEnd | datetime | Fiscal year end date |
| FiscalYearTotal | money | Total fiscal year amount |
| FiscalCalendarID | int | Fiscal calendar reference |
| Status | int | Account status |
| Address1 | nvarchar | Address line 1 |
| Address2 | nvarchar | Address line 2 |
| City | varchar | City |
| State | char | State |
| ZipCode | char | ZIP code |
| DisbursementMethod | tinyint | Disbursement method |
| WriteChecksAs | nvarchar | Check payee name |
| BankID | int | FK to Bank |
| DefaultProviderID | int | Default provider |
| RequireDefaultProvider | bit | Require default provider |
| OnlyAllowObligations | bit | Only allow obligations |
| OnlyPayOtherID | int | Only pay other ID |
| BelowZero | int | Allow below zero |
| HCSAttribute | int | HCS attribute |
| IsSerReqReduce | bit | Service requirement reduction |
| ConsilidateType | tinyint | Consolidation type |
| ObligationProcessID | int | Obligation process |
| AutoAssignAccountProcess | int | Auto-assign account process |
| X_isAdmin | bit | Is admin account |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- Account → ProgramAccount (AccountID)
- Account → Enrollment (AccountID)

---

### ProgramAccount

Links programs to funding accounts.

| Column | Type | Description |
|--------|------|-------------|
| ProgramAccountID | int | Primary key |
| ProgramID | int | FK → Program.ProgramID |
| AccountID | int | FK → Account.AccountID |
| ReferenceID | nvarchar | Reference identifier |
| StartDate | date | Account link start date |
| EndDate | date | Account link end date |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- ProgramAccount → Program (ProgramID)
- ProgramAccount → Account (AccountID)

---

### XProgramSVDPAddOns

SVDP-specific program settings — custom configuration for SVDP programs.

| Column | Type | Description |
|--------|------|-------------|
| XProgramSVDPAddOnsID | int | Primary key |
| ProgramID | int | FK → Program.ProgramID |
| X_Requires90DayRecertification | int | FK to ListItem — requires 90-day recert |
| X_IsEHA | int | FK to ListItem — is EHA program |
| X_EHA | int | FK to ListItem — EHA setting |
| X_IsExitW2 | int | FK to ListItem — exit with W2 |
| X_SkipHSP | int | FK to ListItem — skip housing stability plan |
| X_SkipSnap | int | FK to ListItem — skip SNAP assessment |
| X_CreditCardEmail | int | FK to ListItem — credit card email setting |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** XProgramSVDPAddOns → Program (ProgramID)

---

### programTypeCategory

Junction table linking programs to HUD program type categories.

| Column | Type | Description |
|--------|------|-------------|
| programTypeCategoryID | int | Primary key |
| programID | int | FK → Program.ProgramID |
| programTypeCategoryTypeID | int | FK to program type category |

**Note:** Used to determine which HUD program type rules apply (e.g., Type 4 = PSH, Type 15 = RRH).

---

### AssessHUDProgram

HUD program-specific assessment data — stores HUD data elements collected at entry, update, and exit assessments. This is one of the largest extension tables, covering demographics, employment, disability/health conditions, housing status, veteran information, education, domestic violence, financial indicators, child/family data, criminal justice history, coordinated entry screening, and subsidy tracking. Fields are organized below by logical domain.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| AddressDataQuality | int | Demographics — address data quality indicator |
| AddressID | int | Demographics — FK to Address table |
| MaritalStatusID | tinyint | Demographics — FK to ListItem — marital status |
| PreferredLanguage | int | Demographics — FK to ListItem — preferred language |
| TranslationAssistanceNeeded | int | Demographics — translation assistance required |
| SexualOrientation | int | Demographics — FK to ListItem — sexual orientation |
| Farmer | tinyint | Demographics — is farmer |
| Employed | tinyint | Employment — currently employed |
| EmploymentType | int | Employment — FK to ListItem — type of employment |
| EmploymentTenure | tinyint | Employment — length of current employment |
| HoursWorkedLastWk | tinyint | Employment — hours worked last week |
| LookingForWork | tinyint | Employment — actively looking for work |
| WhyNotEmployed | int | Employment — FK to ListItem — reason not employed |
| ChronicIllness | int | Disability/Health — has chronic health condition |
| ChronicIllnessContinue | int | Disability/Health — chronic illness is ongoing |
| ChronicIllnessDocument | int | Disability/Health — chronic illness documented |
| ChronicIllnessServices | int | Disability/Health — receiving chronic illness services |
| DevelopmentalDisabled | int | Disability/Health — has developmental disability |
| DevelopmentalDisabledContinue | int | Disability/Health — developmental disability ongoing |
| DevelopmentalDisabledDocument | int | Disability/Health — developmental disability documented |
| DevelopmentalDisabledServices | int | Disability/Health — receiving DD services |
| DisabilityAffectsHousing | int | Disability/Health — disability affects housing stability |
| GeneralHealthStatus | tinyint | Disability/Health — general health status rating |
| HealthInsurance | int | Disability/Health — has health insurance |
| HIVAIDS | int | Disability/Health — has HIV/AIDS |
| HIVAIDSContinue | int | Disability/Health — HIV/AIDS ongoing |
| HIVAIDSDocument | int | Disability/Health — HIV/AIDS documented |
| HIVAIDSServices | int | Disability/Health — receiving HIV/AIDS services |
| ISHomeBound | bit | Disability/Health — client is homebound |
| MentalIllness | int | Disability/Health — has mental illness |
| MentalIllnessConfirmed | int | Disability/Health — mental illness confirmed by provider |
| MentalIllnessContinue | int | Disability/Health — mental illness ongoing |
| MentalIllnessDocument | int | Disability/Health — mental illness documented |
| MentalIllnessServices | int | Disability/Health — receiving mental health services |
| MentalIllnessSMI | int | Disability/Health — serious mental illness indicator |
| MHConsult | int | Disability/Health — mental health consultation completed |
| PhysicalDisability | int | Disability/Health — has physical disability |
| PhysicalDisabilityContinue | int | Disability/Health — physical disability ongoing |
| PhysicalDisabilityDocument | int | Disability/Health — physical disability documented |
| PhysicalDisabilityServices | int | Disability/Health — receiving physical disability services |
| ReasonNoHealthInsurance | int | Disability/Health — reason for no health insurance |
| SubstanceAbuse | int | Disability/Health — has substance abuse issue |
| SubstanceAbuseConfirmed | int | Disability/Health — substance abuse confirmed |
| SubstanceAbuseContinue | int | Disability/Health — substance abuse ongoing |
| SubstanceAbuseDocument | int | Disability/Health — substance abuse documented |
| SubstanceAbuseServices | int | Disability/Health — receiving substance abuse services |
| ERVisits | int | Disability/Health — number of ER visits |
| NightsinMedFacility | int | Disability/Health — nights spent in medical facility |
| AnxietyFrequency | int | Disability/Health — anxiety frequency indicator |
| HousingStatus | int | Housing — current housing status |
| LiteralHomelessHistory | int | Housing — literal homeless history |
| SSVFHomelessHistory | int | Housing — SSVF homeless history |
| WorstHousingSituation | int | Housing — worst housing situation experienced |
| HousingLossExpected | int | Housing — expected housing loss |
| PermanentHousing | int | Housing — currently in permanent housing |
| ClientisLeaseholder | int | Housing — client is the leaseholder |
| HoHLeaseholder | int | Housing — head of household is leaseholder |
| MoveInDate | date | Housing — date client moved in |
| ExitDestination | int | Housing — FK to ListItem — exit destination |
| HousingAssessmentAtExit | int | Housing — housing assessment completed at exit |
| HousingAssessmentDisposition | int | Housing — housing assessment disposition |
| HouseholdChange | int | Housing — household composition change indicator |
| HouseholdFivePlus | int | Housing — household has 5+ members |
| RentalByClient | int | Housing — rental paid by client |
| RentalEvictions | int | Housing — number of rental evictions |
| RiskLosingSubsidy | int | Housing — at risk of losing subsidy |
| SubsidyInfoNewHousing | int | Housing — subsidy info for new housing |
| SubsidyInfoSameHousing | int | Housing — subsidy info for same housing |
| VoucherTracking | int | Housing — voucher tracking status |
| Veteran | tinyint | Veteran — veteran status |
| VetBranch | tinyint | Veteran — military branch of service |
| VetDischargeStatus | tinyint | Veteran — discharge status |
| VetDuration | int | Veteran — duration of military service |
| VetServiceEra | tinyint | Veteran — service era |
| VetServedWarZone | tinyint | Veteran — served in a war zone |
| VetWarZoneName | tinyint | Veteran — war zone name |
| VetNumMonthsWarZone | tinyint | Veteran — months spent in war zone |
| VetReceivedFire | tinyint | Veteran — received hostile fire |
| VetServedIraqAfg | int | Veteran — served in Iraq/Afghanistan |
| FemaleVet | int | Veteran — female veteran indicator |
| VAMCStationNo | varchar | Veteran — VAMC station number |
| VAPercentAMI | int | Veteran — VA percent of AMI |
| CurrentEdStatus | int | Education — current education status |
| MostRecentEdStatus | int | Education — most recent education status |
| CurrentSchoolAttend | int | Education — currently attending school |
| EduInSchool | tinyint | Education — in school indicator |
| EduHighestGrade | tinyint | Education — highest grade completed |
| EduVocational | tinyint | Education — vocational education |
| EduCollegeLevel | tinyint | Education — college level attained |
| DomesticViolence | tinyint | DV — domestic violence victim status |
| DVWhen | tinyint | DV — when domestic violence occurred |
| FleeingDV | int | DV — currently fleeing domestic violence |
| IncomeZero | int | Financial — zero income indicator |
| IncomeZeroToFourteen | int | Financial — income 0–14% AMI |
| SuddenIncomeDecrease | int | Financial — sudden income decrease |
| NonCashBenefit | tinyint | Financial — receives non-cash benefits |
| ConnectionWithSOAR | int | Financial — connected with SOAR |
| SupportFromOthers | int | Financial — receives support from others |
| ChildEnrollment | tinyint | Child/Family — child enrollment status |
| ChildEnrollProblem | tinyint | Child/Family — child enrollment problem |
| ChildLastEnrollDate | date | Child/Family — child last enrolled date |
| ChildMCV | tinyint | Child/Family — child MCV status |
| ChildSchoolName | nvarchar | Child/Family — child's school name |
| ChildSchoolType | tinyint | Child/Family — child's school type |
| DependentsUnderSix | int | Child/Family — number of dependents under 6 |
| SingleParent | int | Child/Family — single parent indicator |
| MemberCurrentlyPregnant | int | Child/Family — household member currently pregnant |
| PregnancyStatus | tinyint | Child/Family — pregnancy status |
| PregnancyDueDate | date | Child/Family — pregnancy due date |
| CriminalRecord | int | Criminal Justice — has criminal record |
| SexOffender | int | Criminal Justice — sex offender status |
| IncarceratedAsAdult | int | Criminal Justice — incarcerated as adult |
| DischargedfromJail | int | Criminal Justice — discharged from jail |
| NightsinJail | int | Criminal Justice — nights spent in jail |
| ReferredbyCoordEntry | int | HP Screening/Coord Entry — referred by coordinated entry |
| CoCPrioritized | int | HP Screening/Coord Entry — CoC prioritized |
| GranteeThresholdScore | int | HP Screening/Coord Entry — grantee threshold score |
| HPScreenerReq | int | HP Screening/Coord Entry — HP screener required |
| HPScreeningScore | tinyint | HP Screening/Coord Entry — HP screening score |
| HPTotalPoints | int | HP Screening/Coord Entry — HP total points |
| BounceBack | int | Other — bounce-back indicator |
| CMExitReason | int | Other — case manager exit reason |
| ExpelledReason | int | Other — reason expelled from program |
| LifeHasValue | int | Other — life has value indicator |
| ReasonForLeaving | tinyint | Other — reason for leaving |
| LegacyID | varchar | Other — ID from legacy system |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | smalldatetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |
| LastModifiedBy | int | Audit — FK → Users.UserID |
| LastModifiedDate | smalldatetime | Audit — last edit timestamp |
| LastModifiedFormID | int | Audit — form used for last modification |
| DeletedBy | int | Audit — FK → Users.UserID |
| DeletedDate | date | Audit — soft-delete marker (NULL = active) |

**Key relationships:** AssessHUDProgram → Assessment (AssessmentID, 1:1); AddressID → Address; int FK fields → ListItem.ListItemID

---

### AssessHUDProgramOtherInfo

Stores "Other" text responses for AssessHUDProgram fields.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| CMExitReasonOther | nvarchar | Other CM exit reason text |
| ExitDestinationOther | nvarchar | Other exit destination text |
| HousingAssessmentDispositionOther | nvarchar | Other housing disposition text |
| LanguageOther | nvarchar | Other language text |
| NonCashBenefitOther | nvarchar | Other non-cash benefit text |
| SexualOrientationOther | nvarchar | Other sexual orientation text |
| VoucherTrackingOther | nvarchar | Other voucher tracking text |

**Key relationships:** AssessHUDProgramOtherInfo → Assessment (AssessmentID, 1:1)

---

### AssessHUDUniversal

HUD Universal Data Elements — captures housing status, chronic homelessness indicators, prior residence, disabling conditions, health insurance, HIV status, veteran status, and outreach contact information. Required for all HUD-funded program assessments.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| HousingStatus | tinyint | Housing History — current housing status |
| PriorResidence | int | Housing History — FK to ListItem — prior residence type |
| PriorZipCode | char | Housing History — prior ZIP code |
| ZipCodeQuality | int | Housing History — ZIP code data quality indicator |
| LengthOfStay | tinyint | Housing History — length of stay at prior residence |
| DateStartedOnStreets | date | Housing History — date first started on streets |
| Institution90Days | int | Housing History — in institution 90+ days before entry |
| TransPermHousing7nights | int | Housing History — transitional/perm housing less than 7 nights |
| EnteringFromStreets | int | Housing History — entering directly from streets |
| RentalByClient | int | Housing History — rental paid by client |
| ChronicallyHomeless | int | Chronic Homelessness — chronically homeless status |
| ContinouslyHomeless | int | Chronic Homelessness — continuously homeless indicator |
| MonthsContinuouslyHmlss | tinyint | Chronic Homelessness — months continuously homeless |
| HmlssEpisodes3Years | int | Chronic Homelessness — homeless episodes in past 3 years |
| HmlssMonths3Years | int | Chronic Homelessness — total homeless months in past 3 years |
| HmlssStatusDocument | int | Chronic Homelessness — homeless status documentation type |
| DisablingCondition | tinyint | Disabling Condition — has a disabling condition |
| DisCondOriginalStatus | int | Disabling Condition — original disabling condition status |
| DisablingConditionServices | int | Disabling Condition — currently receiving services |
| ReceivedDisablingConditionServices | int | Disabling Condition — has received services in past |
| HealthInsurance | tinyint | Health — health insurance status |
| HIVAIDSStatus | int | Health — HIV/AIDS status |
| HIVServices | int | Health — currently receiving HIV services |
| ReceivedHIVServices | int | Health — has received HIV services in past |
| VeteranStatus | tinyint | Other — veteran status indicator |
| ClientLocation | int | Other — FK → Provider.EntityID — client location provider |
| ClientLocationDate | date | Other — date of client location record |
| LocationOfContact | int | Other — location of outreach contact |
| DatetimeOfContact | datetime | Other — date/time of outreach contact |
| OutreachEngagementDate | date | Other — outreach engagement date |
| LegacyID | varchar | Other — ID from legacy system |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | smalldatetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |
| LastModifiedBy | int | Audit — FK → Users.UserID |
| LastModifiedDate | smalldatetime | Audit — last edit timestamp |
| LastModifiedFormID | int | Audit — form used for last modification |
| DeletedBy | int | Audit — FK → Users.UserID |
| DeletedDate | date | Audit — soft-delete marker (NULL = active) |

**Key relationships:** AssessHUDUniversal → Assessment (AssessmentID, 1:1); ClientLocation → Provider (EntityID)

---

### AssessHUDUniversalOtherInfo

Stores "Other" text responses for AssessHUDUniversal fields.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| PriorResidenceOther | nvarchar | Other prior residence text |

**Key relationships:** AssessHUDUniversalOtherInfo → Assessment (AssessmentID, 1:1)

---

### AssessHealthInsurance

Health insurance types recorded per assessment — allows multiple insurance types per client.

| Column | Type | Description |
|--------|------|-------------|
| AssessHealthInsuranceID | int | Primary key |
| AssessmentID | int | FK → Assessment.AssessmentID |
| InsuranceTypeID | int | FK → List_Insurance_Types.ListItemID |
| Results | int | Insurance results/status |
| NoReason | int | Reason for no insurance |
| LegacyID | varchar | ID from legacy system |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- AssessHealthInsurance → Assessment (AssessmentID)
- AssessHealthInsurance → List_Insurance_Types (InsuranceTypeID)

---

### AssessHealthInsuranceOtherInfo

Stores "Other" text for health insurance when "Other" type is selected.

| Column | Type | Description |
|--------|------|-------------|
| AssessHealthInsuranceID | int | PK/FK → AssessHealthInsurance.AssessHealthInsuranceID |
| HealthInsuranceOther | nvarchar | Other insurance type text |

---

### AssessFinancialItem

Financial line items per assessment — tracks income sources, assets, and expenses.

| Column | Type | Description |
|--------|------|-------------|
| FinancialItemID | int | Primary key |
| AssessmentID | int | FK → Assessment.AssessmentID |
| FinancialItemTypeID | int | FK → FinancialType.FinancialTypeID |
| Amount | money | Total amount |
| Interval | int | Payment interval |
| IntervalAmount | money | Amount per interval |
| IntervalsPerMonth | money | Intervals per month |
| TransactionType | int | Transaction type |
| FinancialTypeOther | nvarchar | Other financial type description |
| X_CashValue | money | Cash value (for assets) |
| X_ActualAssetIncome | money | Actual asset income |
| X_InterestRate | money | Interest rate |
| X_Passbook | money | Passbook rate |
| X_Fees | money | Fees |
| X_OtherAsset | nvarchar | Other asset description |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- AssessFinancialItem → Assessment (AssessmentID)
- AssessFinancialItem → FinancialType (FinancialItemTypeID)

---

### AssessFinancialItemOtherInfo

Stores "Other" text for financial items.

| Column | Type | Description |
|--------|------|-------------|
| FinancialItemID | int | PK/FK → AssessFinancialItem.FinancialItemID |
| FinancialTypeOther | nvarchar | Other financial type text |

---

### FinancialType

Lookup table for financial item types (income sources, asset types, expense categories).

| Column | Type | Description |
|--------|------|-------------|
| FinancialTypeID | int | Primary key |
| FinancialDescription | nvarchar | Type description |
| FinancialCategoryID | int | Category grouping |
| SubCategoryID | int | Sub-category |
| TypeID | tinyint | Type indicator (income/expense/asset) |
| IncomePovertyType | int | Poverty type classification |
| SortOrder | int | Display order |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

---

### XHouseholdBudget

Household budget assessment — detailed monthly income and expense tracking for financial counseling. Captures both formal income sources (employment, disability, pension) and informal sources (day labor, panhandling, bottle collecting, etc.) alongside comprehensive expense categories. Totals are calculated and a budget plan narrative is recorded. Used during financial counseling sessions to assess household financial stability and create spending plans.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_Job | money | Income — job/employment income |
| X_Disability | money | Income — disability income |
| X_Pension | money | Income — pension income |
| X_GeneralWelfare | money | Income — general welfare benefits |
| X_RecChildSupport | money | Income — received child support |
| X_FriendsFamily | money | Income — friends/family financial support |
| X_GirlfriendBoyfriend | money | Income — partner/significant other support |
| X_OtherFriends | money | Income — other friends support |
| X_DayLabor | money | Income (Informal) — day labor income |
| X_OddJobs | money | Income (Informal) — odd jobs income |
| X_Panhandling | money | Income (Informal) — panhandling income |
| X_BottleCollectingscrapping | money | Income (Informal) — bottle collecting/scrapping income |
| X_SellingCrafts | money | Income (Informal) — selling crafts income |
| X_StreetEntertainment | money | Income (Informal) — street entertainment income |
| X_BabySitting | money | Income (Informal) — babysitting income |
| X_MedicalResearch | money | Income (Informal) — medical research income |
| X_NonMedicalResearch | money | Income (Informal) — non-medical research income |
| X_GamblingProfit | money | Income (Informal) — gambling profit |
| X_Pawning | money | Income (Informal) — pawning income |
| X_Sex | money | Income (Informal) — sex work income |
| X_TreasureHunting | money | Income (Informal) — treasure hunting income |
| X_Inheritance | money | Income — inheritance income |
| X_OtherIncome | money | Income — other income |
| X_OtherIncomeNote | nvarchar | Income — other income notes/explanation |
| X_TotalIncome | money | Income — calculated total monthly income |
| X_HUDIncome | int | Income — HUD income category |
| X_Rent | money | Expense — rent |
| X_Utilities | money | Expense — utilities |
| X_Food | money | Expense — food |
| X_Gas | money | Expense (Transportation) — gas |
| X_Bus | money | Expense (Transportation) — bus/transit |
| X_Taxis | money | Expense (Transportation) — taxis |
| X_carpayment | money | Expense (Transportation) — car payment |
| X_carinsurance | money | Expense (Transportation) — car insurance |
| X_Repairs | money | Expense (Transportation) — vehicle repairs |
| X_CellPhone | money | Expense — cell phone |
| X_Cable | money | Expense — cable/internet |
| X_HouseholdSupplies | money | Expense — household supplies |
| X_Laundry | money | Expense — laundry |
| X_Kids | money | Expense — kids/childcare |
| X_HealthStuff | money | Expense — health-related expenses |
| X_ChildSupport | money | Expense — child support payments |
| X_Debts | money | Expense — debt payments |
| X_Arrears | money | Expense — arrears payments |
| X_LegalStuffFines | money | Expense — legal fees and fines |
| X_Cigarettes | money | Expense (Discretionary) — cigarettes |
| X_Coffee | money | Expense (Discretionary) — coffee |
| X_Alcohol | money | Expense (Discretionary) — alcohol |
| X_OtherDrugs | money | Expense (Discretionary) — other drugs |
| X_GamblingLoss | money | Expense (Discretionary) — gambling losses |
| X_SocializingPartyingNightOut | money | Expense (Discretionary) — socializing/partying/night out |
| X_OtherExpenses | money | Expense — other expenses |
| X_OtherExpensesNote | nvarchar | Expense — other expenses notes/explanation |
| X_TotalExpense | money | Expense — calculated total monthly expenses |
| X_Plan | nvarchar | Budget Plan — budget plan narrative |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XHouseholdBudget → Assessment (AssessmentID, 1:1)

---

### VAMCStationCodes

VA Medical Center station codes lookup table.

| Column | Type | Description |
|--------|------|-------------|
| VAMCStationCodeID | int | Primary key |
| StationNumber | nvarchar | VAMC station number |
| Description | nvarchar | Station description/name |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

---

## Document Management Tables

### DocumentCheck

Tracks document compliance status per client.

| Column | Type | Description |
|--------|------|-------------|
| DocumentCheckID | int | Primary key |
| ClientID | int | FK → Client.EntityID |
| DocumentTypeID | int | FK → DocumentType.DocumentTypeID |
| CertifiedDate | datetime | Certification date |
| Description | varchar | Document description |
| ExpiresDate | date | When the document expires |
| IssuedDate | date | Document issue date |
| StorageMethodID | int | Storage method |
| VerificationMethodID | int | Verification method |
| X_ServiceID | int | FK → Service.ServiceID |
| Restriction | tinyint | Access restriction level |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Business rule:** Document validity is 730 days (2 years) from collection date.

---

### DocumentType

Master list of document types tracked in the system.

| Column | Type | Description |
|--------|------|-------------|
| DocumentTypeID | int | Primary key |
| DocumentCategoryID | int | FK → DocumentTypeCategoryType |
| TypeDescription | nvarchar | Display name of document type |
| SortOrder | tinyint | Display ordering |
| X_isTFARequestDoc | int | FK to ListItem — is TFA request document |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| CreatedDate | smalldatetime | When record was created |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

---

### DocumentTypeCategoryType

Categories that group document types (e.g., "Non-TFA Documents", "TFA Documents").

| Column | Type | Description |
|--------|------|-------------|
| DocumentCategoryID | int | Primary key |
| DocumentTypeID | int | FK → DocumentType.DocumentTypeID |

---

### Files

Physical file storage and metadata for uploaded documents.

| Column | Type | Description |
|--------|------|-------------|
| FileID | int | Primary key |
| ContextID | int | Polymorphic FK |
| ContextTypeID | int | Polymorphic type indicator |
| FileClassification | int | File classification |
| FileDataLink | varchar | File data link |
| FileLabel | nvarchar | File display label |
| FileName | nvarchar | Original file name |
| IsEncrypted | bit | Whether file is encrypted |
| MimeType | nvarchar | MIME type |
| Restriction | tinyint | Access restriction level |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When file was uploaded |
| CreatedFormID | int | Form used to upload file |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** Files → Entity (via ContextID when ContextTypeID indicates entity context)

---

### UVW_DocumentFile

System view — joined document check and file information.

| Column | Type | Description |
|--------|------|-------------|
| ClientID | int | FK → Client.EntityID |
| Description | varchar | Document description |
| DocumentCheckID | int | FK → DocumentCheck.DocumentCheckID |
| DocumentTypeID | int | FK → DocumentType.DocumentTypeID |
| ExpiresDate | date | Document expiration date |
| FileID | int | FK → Files.FileID |
| FileLabel | nvarchar | File display label |
| Restriction | tinyint | Access restriction level |
| StorageMethodID | int | Storage method |
| VerificationMethodID | int | Verification method |

---

## Case Notes Tables

### CaseNotes

Main case notes table — stores client interactions, progress notes, and documentation.

| Column | Type | Description |
|--------|------|-------------|
| CaseNoteID | int | Primary key |
| EntityID | int | FK → Entity.EntityID (client) |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| Body | nvarchar | Full case note content |
| CaseNoteSummary | nvarchar | Brief summary of the note |
| CaseNoteTypeID | int | FK to ListItem (note type) |
| TemplateID | int | FK to case note template used |
| MasterNoteID | int | FK to master note (for linked notes) |
| FamilyOrIndividual | int | Indicates if note applies to family or individual |
| Signature | nvarchar | Signature data |
| ReadOnly | bit | If true, note cannot be edited |
| Restriction | tinyint | Access restriction level |
| Original | int | Original note reference |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| LegacyID | int | ID from legacy system migration |
| X_NoteJobType | int | FK to ListItem — custom field for job type categorization |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When note was created |
| CreatedFormID | int | Form used to create the note |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID (who deleted) |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- CaseNotes → Entity (EntityID)
- CaseNotes → Enrollment (EnrollmentID)
- CaseNotes → CaseNotesExtension (CaseNoteID)
- CaseNotes → SignaturesCaseNotes (CaseNoteID)

---

### CaseNotesExtension

Extended fields for case notes — stores additional metadata like contact type and service tracking.

| Column | Type | Description |
|--------|------|-------------|
| CaseNoteID | int | PK/FK → CaseNotes.CaseNoteID |
| ReferenceDate | datetime | Date the note references |
| ContactType | int | FK to ListItem (phone, in-person, etc.) |
| ServiceID | int | FK → Service.ServiceID |
| ShiftID | int | FK to shift record |
| ComponentTypeID | int | FK to component type |
| SatisfactoryProgress | int | FK to ListItem (progress indicator) |
| NeedWrkSuppServ | int | FK to ListItem (needs work support services) |
| X_CMServiceView | int | FK to ListItem — custom CM service view |
| X_CMToolCAT | int | FK to ListItem — custom CM tool category |
| X_InternalorExternal | int | FK to ListItem — internal vs external contact |

**Key relationships:** CaseNotesExtension → CaseNotes (CaseNoteID, 1:1)

---

### AddendumNotes

Addendum notes linked to a master case note — same structure as `CaseNotes`, linked via `MasterNoteID`. Allows appending follow-up notes to an original case note.

| Column | Type | Description |
|--------|------|-------------|
| CaseNoteID | int | PK, identity |
| Body | nvarchar | Full text body of the addendum note |
| CaseNoteSummary | nvarchar | Summary/subject line of the note |
| CaseNoteTypeID | int | Type of case note |
| EntityID | int | FK to Entity — client the note is about |
| EnrollmentID | int | Associated enrollment ID |
| FamilyOrIndividual | int | Whether note applies to family or individual |
| MasterNoteID | int | FK to CaseNotes.CaseNoteID — the parent note this addendum is attached to |
| Original | bit | Whether this is the original note |
| ReadOnly | bit | Whether the note is read-only |
| Restriction | int | Access restriction level |
| Signature | nvarchar | Signature of the note author |
| TemplateID | int | Template used to create the note |
| X_NoteJobType | int | FK to ListItem.ListItemID — job type categorization for the note |
| CreatedBy | int | User ID who created the record |
| CreatedDate | datetime | Record creation timestamp |
| CreatedFormID | int | Form used to create the record |
| DeletedBy | int | User ID who soft-deleted the record |
| DeletedDate | date | Soft-delete timestamp (NULL = active) |
| LastModifiedBy | int | User ID who last modified the record |
| LastModifiedDate | datetime | Last modification timestamp |
| LastModifiedFormID | int | Form used for last modification |

**Key relationships:** AddendumNotes → CaseNotes (MasterNoteID, M:1), AddendumNotes → Entity (EntityID, M:1), AddendumNotes → ListItem (X_NoteJobType)

---

### Signature

Stores electronic signature images and metadata.

| Column | Type | Description |
|--------|------|-------------|
| SignatureID | int | Primary key |
| SignatoryName | varchar | Name of the person who signed |
| SignatoryTypeID | int | FK to ListItem (client, staff, witness, etc.) |
| SignatureImage | varbinary | Binary signature image data |
| MimeType | nvarchar | Image MIME type (image/png, etc.) |
| IsEncrypted | bit | Whether signature is encrypted |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When signature was captured |
| CreatedFormID | int | Form used to capture signature |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |

---

### SignaturesCaseNotes

Junction table linking signatures to case notes.

| Column | Type | Description |
|--------|------|-------------|
| CaseNotesSignaturesID | int | Primary key |
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| SignatureID | int | FK → Signature.SignatureID |
| Saved | bit | Whether signature has been saved/finalized |

**Key relationships:** Links CaseNotes ↔ Signature (many-to-many)

---

## Referral Tables

### XSVdPReferral

Custom SVDP referral tracking table.

| Column | Type | Description |
|--------|------|-------------|
| XSVdPReferralID | int | Primary key |
| EntityID | int | FK → Entity.EntityID (client) |
| X_EnrollmentID | int | FK → Enrollment.EnrollmentID |
| X_ReferralStatus | int | FK to ListItem (listID 1000000390). Terminal values: 4, 5, 7, 8, 99 |
| X_ReferralType | int | FK to ListItem (type of referral) |
| X_InternalorExternal | int | FK to ListItem (internal vs external referral) |
| X_Date | datetime | Referral date |
| X_EndDate | datetime | Referral end/close date |
| X_BestTimeToContact | int | FK to ListItem |
| X_CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| X_CMNotes | nvarchar | Case manager notes |
| X_SMNotes | nvarchar | Service manager notes |
| X_SMSelectEntity | int | Service manager selected entity |
| X_SMSelectName | nvarchar | Service manager selected name |
| X_AssignEntity1 | int | Assigned entity 1 |
| X_AssignEntity2 | int | Assigned entity 2 |
| X_AssignStaff1 | nvarchar | Assigned staff 1 name |
| X_AssignStaff2 | nvarchar | Assigned staff 2 name |
| X_FoxStatus | int | FK to ListItem — Fox program referral status |
| X_GPDStatus | int | FK to ListItem — GPD program referral status |
| X_HCNStatus | int | FK to ListItem — HCN referral status |
| X_HNStatus | int | FK to ListItem — Housing Navigator referral status |
| X_PSHStatus | int | FK to ListItem — PSH program referral status |
| X_SOARStatus | int | FK to ListItem — SOAR referral status |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | Referral creation date |
| CreatedFormID | int | Form used to create referral |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Business rules:**
- Terminal statuses (4, 5, 7, 8, 99) freeze the "days since referral" counter
- `X_EndDate` provides a reliable freeze date independent of `LastModifiedDate`
- Program-specific status fields (X_FoxStatus, X_GPDStatus, etc.) track referral status per program
- Admins can reopen closed referrals

---

### XLegalServiceReferral

Legal services referral tracking — SSVF legal services referral assessment and reporting.

| Column | Type | Description |
|--------|------|-------------|
| XLegalServiceReferralID | int | Primary key |
| EntityID | int | FK → Entity.EntityID |
| **Custom Fields** | | |
| X_ApproverNotes | nvarchar | Approver notes |
| X_AssignedTo | int | FK to ListItem — assigned staff |
| X_BestTimeToContact | int | FK to ListItem — best contact time |
| X_ClientConsent | bit | Client consent obtained |
| X_DegreeOfUrgency | int | Degree of urgency |
| X_EligibilityCertification | bit | Eligibility certification |
| X_EnrollmentID | int | FK → Enrollment.EnrollmentID |
| X_FoundingSource | int | Funding source |
| X_LegalAssistanceType | int | FK to ListItem — legal assistance type |
| X_LegalReferralType | int | Legal referral type |
| X_Notes | nvarchar | Notes |
| X_Other | nvarchar | Other details |
| X_InternalorExternal | int | FK to ListItem — internal vs external referral |
| X_ReferralStatus | int | FK to ListItem (listID 132). Terminal values: 4, 5, 7, 8, 99 |
| X_ReferralType | int | FK to ListItem — referral type |
| X_SMSelect | int | Service manager selection |
| X_SMSelectName | nvarchar | Service manager name |
| X_SVdPReferral | int | FK → XSVdPReferral.XSVdPReferralID (linked SVDP referral) |
| X_Urgency | int | FK to ListItem — urgency level |
| X_User | int | References user (form-level key) |
| X_UserProvider | int | User provider reference |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | Referral creation date |
| CreatedFormID | int | Form used to create referral |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- XLegalServiceReferral → Entity (EntityID)
- XLegalServiceReferral → Enrollment (X_EnrollmentID)

**Business rules:**
- Terminal statuses (4, 5, 7, 8, 99) freeze the referral counter
- Used on Forms #1000001250, #1000001282

---

## Provider / Service Tables

### Provider

Organizations or entities that provide services — extends Entity table.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK/FK → Entity.EntityID |
| ProviderName | nvarchar | Provider display name |
| FirstName | nvarchar | Contact first name |
| LastName | nvarchar | Contact last name |
| MiddleName | nvarchar | Contact middle name |
| Suffix | int | FK to ListItem |
| ContactTitle | nvarchar | Contact title |
| Title | nvarchar | Provider title |
| SiteIdentifier | nvarchar | Site identifier |
| Description | nvarchar | Provider description |
| DBA | nvarchar | Doing business as |
| Notes | nvarchar | Notes |
| Nickname | nvarchar | Nickname |
| EIN | nvarchar | Employer identification number |
| SocialSecurityNumber | nvarchar | SSN |
| RoutingNumber | nvarchar | Routing number |
| BankAccountNumber | nvarchar | Bank account number |
| Address | nvarchar | Street address |
| Address2 | nvarchar | Street address line 2 |
| City | nvarchar | City |
| State | char | State (2-letter code) |
| StateProvIndent | varchar | State/province identifier |
| ZipCode | char | ZIP code |
| County | nvarchar | County |
| Country | int | FK to ListItem — country |
| CouncilDistrict | nchar | Council district |
| Neighborhood | nvarchar | Neighborhood |
| Latitude | float | Geographic latitude |
| Longitude | float | Geographic longitude |
| MailingAddress | int | Mailing address reference |
| TimeZone | int | Time zone |
| ProviderTypeID | int | FK → ProviderType |
| ProviderTypeCatID | int | FK → ProviderTypeCategory |
| Status | tinyint | Provider status |
| HomePhone | nvarchar | Home phone |
| CellPhone | nvarchar | Cell phone |
| WorkPhone | nvarchar | Work phone |
| Phone | varchar | Phone number |
| FaxNumber | nvarchar | Fax number |
| Email | nvarchar | Email address |
| IsContact | bit | Is a contact record |
| Website | nvarchar | Website URL |
| DefaultPaymentType | int | Default payment type |
| SignRequiredAmount | money | Signature required amount threshold |
| PaymentFormID | int | Payment form ID |
| ProviderAccountNumber | nvarchar | Provider account number |
| DisableForSelection | bit | Disable for selection |
| DisableFundsTracking | bit | Disable funds tracking |
| OrganizationID | int | Organization ID |
| ParentEntityID | int | FK → Entity.EntityID (parent entity) |
| DateEstablished | datetime | Date provider was established |
| DUNSNumber | nvarchar | DUNS number |
| ReferenceID | nvarchar | External reference ID |
| Religion | tinyint | Religion indicator |
| TaxType | tinyint | Tax type |
| DefaultAMIID | int | Default AMI ID |
| DefaultAMIMetro | bit | Default AMI metro indicator |
| TermsID | int | Terms ID |
| W9onFile | bit | W-9 on file |
| WIOALocation | nvarchar | WIOA location |
| WIOAWIB | nvarchar | WIOA workforce investment board |
| LegacyID | varchar | ID from legacy system |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| Restriction | tinyint | Access restriction level |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- Provider → Entity (EntityID, 1:1)
- Provider → ProviderHMIS (EntityID)
- Provider → EnrollmentMember (ProviderID)
- Provider → Service (ProviderID)

---

### ProviderHMIS

HMIS-specific provider configuration — HUD reporting identifiers and CoC codes.

| Column | Type | Description |
|--------|------|-------------|
| ProviderID | int | PK/FK → Provider.EntityID |
| COCCode | nvarchar | Continuum of Care code |
| GeoCode | nvarchar | Geographic code |
| GeoCodeType | int | Geographic code type |
| FIPSCode | nvarchar | FIPS code |
| COCCodeFY | int | CoC code fiscal year |
| FMRFiscalYear | int | Fair Market Rent fiscal year |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |

**Key relationships:** ProviderHMIS → Provider (ProviderID, 1:1)

---

### Service

Services delivered to clients — financial assistance, case management services, and program activities.

| Column | Type | Description |
|--------|------|-------------|
| ServiceID | int | Primary key |
| ProvidedToEntityID | int | FK → Entity.EntityID (client receiving service) |
| ProvidedByEntityID | int | FK → Entity.EntityID (provider) |
| ProvidedByUserID | int | FK → Users.EntityID (staff) |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| FamilyID | int | FK → Family.FamilyID |
| FamilyOrIndividual | int | Family vs individual service |
| **Service Details** | | |
| ServiceTypeID | int | FK → ServiceType.ServiceTypeID |
| ServiceActivityTypeID | int | Service activity type |
| ComponentTypeID | int | Component type |
| BeginDate | datetime | Service start date/time |
| EndDate | datetime | Service end date/time |
| MethodOfContact | int | Method of contact |
| Location | int | Service location |
| AddressID | int | FK → Address |
| Latitude | float | GPS latitude |
| Longitude | float | GPS longitude |
| **Financial** | | |
| Units | money | Number of units |
| UnitValue | money | Value per unit |
| UnitOfMeasure | int | Unit of measure |
| ServiceTotal | money | Total service value |
| PaidtoDate | money | Amount paid to date |
| AccountID | int | FK → Account.AccountID |
| AccountTableType | tinyint | Account table type |
| ISClientAccount | bit | Is client account |
| BillingStatus | int | Billing status |
| BatchTranID | int | Batch transaction ID |
| RefundServiceID | int | Related refund service |
| ReportingCategoryServiceID | int | Reporting category |
| ServiceAuthoEligibilityID | int | Service authorization eligibility |
| ApprovalGroupID | int | Approval group |
| **Custom SVDP Fields** | | |
| X_Grant | int | FK to ListItem — grant |
| X_SageDepartment | int | FK to ListItem — Sage department |
| X_TransactionType | int | FK to ListItem — transaction type |
| X_TransactionNumber | int | Transaction number |
| X_ServiceNote | nvarchar | Service notes |
| X_Reason | varchar | Reason |
| X_DenialReason | varchar | Denial reason |
| X_VendorName | varchar | Vendor name |
| X_MidDate | date | Mid-point date |
| X_CostShare | int | FK to ListItem — cost share |
| X_HUDVASH | int | FK to ListItem — HUD-VASH |
| X_ProjectionProgram | int | FK to ListItem — projection program |
| X_InHMIS | bit | In HMIS |
| X_IsReviewed | int | Is reviewed |
| **Payment Method** | | |
| X_IsCheck | int | FK to ListItem — is check payment |
| X_CheckUpload | bit | Check uploaded |
| X_IsACH | int | FK to ListItem — is ACH payment |
| X_ACHDate | datetime | ACH date |
| X_ACHNumber | nvarchar | ACH number |
| X_CreditCard | int | FK to ListItem — credit card |
| X_CCNumber | int | Credit card number (last 4) |
| X_IsVoid | int | FK to ListItem — is voided |
| X_IsRefund | bit | Is refund |
| X_Unitvalue3 | money | Unit value 3 |
| CaseNotesID | int | FK → CaseNotes.CaseNoteID |
| Restriction | tinyint | Access restriction level |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| LegacyID | varchar | ID from legacy system |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- Service → Entity (ProvidedToEntityID = client, ProvidedByEntityID = provider)
- Service → Users (ProvidedByUserID)
- Service → Enrollment (EnrollmentID)
- Service → ServiceType (ServiceTypeID)
- Service → Account (AccountID)
- Service → CaseNotes (CaseNotesID)

---

### ServiceType

Service type definitions — configures available service types and their default values.

| Column | Type | Description |
|--------|------|-------------|
| ServiceTypeID | int | Primary key |
| Description | nvarchar | Service type description |
| UnitOfMeasure | int | Default unit of measure |
| UnitValue | money | Default unit value |
| DuplicateMinutes | int | Minutes before service is considered duplicate |
| EffectiveDate | date | Effective date |
| LeaseType | int | Lease type |
| ReportServiceCategory | int | Reporting category |
| Taxonomy | int | Taxonomy code |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| LegacyID | varchar | ID from legacy system |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** Service → ServiceType (ServiceTypeID)

---

### ServicePayment

Payments made for services — tracks checks, ACH, and other payment methods.

| Column | Type | Description |
|--------|------|-------------|
| PaymentID | int | Primary key |
| ServiceID | int | FK → Service.ServiceID |
| ReceivedByEntityID | int | FK → Entity.EntityID (payee) |
| AccountID | int | FK → Account.AccountID |
| PaidDate | datetime | Payment date |
| PaymentAmount | money | Payment amount |
| PaymentType | int | Payment type |
| ReferenceNumber | nvarchar | Check/reference number |
| TransactionID | int | Transaction ID |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- ServicePayment → Service (ServiceID)
- ServicePayment → Entity (ReceivedByEntityID)
- ServicePayment → Account (AccountID)

---

### ServiceBillingExtension

Service billing extension — links services to billing contexts via polymorphic relationship. The `ContextID`/`ContextTypeID` pair identifies the billing target.

| Column | Type | Description |
|--------|------|-------------|
| ServiceBillingExtensionID | int | PK, identity |
| ServiceID | int | FK to Service.ServiceID (required) |
| ContextID | int | Polymorphic FK — ID of the billing context entity (required) |
| ContextTypeID | int | Polymorphic type — identifies which table ContextID references (required) |
| Order | int | Sort/display order |

**Key relationships:** ServiceBillingExtension → Service (ServiceID, M:1), ServiceBillingExtension → (polymorphic via ContextID + ContextTypeID)

---

### BillClient

Service type usage junction — marks service types available for client billing. Filtered subset where `ServiceUsage == 6`.

| Column | Type | Description |
|--------|------|-------------|
| ServiceTypeID | int | PK/FK to ServiceType.ServiceTypeID |
| ServiceUsage | tinyint | Usage type flag (required, value = 6 for client billing) |

**Key relationships:** BillClient → ServiceType (ServiceTypeID, 1:1)

---

### MedicalServiceTypeUsage

Service type usage junction — marks service types available for medical usage. Filtered subset where `ServiceUsage == 9`.

| Column | Type | Description |
|--------|------|-------------|
| ServiceTypeID | int | PK/FK to ServiceType.ServiceTypeID |
| ServiceUsage | tinyint | Usage type flag (required, value = 9 for medical) |

**Key relationships:** MedicalServiceTypeUsage → ServiceType (ServiceTypeID, 1:1)

---

### ServiceTypeCategory

Service type category junction — categorizes service types into groupings.

| Column | Type | Description |
|--------|------|-------------|
| CategoryID | int | FK to category definitions (required) |
| ServiceTypeID | int | FK to ServiceType.ServiceTypeID (required) |

**Key relationships:** ServiceTypeCategory → ServiceType (ServiceTypeID, M:1)

---

## WAL (Waiting/Activity List) Tables

### XWAL

WAL header table — tracks staff activity log periods (weekly/bi-weekly time tracking).

| Column | Type | Description |
|--------|------|-------------|
| XLogID | int | Primary key |
| UserID | int | FK → Users.UserID (staff member) |
| X_StartDate | date | WAL period start date |
| X_EndDate | date | WAL period end date |
| X_Total | int | Total hours/units for the period |
| X_IsApproved | bit | Whether WAL has been approved |
| X_LockWAL | bit | Whether WAL is locked from editing |
| X_LockDate | date | Date when WAL was locked |
| X_CaseNoteID | int | FK → CaseNotes.CaseNoteID (linked case note) |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When WAL was created |
| CreatedFormID | int | Form used to create WAL |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- XWAL → Users (UserID)
- XWAL → XWALItem (XLogID)
- XWAL → CaseNotes (X_CaseNoteID)

---

### XWALItem

WAL line items — individual time entries within a WAL period.

| Column | Type | Description |
|--------|------|-------------|
| XWALItemID | int | Primary key |
| XLogID | int | FK → XWAL.XLogID (parent WAL) |
| X_Date | date | Date of the activity |
| X_ClientID | int | FK → Entity.EntityID (client served) |
| X_CaseManagerID | int | FK → Entity.EntityID (case manager) |
| X_Program | int | FK to ListItem (program) |
| X_Grant | int | Grant ID |
| X_JobType | int | FK to ListItem (job type) |
| X_WALType | int | FK to ListItem (WAL entry type) |
| X_SageDepartment | int | FK to ListItem (Sage department for billing) |
| X_SageDepartmentNoClient | int | Sage department when no client specified |
| X_SageDepartmentNoProgram | int | Sage department when no program specified |
| X_WF_SageDep | int | Workflow Sage department |
| X_ExitedProgram | int | FK to ListItem (if client exited) |
| X_NonActiveClient | int | FK to ListItem (non-active client indicator) |
| X_Direct | money | Direct service time |
| X_Collateral | money | Collateral contact time |
| X_Coach | money | Coaching time |
| X_Shadow | money | Shadowing time |
| X_Support | money | Support time |
| X_CaseReview | money | Case review time |
| X_Travel | money | Travel time |
| X_Docs | money | Documentation time |
| X_OtherTime | money | Other time |
| X_TotalItem | money | Total time for this line item |
| X_TotalRounded | int | Total rounded to nearest unit |
| X_Notes | nvarchar | Notes for this line item |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When item was created |
| CreatedFormID | int | Form used to create item |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- XWALItem → XWAL (XLogID)
- XWALItem → Entity (X_ClientID, X_CaseManagerID)

**Time categories:** Direct, Collateral, Coach, Shadow, Support, CaseReview, Travel, Docs, OtherTime — all stored as `money` type for decimal precision.

---

## Custom SVDP Tables

### XClientDocRcpt

Tracks client receipt of required documents and acknowledgments (HIPAA, grievance procedures, etc.).

| Column | Type | Description |
|--------|------|-------------|
| XClientDocRcptID | int | Primary key |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| X_ClientID | int | FK → Client.EntityID |
| X_ProgramName | nvarchar | Program name |
| X_HIPAANotice | int | FK to ListItem — HIPAA notice received |
| X_HIPAANoticeDate | date | HIPAA notice date |
| X_ClientGrievanceHandout | int | FK to ListItem — grievance handout received |
| X_ClientGrievanceHandoutDate | date | Grievance handout date |
| X_AgencyInformBrochure | int | FK to ListItem — agency brochure received |
| X_AgencyInformBrochureDate | date | Agency brochure date |
| X_ClientRR | int | FK to ListItem — client rights/responsibilities |
| X_ClientRRDate | date | Client R&R date |
| X_EmergActionPlan | int | FK to ListItem — emergency action plan |
| X_EmergActionPlanDate | date | Emergency action plan date |
| X_ProgLivingAgree | int | FK to ListItem — program living agreement |
| X_ProgLivingAgreeDate | date | Program living agreement date |
| X_SSVFVetRightPact | int | FK to ListItem — SSVF veteran rights pact |
| X_SSVFVetRightPactDate | date | SSVF vet rights pact date |
| X_VANoticeProtections | int | FK to ListItem — VA notice of protections |
| X_VANoticeProtectionsDate | date | VA notice protections date |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- XClientDocRcpt → Enrollment (EnrollmentID)
- XClientDocRcpt → Client (X_ClientID)

---

### XSNAP

Strengths, Needs, Abilities, Preferences — client assessment for person-centered planning.

| Column | Type | Description |
|--------|------|-------------|
| XSNAPID | int | Primary key |
| ClientID | int | FK → Client.EntityID |
| X_Strength | nvarchar | Client strengths |
| X_Needs | nvarchar | Client needs |
| X_Ability | nvarchar | Client abilities |
| X_Preference | nvarchar | Client preferences |
| Restriction | int | Access restriction level |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** XSNAP → Client (ClientID)

---

### XSVdPEnrollmentSummary

SVDP enrollment summary extension — tracks enrollment status and special program flags.

| Column | Type | Description |
|--------|------|-------------|
| XSVdPEnrollmentSummaryID | int | Primary key |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| X_EnrollmentStatus | int | FK to ListItem — enrollment status |
| X_ReferredFromHUDVASH | int | FK to ListItem — referred from HUD-VASH |
| X_ShallowSubsidyStatus | int | FK to ListItem — shallow subsidy status |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** XSVdPEnrollmentSummary → Enrollment (EnrollmentID)

---

### EntityVeteranInfo

Veteran information for entities — military service details and VA benefits.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK/FK → Entity.EntityID |
| Veteran | tinyint | Veteran status |
| **Military Service** | | |
| VetBranch | tinyint | Military branch |
| VetServiceEra | tinyint | Service era |
| VetDuration | int | Duration of service |
| DateEnteredService | date | Date entered service |
| DateSeparatedFromService | date | Date separated from service |
| VetDischargeStatus | tinyint | Discharge status |
| Reserves | int | Reserve/Guard status |
| **War Zone Service** | | |
| VetServedWarZone | tinyint | Served in war zone |
| VetWarZoneName | tinyint | War zone name |
| VetNumMonthsWarZone | tinyint | Months in war zone |
| VetReceivedFire | tinyint | Received hostile fire |
| **VA Benefits** | | |
| ServiceConnectedDisability | int | Service-connected disability |
| DisabilityRewardLevel | int | Disability award level |
| PercentAMI | int | Percent of AMI |
| SpecialDisabled | int | Special disabled veteran |
| CampaignBadgeVeteran | int | Campaign badge veteran |
| **DD-214** | | |
| HaveDD214 | int | Has DD-214 |
| DD214Ref | int | DD-214 reference |
| DD214orderDate | date | DD-214 order date |
| DD214ReceiveDate | date | DD-214 receive date |
| **Other** | | |
| StandDownEvent | int | Stand down event participation |
| AddressID | int | FK → Address |
| AddressDataQuality | int | Address data quality |
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| LegacyAssessmentID | int | Legacy assessment ID |
| LegacyID | varchar | ID from legacy system |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** EntityVeteranInfo → Entity (EntityID, 1:1)

---

### EnrollmentServicePlan

Service plans linked to enrollments — housing stability plans, case management goals.

| Column | Type | Description |
|--------|------|-------------|
| EnrollmentServicePlanID | int | Primary key |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| ClientID | int | FK → Client.EntityID |
| CaseManagerID | int | FK → Users.EntityID |
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| **Plan Details** | | |
| PlanTypeID | int | Plan type |
| Description | nvarchar | Plan description |
| LongDescription | nvarchar | Long description |
| PlanBeginDate | date | Plan start date |
| PlanEndDate | date | Plan end date |
| ActualCompletedDate | date | Actual completion date |
| PercentComplete | tinyint | Percent complete |
| FamilyOrIndividual | int | Family vs individual plan |
| Signature | nvarchar | Signature data |
| **Context** | | |
| ContextTypeID | int | Context type |
| ContextID | int | Context ID |
| **Custom SVDP Fields** | | |
| X_Phase | int | FK to ListItem — plan phase |
| X_PhaseNote | int | FK to ListItem — phase note |
| X_PhaseOneWaived | bit | Phase one waived |
| X_PhaseTwoWaived | bit | Phase two waived |
| X_Status | int | FK to ListItem — plan status |
| X_IsApproved | bit | Plan approved |
| X_DateOfReview | datetime | Date of review |
| X_PermanentHousingGoal | nvarchar | Permanent housing goal |
| X_ViableHousingOptions | nvarchar | Viable housing options |
| X_SeekingExitByDate | date | Target exit date |
| X_ImmediateIntervention | nvarchar | Immediate intervention |
| X_FinancialResourcesAvailable | nvarchar | Financial resources available |
| X_Recertification | nvarchar | Recertification notes |
| **Phase Actions** | | |
| X_Objective | nvarchar | Objective |
| X_TypeOfAssistance | nvarchar | Type of assistance (Phase 1) |
| X_Who | nvarchar | Who is responsible (Phase 1) |
| X_Frequency | nvarchar | Frequency (Phase 1) |
| X_Rationale | nvarchar | Rationale (Phase 1) |
| X_TypeOfAssistance2 | nvarchar | Type of assistance (Phase 2) |
| X_Who2 | nvarchar | Who is responsible (Phase 2) |
| X_Frequency2 | nvarchar | Frequency (Phase 2) |
| X_Rationale2 | nvarchar | Rationale (Phase 2) |
| X_TypeOfAssistance3 | nvarchar | Type of assistance (Phase 3) |
| X_Who3 | nvarchar | Who is responsible (Phase 3) |
| X_Frequency3 | nvarchar | Frequency (Phase 3) |
| X_Rationale3 | nvarchar | Rationale (Phase 3) |
| X_OtherSpecify | nvarchar | Other — specify |
| X_ParticipatedInDevelopmentOfPlan | int | FK to ListItem — participated in Phase 1 |
| X_ParticipatedInDevelopmentOfPlanPhase2 | int | FK to ListItem — participated in Phase 2 |
| X_ParticipatedInDevelopmentOfPlanPhase3 | int | FK to ListItem — participated in Phase 3 |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- EnrollmentServicePlan → Enrollment (EnrollmentID)
- EnrollmentServicePlan → Client (ClientID)
- EnrollmentServicePlan → Users (CaseManagerID)
- EnrollmentServicePlan → CaseNotes (CaseNoteID)

---

### PlanTypeProgram

Links plan types to programs — configures which plan types are available per program.

| Column | Type | Description |
|--------|------|-------------|
| PlanTypeProgramID | int | Primary key |
| ProgramID | int | FK → Program.ProgramID |
| PlanTypeID | int | FK → PlanType |
| PlanTargetDueDays | int | Target days until plan due |
| PercentCompleteMethod | tinyint | Percent complete calculation method |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** PlanTypeProgram → Program (ProgramID)

---

### ContextDocuments

Required documents junction — links document requirements to various contexts (service types, programs, etc.) via polymorphic relationship. The `ContextID`/`ContextTypeID` pair identifies the parent context (e.g., `ContextTypeID == 3` for ServiceType).

| Column | Type | Description |
|--------|------|-------------|
| ContextDocID | int | PK, identity |
| Association | int | Association type identifier |
| ContextID | int | Polymorphic FK — ID of the parent context entity (required) |
| ContextTypeID | int | Polymorphic type — identifies which table ContextID references (required) |
| DocProcessRuleID | int | Document processing rule identifier |
| DocumentID | int | FK to document definitions (required) |
| Process | int | Process type identifier |
| Required | bit | Whether the document is required (required) |
| SortOrder | int | Display sort order |
| DeletedBy | int | User ID who soft-deleted the record |
| DeletedDate | date | Soft-delete timestamp (NULL = active) |

**Key relationships:** ContextDocuments → (polymorphic via ContextID + ContextTypeID, M:1)

---

### JunctionDocument

Junction table linking document checks to contexts.

| Column | Type | Description |
|--------|------|-------------|
| JunctionDocumentID | int | Primary key |
| ContextTypeID | int | Context type |
| ContextID | int | Context ID |
| DocumentCheckID | int | FK → DocumentCheck.DocumentCheckID |

---

## Lookup Tables

### ListItem

Central lookup table for all dropdown values system-wide.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | Primary key (the value stored in FK columns) |
| ListItemCategoryID | int | FK → ListItemCategory (groups related values) |
| DisplayValue | nvarchar | What the user sees in the dropdown |
| SortOrder | int | Display ordering |
| IsActive | bit | Active/inactive |

**Key ListItemCategory IDs:**
- `1000000390` — Referral Status values (terminal: 4, 5, 7, 8, 99)
- `1000000403` — Office Location (ClientOfficeList) → used by `Client.X_Office`

---

### ListItemCategory

Groups of related ListItems (e.g., "Gender", "Ethnicity", "Referral Status").

| Column | Type | Description |
|--------|------|-------------|
| ListItemCategoryID | int | Primary key |
| CategoryName | nvarchar | Category display name |

---

### List_Insurance_Types

Specialized lookup table for health insurance types — used by AssessHealthInsurance.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | Primary key |
| Description | nvarchar | Insurance type description |
| SortOrder | int | Display ordering |
| IsActive | bit | Active/inactive |
| DeletedDate | date | Soft-delete marker |

**Common values:** Medicaid, Medicare, SCHIP, Employer, COBRA, Private, VA Medical Services, Indian Health Services, Other

---

### uvw_ListItem

Built-in view that provides list item lookups with hierarchy support.

| Column | Type | Description |
|--------|------|-------------|
| ListID | int | List identifier (category ID) |
| ListLabel | nvarchar | Display label |
| ListValue | int | Stored value |
| SubOfID | int | Parent item ID (for hierarchical lists) |
| SortOrder | int | Display ordering |
| Selectable | bit | Whether item can be selected |

**Use case:** Simplifies dropdown value lookups. ListID corresponds to the list category, ListValue is stored in FK columns, ListLabel is displayed to users.

---

### List_Assessment_Event

Assessment event type lookup — Entry, During, Exit.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | Primary key |
| ListID | int | List category ID |
| ListLabel | nvarchar | Display label |
| ListValue | int | Stored value (1=Entry, 2=During, 3=Exit) |
| SubOfID | int | Parent item ID |

**Values:**
- 1 = At Entry
- 2 = During (Update/Recertification)
- 3 = At Exit

---

### List_Assessment_Association

Assessment association lookup — values for linking assessments to program contexts.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | Primary key |
| ListID | int | List category ID |
| ListLabel | nvarchar | Display label |
| ListValue | int | Stored value |
| SubOfID | int | Parent item ID |
| SortOrder | int | Display ordering |
| Selectable | bit | Whether item is active/selectable |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| EnabledForOrgGroupID | int | Enabled for org group |

---

### AreaMedianIncome

Area Median Income (AMI) lookup — poverty level thresholds by household size and geography.

| Column | Type | Description |
|--------|------|-------------|
| AMIID | int | Primary key |
| AreaName | varchar | Area name |
| City | varchar | City |
| County | nvarchar | County |
| State | char | State |
| BegDate | date | Effective begin date |
| EndDate | date | Effective end date |
| Metro | money | Metro area AMI |
| NonMetro | money | Non-metro area AMI |
| Total | money | Total AMI |
| **Poverty Levels by Household Size** | | |
| Poverty1FamMem | money | 1-person household |
| Poverty2FamMem | money | 2-person household |
| Poverty3FamMem | money | 3-person household |
| Poverty4FamMem | money | 4-person household |
| Poverty5FamMem | money | 5-person household |
| Poverty6FamMem | money | 6-person household |
| Poverty7FamMem | money | 7-person household |
| Poverty8FamMem | money | 8-person household |
| PovertyAdditional | money | Each additional household member |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Use case:** Determines client income eligibility for various programs. Programs use AMI percentages (e.g., 30% AMI, 50% AMI) as enrollment thresholds.

---

### List_Acuity_Level_Score_1

Acuity level scoring lookup — Low, Medium, High, Very High.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | Primary key |
| ListID | int | List category ID |
| ListLabel | nvarchar | Display label |
| ListValue | int | Stored value |
| SubOfID | int | Parent item ID |

---

### List_YesNoDontKnowWontAnswer

Lookup list — standard HUD Yes/No/Don't Know/Refused response values. Used across many HUD-required fields.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | PK — ListItem identifier |
| ListID | int | Parent list identifier (required) |
| ListLabel | nvarchar | Display label (e.g., "Yes", "No", "Client doesn't know", "Client prefers not to answer") (required) |
| ListValue | int | Numeric value for the list item (required) |
| SubOfID | int | Parent item ID for hierarchical lists (required) |

**Key relationships:** List_YesNoDontKnowWontAnswer → ListItemCategory (ListID, M:1)

---

### List_PSHStatusList

Lookup list — PSH (Permanent Supportive Housing) referral status values. Used by XSVdPReferral.X_PSHStatus.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | PK — ListItem identifier |
| ListID | int | Parent list identifier |
| ListLabel | nvarchar | Display label |
| ListValue | int | Numeric value |
| SubOfID | int | Parent item ID for hierarchical lists |

---

### List_FoxStatusList

Lookup list — Fox program referral status values. Used by XSVdPReferral.X_FoxStatus.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | PK — ListItem identifier |
| ListID | int | Parent list identifier |
| ListLabel | nvarchar | Display label |
| ListValue | int | Numeric value |
| SubOfID | int | Parent item ID for hierarchical lists |

---

### List_GPDStatusList

Lookup list — GPD (Grant & Per Diem) referral status values. Used by XSVdPReferral.X_GPDStatus.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | PK — ListItem identifier |
| ListID | int | Parent list identifier |
| ListLabel | nvarchar | Display label |
| ListValue | int | Numeric value |
| SubOfID | int | Parent item ID for hierarchical lists |

---

### List_HCNStatus

Lookup list — HCN referral status values. Used by XSVdPReferral.X_HCNStatus.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | PK — ListItem identifier |
| ListID | int | Parent list identifier |
| ListLabel | nvarchar | Display label |
| ListValue | int | Numeric value |
| SubOfID | int | Parent item ID for hierarchical lists |

---

### List_HNStatusList

Lookup list — Housing Navigator referral status values. Used by XSVdPReferral.X_HNStatus.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | PK — ListItem identifier |
| ListID | int | Parent list identifier |
| ListLabel | nvarchar | Display label |
| ListValue | int | Numeric value |
| SubOfID | int | Parent item ID for hierarchical lists |

---

### List_SOARStatusList

Lookup list — SOAR referral status values. Used by XSVdPReferral.X_SOARStatus.

| Column | Type | Description |
|--------|------|-------------|
| ListItemID | int | PK — ListItem identifier |
| ListID | int | Parent list identifier |
| ListLabel | nvarchar | Display label |
| ListValue | int | Numeric value |
| SubOfID | int | Parent item ID for hierarchical lists |

---

## User & Role Management Tables

### RoleDefinition

Role definitions — configures system roles and their capabilities.

| Column | Type | Description |
|--------|------|-------------|
| RoleID | int | Primary key |
| RoleName | nvarchar | Role display name |
| Inactive | bit | Whether role is inactive |
| IsPortal | bit | Is a portal role |
| IsPortalUI | bit | Is portal UI role |
| IsCaseBuddy | bit | Is case buddy role |
| IsUnAuthenticate | bit | Unauthenticated access |
| IsHideBreadcrumbs | bit | Hide breadcrumbs in UI |
| DisableRecentClientLoad | bit | Disable recent client loading |
| EnableTimeLogging | bit | Enable time logging for role |
| LandingDashboardKey | nvarchar | Landing dashboard identifier |
| PortalLogoLink | varchar | Portal logo URL |
| PortalNoAccessDashboardKey | nvarchar | No-access dashboard key |
| PortalRegisterLink | varchar | Portal registration URL |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |

---

### UserRole

Links users to roles — assigns role-based permissions to individual users.

| Column | Type | Description |
|--------|------|-------------|
| UserRoleID | int | Primary key |
| UserID | int | FK → Users.EntityID |
| RoleID | int | FK → RoleDefinition.RoleID |
| UserRoleTypeID | int | Role type classification |
| IsReadonly | bit | Whether role is read-only for this user |

**Key relationships:**
- UserRole → Users (UserID)
- UserRole → RoleDefinition (RoleID)

---

### Impersonation

User impersonation records — tracks when one user is authorized to act as another.

| Column | Type | Description |
|--------|------|-------------|
| ImpersonateID | int | Primary key |
| UserID | int | FK → Users.EntityID (user being impersonated) |
| ImpersonatorID | int | FK → Users.EntityID (user doing the impersonating) |
| StartDate | date | Impersonation start date |
| EndDate | date | Impersonation end date |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- Impersonation → Users (UserID)
- Impersonation → Users (ImpersonatorID)

---

### UserSupervisorHistory

Supervisor assignment history — tracks supervisor changes for staff over time.

| Column | Type | Description |
|--------|------|-------------|
| UserSupervisorHistoryID | int | Primary key |
| UserID | int | FK → Users.EntityID (staff member) |
| SupervisorID | int | FK → Users.EntityID (supervisor) |
| SupervisorType | tinyint | Supervisor type |
| BeginDate | datetime | Assignment start date |
| EndDate | datetime | Assignment end date |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- UserSupervisorHistory → Users (UserID)
- UserSupervisorHistory → Users (SupervisorID)

---

### UserEntity

Entity record for user-type entities — same base `Entity` structure with custom `X_EnrollmentID` field. Represents system users as entities.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK, identity |
| EntityName | nvarchar | Display name of the user entity |
| EntityTypeID | tinyint | Entity type identifier (required) |
| UniqueID | uniqueidentifier | Globally unique identifier |
| X_EnrollmentID | bit | Custom SVDP flag — enrollment ID indicator |
| CreatedBy | int | User ID who created the record |
| CreatedDate | datetime | Record creation timestamp |
| DeletedBy | int | User ID who soft-deleted the record |
| DeletedDate | date | Soft-delete timestamp (NULL = active) |
| LastModifiedBy | int | User ID who last modified the record |
| LastModifiedDate | datetime | Last modification timestamp |

**Key relationships:** UserEntity → Entity (EntityID, subset of Entity where EntityTypeID = user type)

---

### EntityStaff

Entity record for staff-type entities — same base `Entity` structure with custom `X_EnrollmentID` field. Represents staff members as entities.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK, identity |
| EntityName | nvarchar | Display name of the staff entity |
| EntityTypeID | tinyint | Entity type identifier (required) |
| UniqueID | uniqueidentifier | Globally unique identifier |
| X_EnrollmentID | bit | Custom SVDP flag — enrollment ID indicator |
| CreatedBy | int | User ID who created the record |
| CreatedDate | datetime | Record creation timestamp |
| DeletedBy | int | User ID who soft-deleted the record |
| DeletedDate | date | Soft-delete timestamp (NULL = active) |
| LastModifiedBy | int | User ID who last modified the record |
| LastModifiedDate | datetime | Last modification timestamp |

**Key relationships:** EntityStaff → Entity (EntityID, subset of Entity where EntityTypeID = staff type)

---

## Organization & Address Tables

### Organization

Organization records — top-level organizational entities in the system.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK/FK → Entity.EntityID |
| OrgName | nvarchar | Organization display name |
| Address1 | varchar | Street address |
| City | varchar | City |
| State | varchar | State |
| ZipCode | varchar | ZIP code |
| DefaultProviderID | int | FK → Provider (default provider) |
| AllowExcel | bit | Allow Excel export |
| AllowPrint | bit | Allow printing |
| AutoLogoutMinutes | int | Auto-logout timeout |
| CommHubAdhocServiceTypeID | int | Communication hub ad hoc service type |
| EnableTimeLogging | bit | Enable time logging |
| EnableViewHistoryTracking | bit | Enable view history tracking |
| IsCreatedOrgEditable | bit | Created org is editable |
| LockoutAfterAttempts | int | Account lockout threshold |
| PWChangeDays | int | Password change interval (days) |
| RandomAudit | int | Random audit setting |
| TransactionDaysOld | int | Transaction days old setting |
| LegacyID | varchar | ID from legacy system |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** Organization → Entity (EntityID, 1:1)

---

### Address

Generic address table — stores addresses linked to various entity types via polymorphic context.

| Column | Type | Description |
|--------|------|-------------|
| AddressID | int | Primary key |
| ContextID | int | Polymorphic FK (links to entity, provider, etc.) |
| ContextType | int | Polymorphic type indicator |
| AddressType | tinyint | Address type |
| Address1 | nvarchar | Street address line 1 |
| Address2 | nvarchar | Street address line 2 |
| City | varchar | City |
| State | char | State (2-letter code) |
| ZipCode | char | ZIP code |
| County | nvarchar | County |
| Country | int | FK to ListItem — country |
| Neighborhood | nvarchar | Neighborhood |
| Latitude | float | GPS latitude |
| Longitude | float | GPS longitude |
| LocationType | int | Location type |
| BeginDate | date | Address effective start date |
| EndDate | date | Address effective end date |
| Restriction | tinyint | Access restriction level |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Note:** Different from `ClientAddress` — this is the generic address table used across providers, organizations, and other contexts via polymorphic keys.

---

### EntityDemographic

Entity demographic information — stores demographic data for non-client entities (staff, contacts).

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK/FK → Entity.EntityID |
| BirthDate | date | Date of birth |
| Gender | int | FK to ListItem — gender |
| Ethnicity | tinyint | FK to ListItem — ethnicity |
| Race | tinyint | FK to ListItem — race |
| RaceOther | nvarchar | Other race text |
| VeteranStatus | tinyint | Veteran status |
| SSN | varchar | Social Security Number |
| SSNDataQuality | int | SSN data quality indicator |
| CitizenshipStatusID | tinyint | FK to ListItem — citizenship status |
| PrimaryLanguage | int | FK to ListItem — primary language |
| OtherLanguage | tinyint | Other language |
| LanguageOther | nvarchar | Other language text |
| ReligiousAffiliations | tinyint | Religious affiliations |
| SexOffender | tinyint | Sex offender indicator |
| OtherDemographicInfo | int | Other demographic info |
| DLNumber | int | Driver's license number |
| DLState | char | Driver's license state |
| DLExpDate | date | Driver's license expiration date |
| Restriction | int | Access restriction level |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |

**Key relationships:** EntityDemographic → Entity (EntityID, 1:1)

---

### EntityContact

Entity contact records — emergency contacts, references, and other contacts linked to entities.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK/FK → Entity.EntityID |
| ParentEntityID | int | FK → Entity.EntityID (parent entity) |
| FirstName | nvarchar | Contact first name |
| LastName | nvarchar | Contact last name |
| MiddleName | nvarchar | Contact middle name |
| Suffix | int | FK to ListItem — suffix |
| Company | nvarchar | Company name |
| RelationshipID | int | FK to ListItem — relationship type |
| ProjectRole | int | Project role |
| OtherRole | nvarchar | Other role description |
| OtherDesc | nvarchar | Other description |
| Phone1 | varchar | Primary phone |
| Phone1Type | int | Primary phone type |
| Phone2 | varchar | Secondary phone |
| Phone2Type | int | Secondary phone type |
| Email | nvarchar | Email address |
| IsEmergencyContact | bit | Is emergency contact |
| IsBackgroundCheck | bit | Background check completed |
| X_AuthorizedToContact | int | FK to ListItem — authorized to contact |
| X_IsEmergencyContactYN | int | FK to ListItem — emergency contact yes/no |
| BeginDate | date | Contact effective start date |
| EndDate | date | Contact effective end date |
| Restriction | int | Access restriction level |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- EntityContact → Entity (EntityID)
- EntityContact → Entity (ParentEntityID)

---

### OrgGroup

Organization groups — groups of organizations for access control.

| Column | Type | Description |
|--------|------|-------------|
| OrgGroupID | int | Primary key |
| CreatedDate | datetime | When record was created |

---

### OrgGroupMember

Links organizations to organization groups — junction table for org group membership.

| Column | Type | Description |
|--------|------|-------------|
| OrganizationID | int | FK → Organization.EntityID |
| OrgGroupID | int | FK → OrgGroup.OrgGroupID |

**Key relationships:**
- OrgGroupMember → Organization (OrganizationID)
- OrgGroupMember → OrgGroup (OrgGroupID)

---

## Approval & Workflow Tables

### Approval

Approval records — tracks approval workflow for services, case notes, and other items.

| Column | Type | Description |
|--------|------|-------------|
| ApprovalID | int | Primary key |
| ContextID | int | Polymorphic FK (links to service, case note, etc.) |
| ContextTypeID | int | Polymorphic type indicator |
| UserID | int | FK → Users.EntityID (approver) |
| IsApproved | bit | Whether item is approved |
| Status | int | Approval status |
| DeniedBy | int | FK → Users.EntityID (who denied) |
| DeniedDate | datetime | Denial date |
| DeniedCategory | int | Denial category |
| DeniedReason | nvarchar | Denial reason |
| X_Reason | nvarchar | Custom reason field |
| ObligationProcessID | int | Obligation process reference |
| ObligationRequredTime | int | Required obligation time |
| OrganizationID | int | FK → Organization |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- Approval → Users (UserID = approver)
- Approval → Users (DeniedBy)

---

### ApprovalItem

Approval workflow step items — individual approval steps within an approval process. Each ApprovalItem represents one approver's action on an Approval record.

| Column | Type | Description |
|--------|------|-------------|
| ApprovalItemID | int | Primary key |
| ApprovalID | int | FK → Approval.ApprovalID |
| IsApproved | bit | Whether this step is approved |
| Status | int | Approval step status |
| UserID | int | FK → Users.EntityID (approver for this step) |
| ApprovalDate | datetime | Date this step was approved |
| ObligationStepID | int | Obligation step reference |
| ObligationRequredTime | int | Required obligation time |
| OldApprovalItemID | int | Reference to previous approval item |
| HoldReason | varchar | Reason for hold |
| X_Reason | nvarchar | Custom reason field |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- ApprovalItem → Approval (ApprovalID, M:1)
- ApprovalItem → Users (UserID = step approver)

---

### UpdatedClientList

Tracks recently updated client records — used for UI client lists.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | FK → Entity.EntityID |
| UpdatedBy | int | FK → Users.EntityID |
| UpdatedDate | datetime | When client was last updated |
| Status | int | Status indicator |

---

### JobType

Job type definitions — classifies staff positions and roles.

| Column | Type | Description |
|--------|------|-------------|
| JobTypeID | int | Primary key |
| JobDescription | nvarchar | Job type description |
| CategoryID | int | Job category |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** JobType → WorkHistory (ProgramJobTypeID)

---

## Additional Assessment Tables

### XBarrierAssess

Housing barrier assessment — tracks barriers to housing across personal, tenant, landlord, and income domains. Each barrier category is scored, and subtotals roll up into an overall barrier total. Used during housing search to identify and address specific obstacles to placement. Covers criminal history, substance use, health conditions, credit/eviction history, landlord references, and income adequacy.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_NewOrReturn | int | Classification — FK to ListItem — new or returning client |
| X_NewOrReturnOther | int | Classification — other new/return detail |
| X_AMI | int | Income Barrier — FK to ListItem — area median income level |
| X_Amount | money | Income Barrier — amount |
| X_Income | int | Income Barrier — FK to ListItem — income adequacy status |
| X_Authorized | int | Income Barrier — FK to ListItem — authorized income verification |
| X_VetQualifies | int | Income Barrier — FK to ListItem — veteran qualifies for benefits |
| X_Felony | int | Personal Barrier — FK to ListItem — felony record |
| X_FelonyOther | nvarchar | Personal Barrier — other felony details |
| X_Misdemeanors | int | Personal Barrier — FK to ListItem — misdemeanor record |
| X_MisDetail | nvarchar | Personal Barrier — misdemeanor details |
| X_Probation | int | Personal Barrier — FK to ListItem — probation status |
| X_Vice | int | Personal Barrier — FK to ListItem — vice issues |
| X_Violence | int | Personal Barrier — FK to ListItem — violence history |
| X_VoilenceExplain | nvarchar | Personal Barrier — violence explanation (typo preserved from source) |
| X_Drugs | int | Personal Barrier — FK to ListItem — drug use |
| X_DrugsExplain | nvarchar | Personal Barrier — drug use explanation |
| X_Mental | int | Personal Barrier — FK to ListItem — mental health barrier |
| X_MentalExplain | nvarchar | Personal Barrier — mental health explanation |
| X_Physical | int | Personal Barrier — FK to ListItem — physical health barrier |
| X_PhysicalExplain | nvarchar | Personal Barrier — physical health explanation |
| X_BadCredit | int | Tenant Barrier — FK to ListItem — bad credit indicator |
| X_CreditHistory | int | Tenant Barrier — FK to ListItem — credit history |
| X_Eviction | int | Tenant Barrier — FK to ListItem — eviction history |
| X_UnpaidRent | int | Tenant Barrier — FK to ListItem — unpaid rent |
| X_Utilities | int | Tenant Barrier — FK to ListItem — utilities barrier |
| X_UtilitiesOther | nvarchar | Tenant Barrier — other utilities details |
| X_BadRefer | int | Landlord Barrier — FK to ListItem — bad landlord reference |
| X_Lease | int | Landlord Barrier — FK to ListItem — lease history status |
| X_LeaseOther | nvarchar | Landlord Barrier — other lease details |
| X_LandlordOther | nvarchar | Landlord Barrier — other landlord barrier text |
| X_TenantOther | nvarchar | Landlord Barrier — other tenant barrier text |
| X_IdentifiedAddress | nvarchar | Housing Search — identified address |
| X_EndDate | date | Housing Search — barrier assessment end date |
| X_Summary | int | Summary — FK to ListItem — summary assessment |
| X_UnusualCir | bit | Summary — unusual circumstances flag |
| X_OveralTotal | int | Calculated Totals — overall barrier total |
| X_TotalBarrier | int | Calculated Totals — total barrier score |
| X_TotalIncome | int | Calculated Totals — total income barrier score |
| X_TotalLandlordAmount | int | Calculated Totals — total landlord barrier score |
| X_TotalPersonal | int | Calculated Totals — total personal barrier score |
| X_TotalTenant | int | Calculated Totals — total tenant barrier score |
| X_TotalTenantAmount | int | Calculated Totals — total tenant amount score |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XBarrierAssess → Assessment (AssessmentID, 1:1); all int FK fields → ListItem.ListItemID

---

### XClientHousing

Client housing preferences — tracks desired housing features and requirements for housing search assistance. A lightweight extension table used to record the client's preferred housing specifications during the search process.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_Beds | int | Housing Preference — number of bedrooms desired |
| X_Baths | int | Housing Preference — number of bathrooms desired |
| X_Rent | money | Housing Preference — maximum rent budget |
| X_Location | nvarchar | Housing Preference — preferred location |
| X_Pet | int | Housing Preference — pet accommodation needed |
| X_PetExplain | nvarchar | Housing Preference — pet details/explanation |
| X_OtherPref | nvarchar | Housing Preference — other preferences |
| X_OtherAddPref | nvarchar | Housing Preference — other additional preferences |
| X_OtherNeeds | nvarchar | Housing Preference — other housing needs |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XClientHousing → Assessment (AssessmentID, 1:1)

---

### XProgramExitPlanAssess

Program exit/housing stability plan assessment — documents client readiness for independent living and creates an exit preparation plan. Assesses daily living skills (lease compliance, food shopping, laundry, budgeting, prescriptions, landlord communication) and captures narrative action plans for potential housing challenges (eviction, housing loss, instability). Used to verify the client can sustain housing before program exit.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_AbideLease | int | Housing Stability Skills — FK to ListItem — can abide by lease terms |
| X_AccessFoodPant | int | Housing Stability Skills — FK to ListItem — can access food pantry |
| X_AccessLockedOut | int | Housing Stability Skills — FK to ListItem — knows what to do if locked out |
| X_Budget | int | Housing Stability Skills — FK to ListItem — can manage a budget |
| X_CleanAPT | int | Housing Stability Skills — FK to ListItem — can maintain clean apartment |
| X_DoLaundry | int | Housing Stability Skills — FK to ListItem — can do laundry |
| X_ExitPrep | int | Housing Stability Skills — FK to ListItem — exit preparation status |
| X_FoodShopping | int | Housing Stability Skills — FK to ListItem — can do food shopping |
| X_GestsOver | int | Housing Stability Skills — FK to ListItem — can manage guests appropriately |
| X_HandleAppoint | int | Housing Stability Skills — FK to ListItem — can handle appointments |
| X_PayRentUtilitOther | int | Housing Stability Skills — FK to ListItem — can pay rent/utilities/other |
| X_PhysicalMentalHealth | int | Housing Stability Skills — FK to ListItem — manages physical/mental health |
| X_RefillPrescriptions | int | Housing Stability Skills — FK to ListItem — can refill prescriptions |
| X_ResolveHouseIssues | int | Housing Stability Skills — FK to ListItem — can resolve housing maintenance issues |
| X_RespectTenants | int | Housing Stability Skills — FK to ListItem — respects other tenants |
| X_SeekHelp | int | Housing Stability Skills — FK to ListItem — knows how to seek help |
| X_SpeakWLandlord | int | Housing Stability Skills — FK to ListItem — can communicate with landlord |
| X_IAMPrepared | nvarchar | Exit Plan Narratives — "I am prepared" statement |
| X_IfEvictionNoticeIWill | nvarchar | Exit Plan Narratives — eviction notice action plan |
| X_IfLoseHousingIWill | nvarchar | Exit Plan Narratives — housing loss action plan |
| X_IfUnstableIWill | nvarchar | Exit Plan Narratives — instability action plan |
| X_IWillAvoidEvict | nvarchar | Exit Plan Narratives — eviction avoidance plan |
| X_IWillPayRent | nvarchar | Exit Plan Narratives — rent payment plan |
| X_LatestAddress | nvarchar | Exit Plan Narratives — latest address on file |
| X_SignsOfHousingUnstable | nvarchar | Exit Plan Narratives — signs of housing instability to watch for |
| X_StaffComm | nvarchar | Exit Plan Narratives — staff comments |
| X_TargetExitDate | datetime | Exit Plan Narratives — target exit date |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XProgramExitPlanAssess → Assessment (AssessmentID, 1:1); all int FK fields → ListItem.ListItemID

---

### XProgramExitChecklistV3

Program exit checklist — version 3 of the exit verification checklist. Tracks completion of required exit tasks including housing stability plan, final budget review, housing counseling, landlord contact, HMIS exit processing, referrals, and client acknowledgment. Used by case managers to ensure all exit procedures are completed before closing the enrollment.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_AgreeandReadytoExit | int | Exit Readiness — FK to ListItem — client agrees and is ready to exit |
| X_CanSustain | int | Exit Readiness — FK to ListItem — client can sustain housing independently |
| X_PermHousing | int | Exit Readiness — FK to ListItem — client is in permanent housing |
| X_HousingStabPlan | int | Completed Tasks — FK to ListItem — housing stability plan completed |
| X_FinalBudget | int | Completed Tasks — FK to ListItem — final budget review completed |
| X_HousingCounseling | int | Completed Tasks — FK to ListItem — housing counseling completed |
| X_ContactWithLandlord | int | Completed Tasks — FK to ListItem — contact established with landlord |
| X_ContactWithProg | int | Completed Tasks — FK to ListItem — contact with program maintained |
| X_RefferalsMade | int | Completed Tasks — FK to ListItem — referrals made (typo preserved from source) |
| X_KnowTheyCanReachBack | int | Completed Tasks — FK to ListItem — client knows they can reach back for support |
| X_ExitfromHMIS | bit | Administrative — HMIS exit completed |
| X_InformedinWriting | bit | Administrative — client informed in writing |
| X_VAexitSurvey | bit | Administrative — VA exit survey completed |
| X_IfExitedforOtherReasons | int | Administrative — FK to ListItem — if exited for other reasons |
| X_ExitSummary | nvarchar | Narrative — exit summary |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XProgramExitChecklistV3 → Assessment (AssessmentID, 1:1); all int FK fields → ListItem.ListItemID

---

### XCOHCareCenterExitChecklist2

COH Care Center exit document checklist — tracks collection of key identity documents at exit from the COH (Celebration of Hope) Care Center. Documents tracked are required for successful housing placement and benefit access post-exit.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK → Assessment.AssessmentID |
| X_BirthCertificate | int | Document Status — FK to ListItem — birth certificate obtained/status |
| X_DD214 | int | Document Status — FK to ListItem — DD-214 military discharge document status |
| X_DLorStateID | int | Document Status — FK to ListItem — driver's license or state ID status |
| X_SSCard | int | Document Status — FK to ListItem — Social Security card status |
| X_VACard | int | Document Status — FK to ListItem — VA card status |
| X_MissingDocExplain | nvarchar | Narrative — explanation for any missing documents |
| OwnedByOrgID | int | Audit — owning organization ID |
| CreatedBy | int | Audit — FK → Users.UserID |
| CreatedDate | datetime | Audit — when record was created |
| CreatedFormID | int | Audit — form used to create record |

**Key relationships:** XCOHCareCenterExitChecklist2 → Assessment (AssessmentID, 1:1); all int FK fields → ListItem.ListItemID

---

## Assessment Configuration Tables

### ProgramAssessment

Links assessment types to programs — configures which assessments are available per program.

| Column | Type | Description |
|--------|------|-------------|
| ProgramAssessmentID | int | Primary key |
| ProgramID | int | FK → Program.ProgramID |
| AssessmentTypeID | int | FK → AssessmentType.AssessmentTypeID |
| CEAssessment | int | Coordinated entry assessment flag |
| IsRequired | bit | Whether assessment is required |
| IsRequiredRuleID | int | Requirement rule reference |
| SortOrder | tinyint | Display ordering |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- ProgramAssessment → Program (ProgramID)
- ProgramAssessment → AssessmentType (AssessmentTypeID)

---

### AssessmentType

Assessment type definitions — links assessment types to their form configurations.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentTypeID | int | Primary key |
| FormID | int | FK → Form.FormID |
| AssociateWith | tinyint | Association type |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** AssessmentType → Form (FormID)

---

### Form

Form/screen definitions — stores configuration for all forms in the system.

| Column | Type | Description |
|--------|------|-------------|
| FormID | int | Primary key |
| FormName | nvarchar | Form internal name |
| FormDisplayName | nvarchar | Form display name |
| FormType | tinyint | Form type |
| Description | nvarchar | Form description |
| FormHelp | xml | Help content |
| Properties | nvarchar | Form properties |
| QueryID | int | Query reference |
| EditableBy | tinyint | Editable by role type |
| UsableBy | tinyint | Usable by role type |
| CacheGUID | uniqueidentifier | Cache identifier |
| IsBatchBuilder | int | Batch builder flag |
| IsDisabled | bit | Whether form is disabled |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

---

### Assessment Event Tables

Five tables with identical schema, each linking a ProgramAssessmentID to an AssessmentEvent for a specific lifecycle stage:

- **EntryAssessmentEvents** — triggered at enrollment entry
- **DuringAssessmentEvents** — triggered during enrollment
- **ExitAssessmentEvents** — triggered at enrollment exit
- **AnnualAssessmentEvents** — triggered annually
- **PostExitAssessmentEvents** — triggered post-exit

**Shared Schema (all 5 tables):**

| Column | Type | Description |
|--------|------|-------------|
| ProgramAssessmentID | int | FK → ProgramAssessment.ProgramAssessmentID |
| AssessmentEvent | tinyint | Event type identifier |

**Key relationships:** Each table → ProgramAssessment (ProgramAssessmentID)

---

## Additional Service & Program Tables

### ServiceTypeMedicalExt

Medical extension for service types — CPT/NDC codes and billing modifiers. Joins 1:1 to `ServiceType` on `ServiceTypeID`.

| Column | Type | Description |
|--------|------|-------------|
| ServiceTypeID | int | PK/FK to ServiceType.ServiceTypeID |
| CPTCode | nvarchar | CPT (Current Procedural Terminology) billing code |
| Max | money | Maximum billable amount |
| Min | money | Minimum billable amount |
| Modifier | nvarchar | Primary billing modifier |
| Modifier2 | nvarchar | Secondary billing modifier |
| Modifier3 | nvarchar | Tertiary billing modifier |
| Modifier4 | nvarchar | Quaternary billing modifier |
| NDCCode | nvarchar | NDC (National Drug Code) code |
| NDCDescription | nvarchar | Description for the NDC code |
| RoundingType | int | Rounding rule for billing calculations |

**Key relationships:** ServiceTypeMedicalExt → ServiceType (ServiceTypeID, 1:1)

---

### ServiceExtension

Service extension data — stores additional service detail fields for billing and group services.

| Column | Type | Description |
|--------|------|-------------|
| ServiceID | int | PK/FK → Service.ServiceID |
| UnitsTwo | money | Secondary units |
| UnitValueTwo | money | Secondary unit value |
| UnitofMeasureTwo | int | Secondary unit of measure |
| TotalTwo | money | Secondary total |
| GrantAmount | money | Grant amount |
| HMISInfoDate | date | HMIS information date |
| HVRPWithinCounty | int | HVRP within county flag |
| CounselingLevel | int | Counseling level |
| TestScore | int | Test score |
| IsAbsent | bit | Client absent flag |
| IsPresent | bit | Client present flag |
| Mood | int | Client mood |
| Participation | int | Participation level |
| ResponseToGroup | int | Response to group |
| TaskLearning | int | Task learning |
| ThoughtContent | int | Thought content |

**Key relationships:** ServiceExtension → Service (ServiceID, 1:1)

---

### ServiceTypeExt

Service type extensions — secondary unit configuration for service types.

| Column | Type | Description |
|--------|------|-------------|
| ServiceTypeID | int | PK/FK → ServiceType.ServiceTypeID |
| Units | money | Default secondary units |
| UnitValueTwo | money | Default secondary unit value |
| UnitofMeasureTwo | int | Default secondary unit of measure |

**Key relationships:** ServiceTypeExt → ServiceType (ServiceTypeID, 1:1)

---

### ServiceTypeUsage

Service type usage indicators — links service types to usage categories.

| Column | Type | Description |
|--------|------|-------------|
| ServiceTypeID | int | FK → ServiceType.ServiceTypeID |
| ServiceUsage | tinyint | Usage type indicator |

---

### ProgramService

Links service types to programs — configures which services are available per program.

| Column | Type | Description |
|--------|------|-------------|
| ProgramServiceID | int | Primary key |
| ProgramID | int | FK → Program.ProgramID |
| ServiceTypeID | int | FK → ServiceType.ServiceTypeID |
| IsReferable | bit | Whether service is referable |
| SortOrder | int | Display ordering |
| OrgGroupID | int | Organization group for read access |
| WriteOrgGroupID | int | Organization group for write access |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- ProgramService → Program (ProgramID)
- ProgramService → ServiceType (ServiceTypeID)

---

### ProgramBilling

Program billing configuration — invoicing and pricing settings per program.

| Column | Type | Description |
|--------|------|-------------|
| ProgramID | int | PK/FK → Program.ProgramID |
| InvoicingMethod | int | Invoicing method |
| PricingMethod | int | Pricing method |
| Pricing | int | Pricing type |
| ProgramBillingMethod | int | Program billing method |
| InvoiceReportFormat | int | Invoice report format |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** ProgramBilling → Program (ProgramID, 1:1)

---

### UsageBillable

Billable usage flags for service types.

| Column | Type | Description |
|--------|------|-------------|
| ServiceTypeID | int | FK → ServiceType.ServiceTypeID |
| ServiceUsage | tinyint | Usage type |

---

### UsageObligation

Obligation usage flags for service types.

| Column | Type | Description |
|--------|------|-------------|
| ServiceTypeID | int | FK → ServiceType.ServiceTypeID |
| ServiceUsage | tinyint | Usage type |

---

### FamilyCategory

Links families to service type categories — configures family-level service categorization.

| Column | Type | Description |
|--------|------|-------------|
| CategoryID | int | FK → Category |
| ServiceTypeID | int | FK → ServiceType.ServiceTypeID |

---

### programFosterCategory

Junction table linking programs to foster care category types.

| Column | Type | Description |
|--------|------|-------------|
| programTypeCategoryID | int | Primary key |
| programID | int | FK → Program.ProgramID |
| programTypeCategoryTypeID | int | FK to program type category |

---

### programTypeCategoryTFA

Junction table linking programs to TFA (Temporary Financial Assistance) category types.

| Column | Type | Description |
|--------|------|-------------|
| programTypeCategoryID | int | Primary key |
| programID | int | FK → Program.ProgramID |
| programTypeCategoryTypeID | int | FK to program type category |

---

### XServiceSVDPAddOns

SVDP service-level add-on data — tracks financial projections and cost sharing per enrollment.

| Column | Type | Description |
|--------|------|-------------|
| XServiceSVDPAddOnsID | int | Primary key |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| X_ClientProjectionTotal | money | Client projection total (calculated) |
| X_LastMonthDate | datetime | Last month date |
| X_LastMonthDateEnd | datetime | Last month end date |
| X_NumberOfMonths | money | Number of months |
| X_NumberOfMonthsP1 | money | Number of months (phase 1) |
| X_OtherRecurringCosts | money | Other recurring costs |
| X_ProjectionAmount | money | Projection amount |
| X_ProjectionCostSharing | money | Projection cost sharing |
| X_ProjectionCostSharingP1 | money | Projection cost sharing (phase 1) |
| X_ProjectionGrant | int | FK to ListItem — projection grant |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:** XServiceSVDPAddOns → Enrollment (EnrollmentID)

**Use case:** Tracks financial projections for TFA (Temporary Financial Assistance) services — projects monthly costs, cost sharing amounts, and total client projections for grant compliance.

---

## Encounter Tables

### Encounter

Encounter records — tracks interactions/encounters between staff and clients/entities.

| Column | Type | Description |
|--------|------|-------------|
| EncounterID | int | Primary key |
| EntityID | int | FK → Entity.EntityID |
| EncounterTypeID | int | FK → EncounterType.EncounterTypeID |
| Description | nvarchar | Encounter description |
| BeginDate | datetime | Encounter start date/time |
| EndDate | datetime | Encounter end date/time |
| CommType | int | Communication type |
| RecipientUserID | int | FK → Users.EntityID (recipient) |
| RefEncounterID | int | FK → Encounter (self-referencing) |
| GroupEncounterInstanceID | int | Group encounter instance |
| PlannedEncounterGroupItemID | int | Planned encounter group item |
| AssignedContextID | int | Polymorphic FK |
| AssignedContextTypeID | int | Polymorphic type indicator |
| X_AfterCare | int | FK to ListItem — aftercare flag |
| X_Note | nvarchar | Encounter notes |
| X_TemplateID | int | Template reference |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | datetime | Soft-delete marker |

**Key relationships:**
- Encounter → Entity (EntityID)
- Encounter → EncounterType (EncounterTypeID)
- Encounter → Users (RecipientUserID)
- Encounter → Encounter (RefEncounterID — self-referencing)
- Encounter → ContactLog (EncounterID)

---

### EncounterType

Encounter type definitions — configures available encounter categories.

| Column | Type | Description |
|--------|------|-------------|
| EncounterTypeID | int | Primary key |
| Description | nvarchar | Encounter type description |
| IsBillable | bit | Whether encounter is billable |
| IsDefault | bit | Default encounter type |
| IsPlannedEncounter | bit | Is a planned encounter type |
| IsPostService | bit | Post-service encounter |
| IsPostTime | bit | Post-time encounter |
| ServiceType | int | Linked service type |
| TimeType | int | Time type |
| CostCenterID | int | Cost center reference |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | datetime | Soft-delete marker |

**Key relationships:** EncounterType → Encounter (EncounterTypeID)

---

### ContactLog

Contact log records — detailed contact tracking linked to encounters.

| Column | Type | Description |
|--------|------|-------------|
| ContactLogID | int | Primary key |
| EncounterID | int | FK → Encounter.EncounterID |
| ProvidedByEntity | int | FK → Entity.EntityID (staff/provider) |
| ProvidedToEntity | int | FK → Entity.EntityID (client) |
| ContactDate | datetime | Contact date |
| ContactDateLegacy | datetime | Legacy contact date |
| ContactType | int | Contact type |
| ReasonForContact | int | Reason for contact |
| Status | int | Contact status |
| Notes | nvarchar | Contact notes |
| ReferenceNumber | int | Reference number |
| ContextID | int | Polymorphic FK |
| ContextTypeID | int | Polymorphic type indicator |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- ContactLog → Encounter (EncounterID)
- ContactLog → Entity (ProvidedByEntity, ProvidedToEntity)

---

## Release of Information Tables

### ROI

Release of Information records — tracks client consent for information sharing.

| Column | Type | Description |
|--------|------|-------------|
| ROIID | int | Primary key |
| EntityID | int | FK → Entity.EntityID (client) |
| FamilyID | int | FK → Family.FamilyID |
| ProviderID | int | FK → Provider.EntityID |
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| SuccessStoryID | int | Success story reference |
| ROIType | int | Release type |
| BeginDate | smalldatetime | Release effective start date |
| EndDate | smalldatetime | Release effective end date |
| ReleaseDuration | int | Release duration |
| IsRevoked | bit | Whether release is revoked |
| PurposeDesc | varchar | Purpose description |
| AlcoholMentalHealthDesc | varchar | Alcohol/mental health description |
| AdditionalInfo | varchar | Additional information |
| X_AliasMaidenMarried | nvarchar | Alias/maiden/married name |
| X_Authority | nvarchar | Authority reference |
| X_EntityContactID | int | Entity contact reference |
| X_Expire | int | FK to ListItem — expiration setting |
| X_OtherPurpose | nvarchar | Other purpose |
| X_OtherRelease | nvarchar | Other release details |
| X_Purpose | int | FK to ListItem — purpose |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- ROI → Entity (EntityID)
- ROI → Family (FamilyID)
- ROI → Provider (ProviderID)
- ROI → CaseNotes (CaseNoteID)

---

## Waitlist / Pre-Screening Tables

### XBeforeScreeningWaitList

Waitlist/pre-screening tracking — manages clients waiting for screening and enrollment.

| Column | Type | Description |
|--------|------|-------------|
| XBeforeScreeningWaitListID | int | Primary key |
| EntityID | int | FK → Entity.EntityID (client) |
| X_AssignedScreener | int | Assigned screener |
| X_AssignToOffice | int | FK to ListItem — assigned office |
| X_BeginDate | date | Wait list begin date |
| X_EndDate | date | Wait list end date |
| X_WaitListStatus | int | FK to ListItem — waitlist status |
| X_WaitListExitReason | int | FK to ListItem — exit reason |
| X_WLExitDestinationType | int | FK to ListItem — exit destination type |
| X_ProjectedEnrollmentType | int | FK to ListItem — projected enrollment type |
| X_OtherProjectedEnrollmentType | nvarchar | Other projected enrollment type |
| X_ProjectedofAdults | int | FK to ListItem — projected number of adults |
| X_ProjectedofChildren | int | FK to ListItem — projected number of children |
| X_SVdPReferredFrom | int | FK to ListItem — referred from |
| X_OtherReferredFrom | nvarchar | Other referred from |
| X_OtherReferredOut | nvarchar | Other referred out |
| X_ClientAssistType | nvarchar | Client assistance type |
| X_ClientAssistTypeDrop | int | FK to ListItem — client assistance type |
| X_DiversionDestinations | int | FK to ListItem — diversion destinations |
| X_ExternalReferralDestination | int | FK to ListItem — external referral destination |
| X_InstitutionalDestination | nvarchar | Institutional destination |
| X_ScreeningEnrollmentID | int | Links to enrollment |
| X_NewAssignedScreener | nvarchar | New assigned screener name |
| X_NewAssignedEnroller | nvarchar | New assigned enroller name |
| X_IneligibleDetials | nvarchar | Ineligible details (typo in source) |
| X_InformationalOnlyDetails | nvarchar | Informational only details |
| X_ReferredDetails | nvarchar | Referred details |
| X_Self_ResolvedDetails | nvarchar | Self-resolved details |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | datetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | datetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

**Key relationships:**
- XBeforeScreeningWaitList → Entity (EntityID)
- XBeforeScreeningWaitList → X_UVW_EnrollmentsAfterWaitlist (XBeforeScreeningWaitListID)
- XBeforeScreeningWaitList → X_UVW_DaysSinceWaitlist (XBeforeScreeningWaitListID)

**Use case:** Tracks clients from initial referral through screening and enrollment. Supports waitlist management, office assignment, and tracking of pre-screening dispositions.

---

## Additional Junction Tables

### JunctionCaseNote

Generic junction table — links case notes to various contexts.

| Column | Type | Description |
|--------|------|-------------|
| JunctionCaseNoteID | int | Primary key |
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| ContextID | int | Polymorphic FK |
| ContextTypeID | int | Polymorphic type indicator |

---

### TimeCaseNote

Junction table — links case notes to time entries.

| Column | Type | Description |
|--------|------|-------------|
| JunctionCaseNoteID | int | Primary key |
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| ContextID | int | Polymorphic FK |
| ContextTypeID | int | Polymorphic type indicator |

---

### ServiceCaseNote

Junction table — links case notes to services.

| Column | Type | Description |
|--------|------|-------------|
| JunctionCaseNoteID | int | Primary key |
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| ContextID | int | Polymorphic FK |
| ContextTypeID | int | Polymorphic type indicator |

---

### ContextFatherEngagement

Father engagement context records — tracks father engagement for applicable programs.

| Column | Type | Description |
|--------|------|-------------|
| ContextFatherEngagementID | int | Primary key |
| ContextID | int | Polymorphic FK |
| ContextTypeID | int | Polymorphic type indicator |
| YesNo | int | Engagement indicator |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

---

## Additional Provider Tables

### ProviderTypeCategory

Links providers to category types — categorizes providers by service type.

| Column | Type | Description |
|--------|------|-------------|
| ProviderTypeCategoryID | int | Primary key |
| EntityID | int | FK → Entity/Provider |
| ProviderTypeCategoryTypeID | int | FK → ProviderTypeCategoryType |

---

### ProviderTypeCategoryType

Provider category type definitions — master list of provider categories.

| Column | Type | Description |
|--------|------|-------------|
| ProviderTypeCategoryTypeID | int | Primary key |
| Description | nvarchar | Category type description |
| OwnedByOrgID | int | Owning organization ID |
| CreatedBy | int | FK → Users.UserID |
| CreatedDate | smalldatetime | When record was created |
| CreatedFormID | int | Form used to create record |
| LastModifiedBy | int | FK → Users.UserID |
| LastModifiedDate | smalldatetime | Last edit timestamp |
| LastModifiedFormID | int | Form used for last modification |
| DeletedBy | int | FK → Users.UserID |
| DeletedDate | date | Soft-delete marker |

---

## Custom SQL Views (Created by SVDP)

### X_UVW_ApprovalStatus

Service approval status view — tracks approval workflow for services.

| Column | Type | Description |
|--------|------|-------------|
| ApprovalID | int | Approval ID |
| ApprovalItemID | int | Approval item ID |
| ServiceID | int | FK → Service.ServiceID |
| StaffID | int | FK → Users.EntityID (requestor) |
| ApproverID | int | FK → Users.EntityID (approver) |
| Client | nvarchar | Client name |
| Program | nvarchar | Program name |
| ServiceType | nvarchar | Service type |
| ServiceDate | datetime | Service date |
| TransactionType | int | Transaction type |
| ApprovalStatus | int | Approval status |
| ApprovalDate | datetime | Approval date |
| Reason | nvarchar | Approval/denial reason |
| ObligationStepID | int | Obligation step ID |

**Use case:** Dashboard view for tracking service approvals in the financial workflow.

---

### x_uvw_DaysSinceLastReferral

Calculates days since referral creation, freezing the counter when referral hits terminal status.

```sql
CREATE VIEW x_uvw_DaysSinceLastReferral AS
SELECT
    r.XSVdPReferralID,
    r.EntityID,
    r.X_ReferralStatus,
    r.CreatedDate AS ReferralDate,
    r.X_EndDate,
    DATEDIFF(DAY, r.CreatedDate,
        CASE
            WHEN r.X_ReferralStatus IN (4, 5, 7, 8, 99)
                THEN r.X_EndDate
            ELSE GETDATE()
        END
    ) AS DaysSinceReferral
FROM XSVdPReferral r
WHERE r.DeletedDate IS NULL
```

### x_uvw_LatestUserByJobType

**View** — returns latest user assignment per client by program job type. Custom SVDP view for identifying assigned staff by role type.

| Column | Type | Description |
|--------|------|-------------|
| AssignmentID | int | PK/FK to assignment record |
| ClientID | int | PK/FK to EnrollmentMember.ClientID / Entity.EntityID |
| EnrollmentID | int | FK to Enrollment.EnrollmentID |
| ProgramJobTypeID | int | Job type identifier within the program |
| UserID | int | FK to User — assigned staff member's user ID (required) |

**Key relationships:** x_uvw_LatestUserByJobType → EnrollmentMember (ClientID + EnrollmentID), x_uvw_LatestUserByJobType → Entity (ClientID, M:1), x_uvw_LatestUserByJobType → Enrollment (EnrollmentID, M:1)

**Join pattern:** `EnrollmentMember.ClientID = x_uvw_LatestUserByJobType.ClientID AND EnrollmentMember.EnrollmentID = x_uvw_LatestUserByJobType.EnrollmentID`

**Known ProgramJobTypeID values used in forms:** 122, 123, 126, 130, 163, 181, 182, 183, 205

---

### X_UVW_Latest90DayRecertWEnroll

**View** — returns the latest 90-day recertification per client AND enrollment (enrollment-scoped). One row per client-enrollment combination.

| Column | Type | Description |
|--------|------|-------------|
| ClientID | int | PK/FK to EnrollmentMember.ClientID / Entity.EntityID |
| EnrollmentID | int | PK/FK to Enrollment.EnrollmentID |
| AssessmentID | int | FK to Assessment.AssessmentID — latest recertification assessment |
| AssessmentDate | datetime | Date of the latest recertification assessment |
| DaysSinceLastRecert | int | Calculated days since the latest 90-day recertification |

**Key relationships:** X_UVW_Latest90DayRecertWEnroll → Entity (ClientID, M:1), X_UVW_Latest90DayRecertWEnroll → Enrollment (EnrollmentID, M:1), X_UVW_Latest90DayRecertWEnroll → Assessment (AssessmentID, M:1)

### x_uvw_LatestShelterAssessment

Returns the most recent shelter-specific assessment per client.

### X_UVW_EnrollmentsAfterWaitlist

Custom view — shows enrollments that occurred after a client was on the waitlist.

| Column | Type | Description |
|--------|------|-------------|
| XBeforeScreeningWaitListID | int | FK → XBeforeScreeningWaitList |
| ClientID | int | FK → Client.EntityID |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| ProgramID | int | FK → Program.ProgramID |
| EnrollmentBeginDate | date | Enrollment start date |
| WaitlistBeginDate | date | Waitlist begin date |
| EnrollmentAfterWaitlist | int | Enrollment after waitlist indicator |

**Use case:** Tracks which enrollments resulted from waitlist referrals, linking waitlist entries to actual program enrollments.

---

### X_UVW_DaysSinceWaitlist

Custom view — calculates days since waitlist entry for tracking wait times.

| Column | Type | Description |
|--------|------|-------------|
| XBeforeScreeningWaitListID | int | FK → XBeforeScreeningWaitList |
| EntityID | int | FK → Entity.EntityID |
| DaysSinceBeginDate | int | Days since waitlist begin date (calculated) |
| DaysSinceCreatedDate | int | Days since waitlist created date (calculated) |
| DaysCreatedToEnd | int | Days from created to end date (calculated) |

**Use case:** Dashboard view for monitoring waitlist wait times and identifying clients who have been waiting longest.

---

### X_UVW_MostRecentHousingStabilityPlan

Custom view — returns the most recent housing stability plan per enrollment.

| Column | Type | Description |
|--------|------|-------------|
| LatestHousingStabilityPlanID | int | Primary identifier |
| ClientID | int | FK → Client.EntityID |
| EnrollmentID | int | FK → Enrollment.EnrollmentID |
| DateOfHousingStabilityPlan | date | Plan date |
| LatestHousingStabilityPhase | int | Current plan phase |
| GoalID | int | Goal reference |
| GoalDescription | nvarchar | Goal description text |
| GoalSetDate | date | When goal was set |
| PercentCompleteofGoal | tinyint | Goal completion percentage |
| DaysSinceLastHousingStabilityPlan | int | Days since plan (calculated) |
| DaysSinceLastGoalUpdate | int | Days since goal update (calculated) |

**Use case:** Used on TFA service forms to verify housing stability plan compliance before approving financial assistance.

---

### UVW_CaseNote

System view — case note access and ownership information.

| Column | Type | Description |
|--------|------|-------------|
| CaseNoteID | int | FK → CaseNotes.CaseNoteID |
| EntityID | int | FK → Entity.EntityID |
| UserID | int | FK → Users.EntityID |
| CreatedBy | int | FK → Users.UserID |
| ReadOnly | bit | Whether note is read-only |
| RealReadOnly | int | Computed read-only status |

---

### UVW_ProgramSummaryCountInfo

System view — aggregated counts per program for dashboard display.

| Column | Type | Description |
|--------|------|-------------|
| ProgramID | int | FK → Program.ProgramID |
| CountAccount | int | Number of linked accounts |
| CountAssessment | int | Number of assessment types |
| CountDocuments | int | Number of document types |
| CountNonAssessment | int | Number of non-assessment items |
| CountService | int | Number of service types |

---

### uvw_MOUShareToOrg

System view — MOU (Memorandum of Understanding) organization sharing relationships.

| Column | Type | Description |
|--------|------|-------------|
| ShareFromOrgID | int | FK → Organization.EntityID (source org) |
| ShareToOrgID | int | FK → Organization.EntityID (target org) |
| OrgName | nvarchar | Organization name |

**Use case:** Determines which organizations share data access through MOU agreements.

---

### UVW_OpenReservation

System view — open bed/unit reservation counts for providers.

| Column | Type | Description |
|--------|------|-------------|
| ProviderID | int | FK → Provider.EntityID |
| OrgID | int | FK → Organization.EntityID |
| ResourceID | int | Resource/bed/unit reference |
| UsageID | int | Usage record reference |
| CountEnroll | int | Count of enrollments |

---

### UVW_ProviderDemographic

System view — flattened provider demographic and location information.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | FK → Entity/Provider |
| ProviderName | nvarchar | Provider name |
| Address | nvarchar | Street address |
| City | nvarchar | City |
| State | char | State |
| ZipCode | char | ZIP code |
| Latitude | float | GPS latitude |
| Longitude | float | GPS longitude |
| OrgName | nvarchar | Parent organization name |
| OrgLatitude | float | Parent org latitude |
| OrgLongitude | float | Parent org longitude |
| CountSubProvider | int | Count of sub-providers |
| TodayDate | datetime | Computed current date |

---

### vw_ClientDocumentCheck_NonTFA

Document compliance view for Non-TFA documents (62 document types).

### vw_ClientDocumentCheck_TFA

Document compliance view for TFA documents (38 document types).

### uvw_ClientHOH

Built-in view that returns Head of Household client information with address details.

| Column | Type | Description |
|--------|------|-------------|
| ClientID | int | FK → Client.EntityID |
| FamilyID | int | FK → Family.FamilyID |
| HOHLastName | nvarchar | HoH last name |
| HohRestriction | int | HoH restriction level |
| Ethnicity | tinyint | HoH ethnicity |
| AddressID | int | FK → ClientAddress.AddressID |
| AddressType | tinyint | Address type |
| Address1 | nvarchar | Street address line 1 |
| Address2 | nvarchar | Street address line 2 |
| City | varchar | City |
| State | char | State |
| ZipCode | char | ZIP code |
| County | nvarchar | County |
| Country | int | Country |
| Neighborhood | nvarchar | Neighborhood |
| Latitude | float | GPS latitude |
| Longitude | float | GPS longitude |
| RuralAreaStatus | int | Rural area status |

**Use case:** Getting HoH demographic and address info for family-level reports.

### UVW_ClientRace

Built-in view that returns client race information in display format.

| Column | Type | Description |
|--------|------|-------------|
| ClientID | int | FK → Client.EntityID |
| RaceName | nvarchar | Single race name |
| RaceString | nvarchar | Concatenated race string (for multi-race clients) |

**Use case:** Displaying race information in reports without joining to ListItem.

---

### uvw_ClientEnrollmentDays

**View** — calculates days enrolled and case size per enrollment member. Useful for length-of-stay reporting.

| Column | Type | Description |
|--------|------|-------------|
| MemberID | int | PK/FK to EnrollmentMember.MemberID |
| EnrollmentID | int | FK to Enrollment.EnrollmentID (required) |
| CaseSize | int | Number of members in the enrollment case |
| DaysEnrolled | int | Calculated number of days the member has been enrolled |

**Key relationships:** uvw_ClientEnrollmentDays → EnrollmentMember (MemberID, 1:1)

---

### X_UVW_MostRecentAcuity

**View** — returns the most recent acuity assessment per client with days since assessment. Custom SVDP view for monitoring assessment currency.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK/FK to EnrollmentMember.ClientID / Entity.EntityID |
| AssessmentID | int | FK to Assessment.AssessmentID — most recent acuity assessment |
| BeginAssessment | datetime | Date the most recent acuity assessment began |
| DaysSinceAssessment | int | Calculated days elapsed since the most recent acuity assessment |

**Key relationships:** X_UVW_MostRecentAcuity → Entity (EntityID, 1:1), X_UVW_MostRecentAcuity → Assessment (AssessmentID, M:1)

---

### X_UVW_Latest90DayRecert

**View** — returns the latest 90-day recertification assessment per client. One row per client regardless of how many enrollments they have.

| Column | Type | Description |
|--------|------|-------------|
| ClientID | int | PK/FK to EnrollmentMember.ClientID / Entity.EntityID |
| AssessmentID | int | FK to Assessment.AssessmentID — latest recertification assessment |
| AssessmentDate | datetime | Date of the latest recertification assessment |
| DaysSinceLastRecert | int | Calculated days since the latest 90-day recertification |

**Key relationships:** X_UVW_Latest90DayRecert → Entity (ClientID, 1:1), X_UVW_Latest90DayRecert → Assessment (AssessmentID, M:1)

---

### X_UVW_MostRecentResubmission

**View** — returns the most recent resubmission date per service. Used to track when a service was last resubmitted for approval or payment processing.

| Column | Type | Description |
|--------|------|-------------|
| ServiceID | int | PK/FK → Service.ServiceID |
| ResubmitDate | date | Date of the most recent resubmission |

**Key relationships:** X_UVW_MostRecentResubmission → Service (ServiceID, 1:1)

---

### UVW_EnrolledMemberCount

**View** — returns count of enrolled members per enrollment with program info. Useful for determining case/family size.

| Column | Type | Description |
|--------|------|-------------|
| EnrollmentID | int | PK/FK to Enrollment.EnrollmentID |
| FamilyID | int | FK to Family (required) |
| FamilyName | nvarchar | Display name of the family (required) |
| Members | int | Count of enrolled members in the enrollment |
| ProgramID | int | FK to Program.ProgramID (required) |
| ProgramName | nvarchar | Display name of the program (required) |

**Key relationships:** UVW_EnrolledMemberCount → Enrollment (EnrollmentID, 1:1), UVW_EnrolledMemberCount → Program (ProgramID, M:1)

---

### UVW_FinancialTotal

**View** — returns financial item totals per assessment/client split into income and expense categories. Used for income and benefits reporting.

| Column | Type | Description |
|--------|------|-------------|
| AssessmentID | int | PK/FK to Assessment.AssessmentID |
| ClientID | int | PK/FK to Entity.EntityID |
| FinancialItemID | int | FK to financial item definition (required) |
| FinancialItemTypeID | int | Type of financial item (required) |
| FinancialDescription | nvarchar | Description of the financial item (required) |
| FinancialCategoryID | int | Category grouping for the financial item |
| Amount | money | Total amount for the financial item |
| IncomeAmount | money | Portion classified as income (required) |
| ExpenseAmount | money | Portion classified as expense (required) |

**Key relationships:** UVW_FinancialTotal → Assessment (AssessmentID, M:1), UVW_FinancialTotal → Entity (ClientID, M:1)

---

### UVW_LatestCaseManager

**View** — returns the most recent case manager assignment per client. One row per client showing the currently assigned case manager.

| Column | Type | Description |
|--------|------|-------------|
| AssignmentID | int | PK/FK to CaseManagerAssignment.AssignmentID |
| ClientID | int | PK/FK to Entity.EntityID |
| EnrollmentID | int | FK to Enrollment.EnrollmentID |
| UserID | int | FK to User — assigned case manager's user ID (required) |
| CaseManager | varchar | Display name of the assigned case manager (required) |

**Key relationships:** UVW_LatestCaseManager → Entity (ClientID, 1:1), UVW_LatestCaseManager → CaseManagerAssignment (AssignmentID, 1:1), UVW_LatestCaseManager → Enrollment (EnrollmentID, M:1)

---

### UVW_IsServiceUsed

**View** — returns whether a service has been used (has associated usage records). Useful for determining if a service type can be safely modified or deactivated.

| Column | Type | Description |
|--------|------|-------------|
| ServiceID | int | FK to Service.ServiceID |
| CountID | int | Count of usage records associated with the service (required) |

**Key relationships:** UVW_IsServiceUsed → Service (ServiceID, M:1)

---

### ClientMailingOrCurrentAddress

**View** — returns client's mailing or current address as a single row. Resolves to one address per client.

| Column | Type | Description |
|--------|------|-------------|
| EntityID | int | PK/FK to Client.EntityID |
| Address | nvarchar | Formatted address string (required) |
| AddressType | int | Type of address returned (mailing or current) |

**Key relationships:** ClientMailingOrCurrentAddress → Client (EntityID, 1:1)

---

### x_uvw_DaysSinceReferral_Dashboard

Custom view — calculates days since referral for the referral dashboard. Shows open/active referrals with elapsed time.

| Column | Type | Description |
|--------|------|-------------|
| XSVdPReferralID | int | FK → XSVdPReferral.XSVdPReferralID |
| EntityID | int | FK → Entity.EntityID (client) |
| FirstName | nvarchar | Client first name |
| LastName | nvarchar | Client last name |
| ReferralDate | datetime | Original referral date |
| X_Date | datetime | Referral date (from XSVdPReferral) |
| X_EndDate | datetime | Referral end date (from XSVdPReferral) |
| X_InternalorExternal | int | FK to ListItem — internal vs external |
| X_ReferralStatus | int | FK to ListItem — current referral status |
| X_ReferralType | int | FK to ListItem — referral type |
| DaysSinceReferral | int | Calculated days since referral was created |

**Key relationships:** x_uvw_DaysSinceReferral_Dashboard → XSVdPReferral (XSVdPReferralID), x_uvw_DaysSinceReferral_Dashboard → Client (EntityID)

**Use case:** Powers the referral dashboard to track aging referrals and identify those needing follow-up. DaysSinceReferral freezes when referral reaches a terminal status.

---

## Programs & Grants

SVDP operates the following program types, each with specific validation rules and allowed values:

| Program | Type | Description |
|---------|------|-------------|
| SSVF | Veteran | Supportive Services for Veteran Families |
| GPD | Veteran | Grant & Per Diem |
| HUD-VASH | Veteran | HUD-VA Supportive Housing |
| RRH | Housing | Rapid Re-Housing |
| HP | Housing | Homelessness Prevention |
| PSH | Housing | Permanent Supportive Housing |
| EHA | Shelter | Emergency Housing Assistance |
| SEHA | Shelter | Special Emergency Housing Assistance |
| ES | Shelter | Emergency Shelter |

**Program Type Numbers** (used for exit destination / prior residence validation):
- Type 4 = PSH
- Type 15 = RRH-style programs
- Type 16 = Other categories
- Each type number determines which exit destinations and prior residences are considered valid.

---

## Data Quality Report Card Fields

The following 62 data points are tracked in the compliance report system (sourced from CaseWorthy via Excel export):

**Client Demographics (14 fields):** Client ID, First Name, Last Name, SSN, Birth Date, Gender, Ethnicity, Race, Veteran Status, Military Branch, Discharge Status, Relation to HoH, Family ID, # Enrolled Family Members

**Staff & Program Info (9 fields):** Case Manager, Position Type, Client Location, Program Type, Program Name, Event, VAMC Station Number, Referred From HUD-VASH, HUD VASH Status

**Enrollment Timeline (11 fields):** Type of Assessment, Assessment ID, Assessment Last Modified Date, Enrollment Status, Begin Date, End Date, Move-In Date, Exit Destination, Days Enrolled, Days Since Last Recert/Update, Last Case Note Completed

**Health & Disabilities (15 fields):** Disabling Condition, Chronic Illness (+ Ongoing), Mental Illness (+ Ongoing), Physical Disability (+ Ongoing), Developmental Disability (+ Ongoing), HIV/AIDS (+ Ongoing), Substance Abuse (+ Ongoing/Continue), Domestic Violence, Health Insurance

**Housing Stability (7 fields):** Prior Residence, Institutional Stay Over 90 Days, Transitional/Perm Housing <7 Nights, Entering From Streets, Subsidy Type, Receiving Shallow Subsidy, Housing Satisfaction Survey (SSVF)

**Income & Benefits (4 fields):** Income, % of AMI, Non-Cash Benefits, Connection With SOAR

**Scoring & Eligibility (2 fields):** Acuity Score Total, HP Eligibility Score

---

## Validation Business Rules

### Blank Value Detection

These values are treated as blank/invalid across all validations:
- `NULL` / empty string
- "unknown" (case-insensitive)
- "data not collected" (case-insensitive)
- "client doesn't know" (case-insensitive)

### Invalid SSNs

- 000-00-0000
- 111-11-1111
- 123-45-6789
- 999-99-9999

### Assessment Events

| Value | Meaning |
|-------|---------|
| 1 | At Entry |
| 2 | During (Update / 90-Day Recertification) |
| 3 | At Exit |

### Soft Delete Convention

- `DeletedDate IS NULL` → Record is active
- `DeletedDate = '12/31/9999'` → Record is NOT deleted (legacy; treat as active)
- Any other date → Record was soft-deleted on that date

---

## Known List Values

This section documents the actual dropdown values for key ListItemCategory IDs used across the system. Values are stored in the `ListItem` table and referenced by integer FK columns throughout CaseWorthy.

### Office Location List (ListID 1000000403)

**List Name:** ClientOfficeList | **Used by:** `Client.X_Office`

| Value | Label |
|-------|-------|
| 1 | Leesburg Office |
| 2 | Mid Florida Office |
| 3 | Orlando Office |
| 4 | Lakeland Office |
| 5 | New Port Richey Office |
| 6 | Pasco – PSH |
| 7 | Sarasota Office |
| 8 | Sarasota – PSH |
| 9 | Tampa Office – SSVF |
| 10 | Tampa Office – Non Veteran |
| 11 | Clearwater Office SSVF |
| 12 | Clearwater Office – Non Veteran |
| 13 | Pinellas Center of Hope Office |
| 14 | Pinellas Care Center Shelter |
| 15 | Sebring Office |
| 16 | Port Charlotte Office |
| 17 | Port Charlotte Care Center Shelter |
| 18 | Fort Myers Office |
| 19 | San Juan Office |
| 99 | Admin |

---

## Known Gaps

This schema reference is compiled from available conversations, project documentation, and form exports. The following areas are **not yet documented** and would require direct database access or CaseWorthy vendor documentation to complete:

1. **Most ListItemCategory IDs** and their associated dropdown values (Office Location list now documented; others still needed)
2. **Workflow/trigger tables** that drive CaseWorthy automation
3. **Audit/history tables** that track field-level changes
4. **Report/Dashboard configuration tables**
5. **Resource/Bed inventory tables** — referenced by UVW_OpenReservation but structure unknown
6. **Category table** — referenced by FamilyCategory, ServiceTypeCategory but structure unknown

**Previously documented as gaps, now resolved:**
- ~~TFA tables~~ — XServiceSVDPAddOns, XProgramSVDPAddOns, programTypeCategoryTFA now documented
- ~~Screening/Pre-Screen tables~~ — XBeforeScreeningWaitList, X_UVW_EnrollmentsAfterWaitlist, X_UVW_DaysSinceWaitlist now documented
- ~~Full Provider/Service schema~~ — Provider expanded with all fields; ServiceExtension, ServiceTypeExt, ServiceTypeMedicalExt, ProgramService, ProgramBilling now documented
- ~~Form definition tables~~ — Form table now documented with full schema
- ~~Assessment extension table details~~ — All 13 assessment extension tables (AssessHUDProgram, XBarrierAssess, XClientHousing, etc.) now fully expanded with column-level documentation
- ~~EnrollmentHMIS and enrollment review tables~~ — EnrollmentHMIS, XEnrollmentReview now documented
- ~~Case note addendum structure~~ — AddendumNotes now documented

---

## Appendix: CaseWorthy Form Export IDs

These XML form exports exist in the documentation directory and map to specific CaseWorthy form configurations:

| File | Form ID | Description (inferred) |
|------|---------|----------------------|
| Form_1000000035_Prod.xml | 1000000035 | Production form |
| Form_1000001069_Prod.xml | 1000001069 | Production form |
| Form_1000001072_UAT.xml | 1000001072 | Staff Cert → Staff Tentative |
| Form_1000001560_UAT.xml | 1000001560 | Screening Sign-off |
| Form_1000001607_UAT.xml | 1000001607 | Updated with Rules |
| Form_1000001650_UAT.xml | 1000001650 | Enrollment Summary → Staff Cert |
| Form_1000001659_Test.xml | 1000001659 | AfterCare Survey |
| Form_1000001660_Test.xml | 1000001660 | AfterCare Summary |
| Form_1000001662_Test.xml | 1000001662 | Test form |
| Form_1000001670_Test.xml | 1000001670 | At Risk Assessment / Summary |
| CaseWorthyObjectExport.xml | — | Full object export |
