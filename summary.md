# Business Insights — Zepto Catalog Analysis

*Base: 1,800 unique SKUs (deduplicated from a 3,729-row raw export). Figures in Rs.*

## 1. The raw file overstates revenue by 2.1x — fix category tagging before trusting any report on this data
86% of the raw export's rows (3,210 of 3,729) are exact duplicates of another row,
differing only in category label. Total "potential revenue" reads as Rs 22.4L in the
raw file vs. the real Rs 10.6L once deduplicated. **Recommendation:** audit the export
pipeline for whatever process is tagging one product with multiple categories, and
treat any historical report built on this raw feed as unreliable until reprocessed.

## 2. Revenue is concentrated in two categories; core grocery categories are under-weighted
Cooking Essentials (Rs 3.08L) and Paan Corner (Rs 2.50L) together hold 53% of total
potential revenue from 750 of 1,800 SKUs. Meanwhile Fruits & Vegetables (Rs 10,636) and
Meats, Fish & Eggs (Rs 9,702) — categories core to a "10-minute grocery" positioning —
contribute under 2% combined. **Recommendation:** investigate whether this reflects a
genuine assortment gap (too few fresh SKUs listed) or a pricing issue (fresh items
priced too low to show revenue weight); either is worth a follow-up pull of full
transaction data.

## 3. Biscuits and perishable-adjacent categories have the worst stock availability
Biscuits (28.6% OOS) and Meats/Fish/Eggs (21.9% OOS) run out far more than the catalog
average (12.1%). Biscuits combine this with the lowest average price (Rs 52.78) —
a high-friction, low-margin category. **Recommendation:** prioritize replenishment
frequency for Biscuits specifically; a stock-out on a low-price, high-frequency item
likely costs more in customer churn than the SKU's own revenue suggests.

## 4. Mid-priced items, not the cheapest ones, drive the most revenue
The Rs150–299 price band generates Rs 4.16L from 451 SKUs — more than the under-Rs50
band's Rs 45,472 from 786 SKUs (nearly double the SKU count for a tenth of the
revenue). **Recommendation:** if merchandising or promotional budget is being weighted
toward cheap, high-volume items, this data suggests the mid-price band deserves at
least equal attention as a revenue lever.

## 5. Discounting looks category-driven, not price- or margin-driven
Discount percentage barely correlates with selling price (r ≈ 0.03) — Zepto discounts
a Rs 20 item and a Rs 2,000 item by roughly the same average percentage. Fruits &
Vegetables carry the deepest average discount (15.96%) despite already being the
cheapest category overall, consistent with a perishability-driven markdown rather than
a considered margin strategy. **Recommendation:** if discount budget is meant to drive
incremental revenue rather than just move perishables, a price-tier-aware discount
policy (deeper cuts on high-price, high-margin items) may perform better than the
current flat, category-by-category approach.
