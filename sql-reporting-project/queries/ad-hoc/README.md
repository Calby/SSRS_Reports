# Ad Hoc Queries

One-off analysis and exploration queries. Not tied to any SSRS report.

## Naming Convention
[YYYY-MM-DD]_[brief-description].sql

## Rules
- Always include a header comment block explaining what the query does and why
- Never return PHI/PII (names, SSNs, DOBs) in a file that will be shared
- Use ClientID only in shareable outputs
- These are scratch queries — review with /project:review-query before sharing results with leadership

## File Retention
Ad hoc queries older than 90 days that aren't referenced by any report can be archived or deleted.
Add a comment at the top if a query should be kept for reference: -- KEEP: [reason]
