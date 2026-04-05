# HMIS Compliance Rules

## What This File Is For
Rules and logic for building reports that must conform to HUD HMIS data
standards. Reference this when building any federally-funded program report.

---

## Universal Exit Destination Logic (HUD Element 3.12)
Exit destinations determine housing outcomes. When reporting on exits:

**Permanent Housing Destinations (positive exits):**
Place of employment, owned by client, rental by client, staying with family
(permanent), staying with friends (permanent), permanent housing for formerly
homeless persons, etc.

**Temporary Destinations:**
Hotel/motel (no voucher), staying with family (temporary), transitional
housing, etc.

**Institutional:**
Jail/prison, psychiatric facility, substance abuse treatment, hospital, etc.

**Other / Unknown:**
Deceased, don't know, refused, data not collected, no exit interview completed

> Flag any report that calculates "housing placement rate" — confirm with program
> manager which destination codes count as "housed" for their specific funder.

---

## Program Type Flags and Their Reporting Rules

### SSVF (Supportive Services for Veterans Families)
- Funder: VA
- Key metrics: Veteran households served, housing stability, recidivism
- Eligibility: Must be a veteran household at or below 50% AMI
- Key date logic: Services tracked within the grant year (typically Oct 1–Sep 30)
- PHI caution: SSVF data has stricter sharing restrictions — confirm before exporting

### GPD (Grant Per Diem)
- Funder: VA
- Key metrics: Bed nights, exits to permanent housing, average length of stay
- Date logic: Report on bed nights within date range, not enrollments
- Note: Transitional housing — most clients have exits to permanent housing as goal

### HUD-VASH
- Funder: HUD + VA
- Key metrics: Voucher utilization, housed rate
- Enrollment tied to HCV voucher assignment

### PSH (Permanent Supportive Housing)
- Key metrics: Monthly contact, housing retention, incident reporting
- Clients should have no exit date while housed — flag any PSH exit to non-permanent destination

### RRH (Rapid Rehousing)
- Key metrics: Time to house, housing placement rate, recidivism
- Short-term intervention — watch for clients cycling back in

### CoC / ESG
- Funder: HUD
- Annual Performance Report (APR) metrics apply
- HMIS data quality is critical — flag missing Universal Data Elements

### SOAR (SSI/SSDI Outreach, Access, Recovery)
- Key metric: SSI/SSDI applications and approvals
- Smaller program — tends to be single-office

---

## Universal Data Elements (UDEs) — Must Not Be Missing
These fields are required on all HMIS enrollments. Flag in data quality reports
if missing or "Don't know" / "Refused" / "Data not collected":

- Name (can be alias)
- SSN (partial acceptable)
- Date of Birth
- Race / Ethnicity
- Gender
- Veteran Status
- Disabling Condition
- Prior Living Situation (Element 3.917)
- Housing Status at Entry

---

## PHI / PII Handling in Queries
- Never return client names, SSNs, DOBs, or addresses in ad hoc query outputs
  that will be shared outside the immediate data team
- Use ClientID only in shared outputs unless explicitly authorized
- SSVF data: treat as more restricted — confirm before any export
- ServTracker participant data: governed by aging services privacy rules —
  different from HMIS rules, verify with program before sharing

---

## Data Quality Red Flags to Check in Any Report
- Enrollment date after exit date
- Exit date before enrollment date
- Age calculated as < 0 or > 120
- Active enrollment with exit date in the future
- Missing program assignment on enrollment
- Duplicate active enrollments in the same program for the same client
