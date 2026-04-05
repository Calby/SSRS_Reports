# /project:new-view

Scaffold a new SQL view following the x_uvw_ naming convention.

## Step 1 — Ask me:
1. What will this view expose? (What data, what grain?)
2. What is the intended consumer? (SSRS report, ad hoc queries, dashboard, Python script)
3. What base tables will it draw from?
4. Are there any filters that should be baked in? (e.g., active records only)
5. Should this replace an existing view, or is it net new?

## Step 2 — Generate the view file at: queries/views/x_uvw_[Description].sql

Use this structure:
```sql
-- ============================================================
-- View:    x_uvw_[Description]
-- Purpose: [What this view exposes and why]
-- Grain:   [One row per: client / enrollment / service / etc.]
-- Used By: [Report names or consumers]
-- Created: [YYYY-MM-DD]
-- Author:  [Placeholder]
-- Changes: [Date] - [What changed and why]
-- ============================================================

CREATE OR ALTER VIEW x_uvw_[Description]
AS

WITH
[LogicalCTE1] AS (
    -- [Explain what this CTE isolates]
    SELECT
        [columns]
    FROM [Table]
    WHERE [filters]
),

[LogicalCTE2] AS (
    -- [Explain what this CTE isolates]
    ...
)

SELECT
    [alias all columns explicitly]
FROM [LogicalCTE1] a
JOIN [LogicalCTE2] b ON a.[Key] = b.[Key]

GO
```

## Step 3 — Add an entry to docs/schema-overview.md under the Views section.
