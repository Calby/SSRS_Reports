# /project:optimize

Analyze the current SQL query for performance issues and suggest improvements.

## What to Check:

**Execution path issues**
- Table scan vs. index seek candidates — which columns in WHERE/JOIN likely lack indexes?
- Are there any DISTINCT calls masking a bad join (driving up row counts before filtering)?
- Is there a HAVING clause that could be a WHERE clause instead?
- Are functions applied to indexed columns in WHERE (killing index use)?
  Example: WHERE YEAR(EnrollmentDate) = 2025 — bad. Use range instead.

**CTE and subquery structure**
- Could any subquery be a CTE for readability and potential optimization?
- Are any CTEs referenced more than once? (May need temp table or materialization)
- Could a correlated subquery be rewritten as a JOIN?

**Data volume**
- Where is the largest table in the join order?
- Is filtering happening as early as possible, or after a large join?
- Are there any CROSS JOINs or unintended Cartesian products?

**Specific to CaseWorthy / ServTracker**
- Are enrollment date range filters using indexed columns?
- When filtering by program, are you using ProgramID (int) not ProgramName (string)?
- Are you joining through the correct bridge tables for services vs. enrollments?

## Output Format
1. Top 3 highest-impact changes (with rewritten snippet)
2. Secondary recommendations
3. What NOT to change (things that look odd but are intentional)
