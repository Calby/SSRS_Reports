# /project:review-query

Review the current SQL file or the query I've pasted for the following:

## Logic & Correctness
- Are the JOIN conditions correct and complete?
- Is the WHERE clause filtering what's intended?
- Are there any implicit cross joins or unintended Cartesian products?
- Is NULL handling correct (using IS NULL / IS NOT NULL, not = NULL)?
- Are date comparisons safe? (BETWEEN is inclusive on both ends)
- Could any aggregation produce unexpected results due to duplicates?

## Performance
- Are there any obvious missing index candidates (columns in WHERE/JOIN not indexed)?
- Is SELECT * used anywhere? Flag it — alias all columns explicitly.
- Are there unnecessary subqueries that could be CTEs or JOINs?
- Is DISTINCT used where it shouldn't need to be (symptom of a bad join)?

## Style & Standards
- ALL CAPS keywords?
- CTEs preferred over nested subqueries?
- Are all columns aliased with meaningful names?
- Does it follow the naming convention in .claude/rules/naming-conventions.md?
- Is there a comment block at the top explaining what the query does?

## HMIS / Compliance
- Does anything return PHI/PII that shouldn't? (Flag client names, SSNs, DOBs)
- If this is program-filtered, is the program logic correct for the grant type?
- See .claude/rules/hmis-compliance.md for data element rules.

## Output Format
- Give specific line numbers for issues.
- Rate each issue: [CRITICAL] [WARN] [STYLE]
- Summarize findings in 3-5 bullets at the top before details.
