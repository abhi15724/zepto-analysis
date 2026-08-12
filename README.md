# Zepto Catalog Intelligence — How This Was Built

## The dataset and the business question

The input was a Zepto product export: 3,729 rows, 9 columns (category, name, MRP,
discount %, available quantity, selling price, weight, stock status, pack quantity) —
a **catalog/inventory snapshot**, not a transaction log. There are no order dates or
customer IDs, so this isn't a "sales over time" dashboard — it's a **product & pricing
intelligence** dashboard answering the questions a category manager would actually ask
of a catalog file: *Which categories carry the most revenue potential? Where are we
losing sales to stock-outs? Is our discounting strategy coherent? And — critically —
can we trust the numbers in the file at all?*

That last question turned out to matter more than any other finding.

## Screenshots

**Welcome screen** — Zepto-branded landing page with the entry point into the dashboard.
![Welcome screen](Welcome screen.png)

**Overview tab** — KPI cards, category slicer, revenue/SKU-share charts, top products table.
![Overview tab](screenshots/02_overview.png)

**Pricing & Discounts tab** — price-band revenue, discount distribution, sortable category detail table.
![Pricing tab](screenshots/03_pricing.png)

**Stock & Data Quality tab** — OOS rate by category, the duplication catch, and written insights.
![Data quality tab](screenshots/04_quality.png)

## The sequence: profile → SQL → Python → Excel → visuals → dashboard

### 1. Profiling caught a serious data quality issue (Python / pandas)
Initial `.info()` / `.duplicated()` / `.value_counts()` checks showed 3,729 rows but
only 1,673 distinct product names. Digging into one repeated name ("Arden Eggs White")
showed the *exact same* product — same price, same stock count, same weight — listed
identically under five different category tags (Cooking Essentials, Munchies, Dairy
Bread & Batter, Beverages, Meats/Fish/Eggs). This wasn't an isolated case: **3,210 of
3,729 rows (86%) were cross-category duplicates** of another row.

**Fix:** deduplicated on (name, MRP, selling price, available quantity, weight, stock
quantity), keeping one row per unique product and assigning it a single primary
category (alphabetical tie-break where a product spanned multiple tags — a real fix
would need a proper category master table, but this removes the double-counting).
Result: **1,800 unique SKUs across 9 primary categories.** Every KPI, chart, and table
in this project uses the deduplicated catalog. The raw file's numbers are shown once,
deliberately, as a before/after comparison — total potential revenue drops from a
misleading Rs 22.4L (raw) to a real Rs 10.6L (deduplicated), a 2.1x overstatement.

Other cleaning: dropped 2 exact duplicate rows and 1 row with a zero price (unusable
for revenue math); converted `mrp` and `discountedSellingPrice` from paise to rupees
(÷100) for readability; added `potential_revenue = selling_price × available_quantity`,
zeroed out for out-of-stock items since they can't generate revenue until restocked.

Cleaned output: `data/cleaned_data.csv` (post dupe/zero-price removal, pre-category-dedupe)
and `data/deduped_catalog.csv` (the 1,800-SKU analysis base).

### 2. SQL layer (SQLite)
`sql/analysis.db` holds the cleaned catalog; `sql/queries.sql` has 10 business-question
queries using real SQL technique — window functions (`RANK()`, `ROW_NUMBER() OVER
(PARTITION BY ...)` for top-N-per-category, running totals), `HAVING` for
above-average-discount categories, and `CASE`-based price banding. SQL was the right
tool here because these are genuinely set-based, group-and-rank questions — "top 5 SKUs
per category," "categories discounting above the catalog average" — that read cleanly
as SQL and awkwardly as pandas loops.

### 3. Python analysis
Beyond cleaning, pandas handled what's awkward in SQL: correlation checks (discount %
vs. price: r ≈ 0.03, essentially no relationship; weight vs. price: r ≈ 0.48, a loose
positive relationship), price-per-100g value ranking, and the discount-depth
distribution. `python/dashboard_data_final.json` is the final aggregated dataset that
feeds the dashboard.

### 4. Excel deliverable (`excel/analysis.xlsx`)
Built for a non-technical stakeholder to open directly:
- **Summary** — headline KPIs as live formulas (`SUM`, `AVERAGE`, `COUNTIF`) against
  the Raw Data tab, plus the data-quality note in plain language.
- **Category Pivot** — `SUMIF`/`AVERAGEIF`/`SUMPRODUCT` formulas per category, with an
  embedded bar chart (revenue by category) and pie chart (SKU share).
- **Raw Data** — the full 1,800-row deduplicated catalog.
- **Data Quality** — the duplication finding written out in full, so anyone auditing
  the numbers can see exactly what was changed and why.
All formulas were recalculated with LibreOffice (`recalc.py`) — 1,861 formulas, 0 errors.

### 5. Visuals (`visuals/*.png`)
Four charts, each built to answer one specific question rather than a generic
"chart everything": revenue by category, OOS rate by category, revenue by price band,
and the duplication before/after comparison.

### 6. The dashboard — `zepto_dashboard.html`
A single self-contained HTML file (Chart.js loaded from a CDN, no build step, no
external data files) delivering the same analysis as an interactive experience:
- **Welcome screen** styled on Zepto's own brand (deep purple, pink-to-orange gradient
  wordmark, yellow accent) with a "Dashboard" button.
- **Overview tab** — KPI cards, a category slicer (click to filter), revenue-by-category
  and SKU-share charts, and a top-10-products table that respects the slicer — the same
  cross-filtering feel as a Power BI report page.
- **Pricing & Discounts tab** — price-band revenue, discount distribution, a sortable
  category detail table, and the correlation findings.
- **Stock & Data Quality tab** — OOS rate by category, the duplication before/after
  chart, and the written insights.
All numbers in the dashboard are pre-aggregated from the deduplicated catalog and
embedded directly in the page — nothing is recalculated live from the raw file, since
the point of this deliverable is the *corrected*, trustworthy view.

## Judgment calls worth knowing about
- **Category dedup uses alphabetical tie-break**, not a "correct" category. A few
  categories (Munchies, Packaged Food, Ice Cream & Desserts, Personal Care, Dairy Bread
  & Batter) don't appear in the deduplicated 9-category view because every product
  under those tags turned out to be a duplicate of a product also tagged with an
  alphabetically-earlier category. This is a simplification flagged for a real fix.
- **"Potential revenue"** is selling price × available quantity, not actual sales — this
  dataset has no transaction history, so this is inventory value at risk/available, not
  realized revenue. It's labeled as such throughout.
- **Pricing and Discount tab charts are catalog-wide**, not filtered by the Overview
  slicer, since price bands and discount bins aren't broken out by category in the
  aggregated data feeding the dashboard.

## Where everything lives
```
zepto-catalog-dashboard/
├── README.md                     (this file)
├── zepto_dashboard.html          (the interactive dashboard — main deliverable)
├── screenshots/
│   └── 01-04_*.png                (dashboard screenshots, referenced above)
├── data/
│   ├── cleaned_data.csv          (post cleaning, pre category-dedupe: 3,729 rows)
│   └── deduped_catalog.csv       (analysis base: 1,800 unique SKUs)
├── sql/
│   ├── analysis.db                (SQLite database)
│   └── queries.sql                (10 business-question queries)
├── python/
│   ├── analysis_output.txt        (full profiling + analysis log)
│   └── dashboard_data_final.json  (aggregated data feeding the dashboard)
├── visuals/
│   └── 01-04_*.png                (4 static charts)
├── excel/
│   └── analysis.xlsx              (client-facing workbook, formulas + charts)
└── insights/
    └── summary.md                 (written business insights)
```
