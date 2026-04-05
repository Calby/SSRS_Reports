# SSRS Templates

Blank or starter .rdl files to use as the basis for new reports.
Avoids rebuilding common layout, headers, footers, and data sources from scratch.

## Available Templates

| File                          | Description                                         |
|-------------------------------|-----------------------------------------------------|
| _blank-tabular.rdl            | Blank tablix with standard header/footer            |
| _blank-grouped.rdl            | Grouped tablix with subtotals at group level        |
| _blank-with-chart.rdl         | Tablix + bar chart side by side                     |

## How to Use
1. Copy the appropriate template into ssrs/published/
2. Rename to [ProgramCode]_[ReportName].rdl
3. Open in Visual Studio / Report Builder
4. Replace the placeholder data source with the project data source
5. Add your dataset query
6. Build out the layout

## Standard Layout Rules (applied in all templates)
- Page header: Report title (left) | Date range (center) | Program (right)
- Page footer: Run date/time (left) | Page X of Y (right)
- Font: Segoe UI, 9pt body, 10pt column headers, 11pt report title
- Column headers: light gray background (#E8E8E8), bold
- Alternating row color: white / very light gray (#F5F5F5)
- Group header rows: slightly darker gray (#D0D0D0), bold
