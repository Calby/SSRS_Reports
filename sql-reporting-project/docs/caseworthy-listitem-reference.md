# CaseWorthy ListItem Reference

This file documents the lists and list items used across CaseWorthy dropdown fields at SVDP CARES. Each section corresponds to a ListItem/ListItemCategory entry in the database.

---

## Job Types (ProgramJobTypeID)

Used by: `x_uvw_LatestUserByJobType.ProgramJobTypeID`, `WorkHistory`, staff assignment forms

> Items marked with **\*** are system/special entries (not standard staff roles).

| Job Type ID | Job Code Description | Job Category | Organizations |
|:-----------:|----------------------|--------------|:-------------:|
| 2 | Grant Accountant | Finance | All |
| 3 | Senior Accountant | Finance | All |
| 17 | Chief Executive Officer **\*** | Executive Staff | All |
| 119 | Administrative Assistant | Administrative | All |
| 120 | Receptionist | Administrative | All |
| 121 | Case Manager Assistant | Case Manager | All |
| 122 | Case Manager | Case Manager | All |
| 123 | SOAR-Case Manager IV | Case Manager | All |
| 126 | Lead Navigator | COH/Care Center Operations | All |
| 129 | Manager-CARE Center | COH/Care Center Operations | All |
| 130 | Navigator | COH/Care Center Operations | All |
| 131 | POD Attendant | COH/Care Center Operations | All |
| 134 | Supervisor Plant Operations | COH/Care Center Operations | All |
| 136 | Quality Improvement Specialist | Compliance | All |
| 137 | Director Of Finance | Finance | All |
| 138 | Director Of Mission | Development | All |
| 142 | Emergency Housing Assistance Specialist I | Emergency Housing Assistance | All |
| 143 | Emergency Housing Assistance Specialist II | Emergency Housing Assistance | All |
| 144 | Emergency Housing Specialist | Emergency Housing Assistance | All |
| 145 | Chief Development Officer | Executive Staff | All |
| 147 | Chief Financial Officer | Executive Staff | All |
| 149 | Chief Of Administrative Services | Executive Staff | All |
| 150 | Chief Of Compliance | Executive Staff | All |
| 151 | Chief Of Homelessness | Executive Staff | All |
| 152 | Chief Of Housing | Executive Staff | All |
| 153 | Chief Of Human Resource | Executive Staff | All |
| 154 | Director of Information Technology | Executive Staff | All |
| 155 | Chief of Staff | Executive Staff | All |
| 157 | Veteran Services Legal Council | Executive Staff | All |
| 158 | Family Coordinator | Family Coordinator | All |
| 159 | Accountant | Finance | All |
| 161 | Grant Specialist | Grants | All |
| 162 | Grants Manager | Grants | All |
| 163 | Healthcare Navigator | Healthcare/Suicide Prevention | All |
| 164 | Housing Locator | Housing | All |
| 165 | Housing Specialist | Housing | All |
| 166 | Employee Engagement/ Wellness Specialist | HR | All |
| 171 | Compliance Officer | IT / Data Compliance | All |
| 172 | Data Entry Specialist | IT / Data Compliance | All |
| 173 | Data Quality Specialist | IT / Data Compliance | All |
| 174 | Data Systems Specialist | IT / Data Compliance | All |
| 175 | IT Specialist I | IT / Data Compliance | All |
| 176 | IT Specialist II | IT / Data Compliance | All |
| 177 | EHA Operations Manager | Operation Manager | All |
| 178 | Operations Manager | Operation Manager | All |
| 179 | Operations Manager Health Care Navigator | Operation Manager | All |
| 180 | Street Outreach Specialist | Peer & Outreach | All |
| 181 | Peer Mentor | Peer & Outreach | All |
| 182 | Peer Mentor/ Outreach II | Peer & Outreach | All |
| 183 | Rapid Resolution Specialist I | Rapid Resolution | All |
| 184 | Rapid Resolution Specialist II | Rapid Resolution | All |
| 185 | Rapid Resolution Specialist III | Rapid Resolution | All |
| 186 | Operations Supervisor | Supervisor | All |
| 188 | Supervisor Center Of Hope | Supervisor | All |
| 189 | Assistant Manager Thrift Store | Thrift Store | All |
| 191 | Driver | Thrift Store | All |
| 192 | Director of COH/CARE Center | COH/Care Center Operations | All |
| 193 | Contracted HMIS Reporting Specialist **\*** | IT / Data Compliance | All |
| 194 | CaseWorthy Staff **\*** | CaseWorthy | All |
| 195 | Employment Specialist **\*** | Boley | All |
| 196 | Donation Processor | Thrift Store | All |
| 198 | Test User **\*** | TEST | All |
| 199 | Paralegal I | Legal | All |
| 200 | Chief of Legal Services | Executive Staff | All |
| 201 | Legal Services Coordinator II | Legal | All |
| 202 | IT Supervisor | IT / Data Compliance | All |
| 203 | Housing Navigator | Housing | All |
| 205 | Aftercare Coordinator | Healthcare/Suicide Prevention | All |
| 206 | Quality Assurance Accountant | Finance | All |
| 207 | SOAR Benefits Specialist | Case Manager | All |
| 208 | Chief Performance Quality Improvement | Executive Staff | All |
| 211 | Operations Support | Administrative | All |
| 10212 | Deputy Chief of Homeless Programs | Executive Staff | All |
| 10213 | Case Manager IV | Case Manager | All |

### Job Type IDs Used in Form Filters

The following IDs are referenced in CaseWorthy form join conditions via `x_uvw_LatestUserByJobType`:

`InList([122, 123, 126, 130, 181, 182, 183, 205, 163])`

| Job Type ID | Role |
|:-----------:|------|
| 122 | Case Manager |
| 123 | SOAR-Case Manager IV |
| 126 | Lead Navigator |
| 130 | Navigator |
| 163 | Healthcare Navigator |
| 181 | Peer Mentor |
| 182 | Peer Mentor/ Outreach II |
| 183 | Rapid Resolution Specialist I |
| 205 | Aftercare Coordinator |

### Job Categories Summary

| Job Category | Count | ID Range |
|--------------|:-----:|----------|
| Administrative | 3 | 119, 120, 211 |
| Boley | 1 | 195 |
| Case Manager | 5 | 121, 122, 123, 207, 10213 |
| CaseWorthy | 1 | 194 |
| COH/Care Center Operations | 6 | 126, 129, 130, 131, 134, 192 |
| Compliance | 1 | 136 |
| Development | 1 | 138 |
| Emergency Housing Assistance | 3 | 142, 143, 144 |
| Executive Staff | 15 | 17, 145, 147, 149–155, 157, 200, 208, 10212 |
| Family Coordinator | 1 | 158 |
| Finance | 5 | 2, 3, 137, 159, 206 |
| Grants | 2 | 161, 162 |
| Healthcare/Suicide Prevention | 2 | 163, 205 |
| Housing | 3 | 164, 165, 203 |
| HR | 1 | 166 |
| IT / Data Compliance | 7 | 171–176, 193, 202 |
| Legal | 2 | 199, 201 |
| Operation Manager | 3 | 177, 178, 179 |
| Peer & Outreach | 3 | 180, 181, 182 |
| Rapid Resolution | 3 | 183, 184, 185 |
| Supervisor | 2 | 186, 188 |
| TEST | 1 | 198 |
| Thrift Store | 3 | 189, 191, 196 |

---

## YesNoDontKnowWontAnswer (List ID: 37)

Used by: HUD Universal Data Element fields (e.g., Veteran Status, Disabling Condition, domestic violence questions). This is the standard HUD response list for yes/no questions that allow "don't know" and "refused" answers.

| Value | Label | Sort Order |
|:-----:|-------|:----------:|
| 1 | Yes | 2 |
| 2 | No | 1 |
| 3 | Client doesn't know | 3 |
| 4 | Client Prefers Not to Answer | 4 |
| 99 | Data Not Collected | 99 |

**Notes:**
- Sorted by Sort Order, so **No** appears first in dropdowns
- Enabled for Everyone, all items Selectable
- Not categorized
- Values 1/2 are valid responses; values 3, 4, 99 are typically flagged in data quality checks

---

<!-- Additional lists will be added below as they are documented -->
