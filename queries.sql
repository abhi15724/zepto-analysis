-- ============================================================
-- Zepto Product Catalog — Business Question Queries
-- Table: products (cleaned catalog snapshot, 3,729 SKUs)
-- ============================================================

-- Q1: Which categories hold the most potential revenue (in-stock value)?
SELECT Category,
       COUNT(*) AS sku_count,
       ROUND(SUM(potential_revenue), 2) AS total_potential_revenue,
       ROUND(AVG(selling_price_rs), 2) AS avg_selling_price
FROM products
GROUP BY Category
ORDER BY total_potential_revenue DESC;

-- Q2: Category ranked by revenue with % share and running total (window functions)
SELECT Category,
       ROUND(SUM(potential_revenue), 2) AS revenue,
       ROUND(100.0 * SUM(potential_revenue) / (SELECT SUM(potential_revenue) FROM products), 2) AS pct_of_total,
       ROUND(SUM(SUM(potential_revenue)) OVER (ORDER BY SUM(potential_revenue) DESC), 2) AS running_total,
       RANK() OVER (ORDER BY SUM(potential_revenue) DESC) AS revenue_rank
FROM products
GROUP BY Category
ORDER BY revenue DESC;

-- Q3: Out-of-stock rate by category (which categories are hardest to keep on shelf?)
SELECT Category,
       COUNT(*) AS total_skus,
       SUM(CASE WHEN outOfStock='True' OR outOfStock=1 THEN 1 ELSE 0 END) AS oos_skus,
       ROUND(100.0 * SUM(CASE WHEN outOfStock='True' OR outOfStock=1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS oos_rate_pct
FROM products
GROUP BY Category
HAVING oos_skus > 0
ORDER BY oos_rate_pct DESC;

-- Q4: Top 5 highest-revenue SKUs per category (window function: ROW_NUMBER per partition)
SELECT Category, name, selling_price_rs, availableQuantity, potential_revenue
FROM (
  SELECT Category, name, selling_price_rs, availableQuantity, potential_revenue,
         ROW_NUMBER() OVER (PARTITION BY Category ORDER BY potential_revenue DESC) AS rn
  FROM products
  WHERE outOfStock = 'False' OR outOfStock = 0
)
WHERE rn <= 5
ORDER BY Category, potential_revenue DESC;

-- Q5: Discount depth vs. category — who discounts hardest?
SELECT Category,
       ROUND(AVG(discountPercent), 2) AS avg_discount_pct,
       ROUND(MAX(discountPercent), 2) AS max_discount_pct,
       COUNT(CASE WHEN discountPercent = 0 THEN 1 END) AS zero_discount_skus
FROM products
GROUP BY Category
ORDER BY avg_discount_pct DESC;

-- Q6: Price band distribution — how many SKUs fall in each price tier?
SELECT CASE
         WHEN selling_price_rs < 50 THEN '1. Under Rs 50'
         WHEN selling_price_rs < 150 THEN '2. Rs 50-149'
         WHEN selling_price_rs < 300 THEN '3. Rs 150-299'
         WHEN selling_price_rs < 500 THEN '4. Rs 300-499'
         ELSE '5. Rs 500+'
       END AS price_band,
       COUNT(*) AS sku_count,
       ROUND(SUM(potential_revenue), 2) AS revenue_in_band
FROM products
GROUP BY price_band
ORDER BY price_band;

-- Q7: Categories with the best discount-to-revenue efficiency (HAVING clause)
SELECT Category,
       ROUND(AVG(discountPercent), 2) AS avg_discount_pct,
       ROUND(SUM(potential_revenue), 2) AS revenue
FROM products
GROUP BY Category
HAVING AVG(discountPercent) > (SELECT AVG(discountPercent) FROM products)
ORDER BY revenue DESC;

-- Q8: Top 15 individual SKUs by potential revenue, company-wide
SELECT name, Category, selling_price_rs, availableQuantity, potential_revenue
FROM products
WHERE outOfStock = 'False' OR outOfStock = 0
ORDER BY potential_revenue DESC
LIMIT 15;

-- Q9: Weight-normalized value — best "value per 100g" products (cheapest per unit weight)
SELECT name, Category, weightInGms, selling_price_rs,
       ROUND(selling_price_rs / NULLIF(weightInGms, 0) * 100, 2) AS price_per_100g
FROM products
WHERE weightInGms > 0
ORDER BY price_per_100g ASC
LIMIT 10;

-- Q10: Overall catalog health summary (single-row KPI check)
SELECT COUNT(*) AS total_skus,
       COUNT(DISTINCT Category) AS categories,
       ROUND(SUM(potential_revenue), 2) AS total_potential_revenue,
       ROUND(100.0 * SUM(CASE WHEN outOfStock='True' OR outOfStock=1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS overall_oos_rate,
       ROUND(AVG(discountPercent), 2) AS avg_discount_pct
FROM products;
