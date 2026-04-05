# Report Index

Active report inventory. Update this file whenever a report is added, modified,
or retired. Include the dataset query file name and the SSRS .rdl file name.

---

## Active SSRS Reports

| Report Name                    | Program | File (RDL)                            | Dataset Query                              | Owner / Requester | Status   | Last Updated |
|-------------------------------|---------|---------------------------------------|--------------------------------------------|-------------------|----------|--------------|
| Monthly Service Report         | SSVF    | SSVF_MonthlyServiceReport.rdl         | SSVF_MonthlyServiceReport_dataset.sql      |                   | Active   |              |
| Exit Destinations              | GPD     | GPD_ExitDestinations.rdl              | GPD_ExitDestinations_dataset.sql           |                   | Active   |              |
| PSH Monthly Contact            | PSH     | PSH_MonthlyContact.rdl                | PSH_MonthlyContact_dataset.sql             |                   | Active   |              |
| Assessment Sign-Off Backlog    | All     | ALL_AssessmentSignOffBacklog.rdl      | ALL_AssessmentSignOffBacklog_dataset.sql   |                   | Active   |              |
| Screening Sign-Off Report      | All     | ALL_ScreeningSignOff.rdl              | ALL_ScreeningSignOff_dataset.sql           |                   | Active   |              |
| VA Corrections Report          | HUDVASH | HUDVASH_VACorrections.rdl             | HUDVASH_VACorrections_dataset.sql          |                   | Active   |              |
| Referral Closed Report         | All     | ALL_ReferralClosed.rdl                | ALL_ReferralClosed_dataset.sql             |                   | Active   |              |
| Healthcare Nav Eligibility     | HCN     | HCN_EligibilityReport.rdl             | HCN_EligibilityReport_dataset.sql          |                   | Active   |              |

---

## Custom Views (x_uvw_)

| View Name                          | Purpose                                     | Used By (Reports)              | Last Updated |
|------------------------------------|---------------------------------------------|--------------------------------|--------------|
| x_uvw_ActiveEnrollmentsByProgram   | Active enrollments with program detail      | Multiple                       |              |
| x_uvw_SSVFServiceSummary           | SSVF service totals by client               | SSVF Monthly Service Report    |              |
| x_uvw_AssessmentSignOffStatus      | Assessment sign-off status across offices   | Assessment Sign-Off Backlog    |              |
| x_uvw_GPDExitDestinations          | GPD exit records with destination codes     | GPD Exit Destinations          |              |

---

## Reports in Development

| Report Name            | Program | Target Date | Notes                                  |
|------------------------|---------|-------------|----------------------------------------|
| [Add here]             |         |             |                                        |

---

## Retired / Deprecated Reports

| Report Name            | Program | Retired Date | Replacement            |
|------------------------|---------|--------------|------------------------|
| [Add here]             |         |              |                        |

---

*To add a new report: use /project:new-report to scaffold the spec and query stub,
then add a row to this table when the report is deployed.*
