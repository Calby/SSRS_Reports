# /project:explain

Explain what the current SQL file or selected query does in plain English.

Target audience: a technically literate colleague or program manager who
understands what reports are for but doesn't write SQL.

## Structure Your Explanation As:

**What it does** (1-2 sentences max)
What data this produces and why someone would run it.

**Key inputs**
- What parameters does it accept? (date range, program, office, etc.)
- What tables / views does it pull from?

**What it returns**
- What does each column represent?
- Is it one row per client, per enrollment, per service, per month?
- What's the grain of this dataset?

**Filters and business logic**
- Who is included vs. excluded and why?
- Any special handling (active only, exit within range, specific program types)?

**Gotchas or assumptions**
- Any known edge cases or data quality issues to be aware of?
- Any hardcoded values that should be noted?

**Where it fits**
- Is this a dataset for an SSRS report? An ad hoc request? A view?
- Which report or use case does this support?
