USE video_game_store;
-- ==================================================================================
-- 1. Store Performance Dashboard (Report Query with Grouped KPIs)
-- Goal: Monthly report per store: Revenue, Trans count, Avg Value, Return Rate, MoM Growth.
-- Complexity: Window Functions (LAG), Aggregation, Date Grouping
-- ==================================================================================
SELECT s.store_name,
    DATE_FORMAT(p.purchase_date, '%Y-%m') AS report_month,
    COUNT(DISTINCT p.purchase_id) AS total_transactions,
    SUM(p.total_amount) AS total_revenue,
    ROUND(AVG(p.total_amount), 2) AS avg_transaction_value,
    SUM(pi.quantity) AS total_items_sold,
    -- Calculate Return Rate (Value of Returns / Total Revenue)
    ROUND(
        IFNULL(SUM(r.refund_amount), 0) / NULLIF(SUM(p.total_amount), 0) * 100,
        2
    ) AS return_rate_pct,
    -- Month-over-Month Revenue Growth using LAG
    ROUND(
        (
            SUM(p.total_amount) - LAG(SUM(p.total_amount)) OVER (
                PARTITION BY s.store_id
                ORDER BY DATE_FORMAT(p.purchase_date, '%Y-%m')
            )
        ) / LAG(SUM(p.total_amount)) OVER (
            PARTITION BY s.store_id
            ORDER BY DATE_FORMAT(p.purchase_date, '%Y-%m')
        ) * 100,
        2
    ) AS mom_growth_pct
FROM Store s
    JOIN Purchase p ON s.store_id = p.store_id
    JOIN PurchaseItem pi ON p.purchase_id = pi.purchase_id
    LEFT JOIN `Return` r ON p.purchase_id = r.purchase_id
GROUP BY s.store_id,
    s.store_name,
    report_month
ORDER BY s.store_name,
    report_month DESC;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 2. Customer Lifetime Value with Cohort Ranking (Window Function)
-- Goal: Rank customers within their "Join Month" cohort based on Net Value (Spend - Returns).
-- Complexity: Window Functions (RANK), Subqueries, Date Extraction
-- ==================================================================================
WITH CustomerFinancials AS (
    SELECT c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATE_FORMAT(c.join_date, '%Y-%m') AS join_cohort,
        COUNT(DISTINCT p.purchase_id) AS purchase_count,
        SUM(p.total_amount) AS total_spend,
        IFNULL(SUM(r.refund_amount), 0) AS total_returns,
        (
            SUM(p.total_amount) - IFNULL(SUM(r.refund_amount), 0)
        ) AS net_value
    FROM Customer c
        JOIN Purchase p ON c.customer_id = p.customer_id
        LEFT JOIN `Return` r ON p.purchase_id = r.purchase_id
    GROUP BY c.customer_id,
        c.first_name,
        c.last_name,
        c.join_date
    HAVING purchase_count >= 2
)
SELECT join_cohort,
    customer_name,
    purchase_count,
    total_spend,
    total_returns,
    net_value,
    RANK() OVER (
        PARTITION BY join_cohort
        ORDER BY net_value DESC
    ) AS cohort_rank
FROM CustomerFinancials
ORDER BY join_cohort DESC,
    cohort_rank;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 3. Products Requiring Urgent Restocking (Correlated Subquery with EXISTS)
-- Goal: Find products below threshold that have actually sold in the last 90 days.
-- Complexity: EXISTS clause, Date Arithmetic
-- ==================================================================================
SELECT s.store_name,
    p.name AS product_name,
    v.name AS vendor,
    i.quantity_available,
    i.restock_threshold,
    (i.restock_threshold - i.quantity_available) AS suggested_order_qty
FROM Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Vendor v ON p.vendor_id = v.vendor_id
    JOIN Store s ON i.store_id = s.store_id
WHERE i.quantity_available <= i.restock_threshold -- Ensure the product is active/selling (Sold within the last 90 days relative to Jan 2024)
    AND EXISTS (
        SELECT 1
        FROM PurchaseItem pi
            JOIN Purchase pu ON pi.purchase_id = pu.purchase_id
        WHERE pi.inventory_id = i.inventory_id
            AND pu.purchase_date >= '2023-10-01' -- Adjusted date for seed data
    )
ORDER BY s.store_name,
    i.quantity_available ASC;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 4. Vendor Quality Scorecard (Multiple Aggregation Levels)
-- Goal: Rank vendors by a composite score (Revenue, Ratings, Low Returns).
-- Complexity: Multiple Joins, Derived Metrics, Subqueries
-- ==================================================================================
SELECT v.name AS vendor_name,
    COUNT(DISTINCT pi.purchase_item_id) AS total_units_sold,
    SUM(pi.line_total) AS total_revenue,
    ROUND(AVG(rev.rating), 1) AS avg_product_rating,
    -- Calculate Return Percentage
    ROUND(
        COUNT(DISTINCT ri.return_item_id) / COUNT(DISTINCT pi.purchase_item_id) * 100,
        1
    ) AS return_rate_pct,
    -- Composite Score: (Revenue/1000) + (Rating * 20) - (Return Rate * 5)
    ROUND(
        (SUM(pi.line_total) / 1000) + (IFNULL(AVG(rev.rating), 3) * 20) - (
            (
                COUNT(DISTINCT ri.return_item_id) / COUNT(DISTINCT pi.purchase_item_id) * 100
            ) * 5
        ),
        0
    ) AS quality_score
FROM Vendor v
    JOIN Product p ON v.vendor_id = p.vendor_id
    JOIN Inventory i ON p.product_id = i.product_id
    JOIN PurchaseItem pi ON i.inventory_id = pi.inventory_id
    LEFT JOIN Review rev ON p.product_id = rev.product_id
    LEFT JOIN ReturnItem ri ON pi.purchase_item_id = ri.purchase_item_id
GROUP BY v.vendor_id,
    v.name
ORDER BY quality_score DESC;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 5. Employee Sales Performance (Window Function for Ranking)
-- Goal: Rank employees by Revenue, identifying their contribution to Loyalty vs Walk-in sales.
-- Complexity: Conditional Aggregation (CASE), Window Function (PERCENT_RANK)
-- ==================================================================================
SELECT e.first_name,
    e.last_name,
    s.store_name,
    COUNT(p.purchase_id) AS transactions_processed,
    SUM(p.total_amount) AS total_revenue,
    -- Percentage of revenue from loyalty members
    ROUND(
        SUM(
            CASE
                WHEN p.customer_id IS NOT NULL THEN p.total_amount
                ELSE 0
            END
        ) / SUM(p.total_amount) * 100,
        1
    ) AS loyalty_sales_pct,
    -- Percentile Rank compared to all employees
    ROUND(
        PERCENT_RANK() OVER (
            ORDER BY SUM(p.total_amount)
        ),
        2
    ) AS revenue_percentile
FROM Employee e
    JOIN Store s ON e.store_id = s.store_id
    JOIN Purchase p ON e.employee_id = p.employee_id
WHERE p.purchase_date BETWEEN '2023-10-01' AND '2024-01-31' -- Q4 2023 + Jan 2024
GROUP BY e.employee_id,
    e.first_name,
    e.last_name,
    s.store_name
ORDER BY total_revenue DESC;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 6. Platform and ESRB Mix Analysis (CTE)
-- Goal: Compare sales distribution by Platform and Rating between periods.
-- Complexity: CTE, Percentage Calculation
-- ==================================================================================
WITH SalesMix AS (
    SELECT p.platform,
        p.esrb_rating,
        -- Group dates into periods (using Month for seed data context)
        CASE
            WHEN pu.purchase_date BETWEEN '2023-10-01' AND '2023-11-30' THEN 'Period_1'
            WHEN pu.purchase_date BETWEEN '2023-12-01' AND '2024-01-31' THEN 'Period_2'
        END AS period,
        SUM(pi.line_total) AS revenue
    FROM Product p
        JOIN Inventory i ON p.product_id = i.product_id
        JOIN PurchaseItem pi ON i.inventory_id = pi.inventory_id
        JOIN Purchase pu ON pi.purchase_id = pu.purchase_id
    GROUP BY p.platform,
        p.esrb_rating,
        period
    HAVING period IS NOT NULL
)
SELECT s1.platform,
    s1.esrb_rating,
    s1.revenue AS period_1_rev,
    s2.revenue AS period_2_rev,
    CONCAT(
        ROUND(
            ((s2.revenue - s1.revenue) / s1.revenue * 100),
            1
        ),
        '%'
    ) AS growth_pct
FROM SalesMix s1
    JOIN SalesMix s2 ON s1.platform = s2.platform
    AND s1.esrb_rating = s2.esrb_rating
WHERE s1.period = 'Period_1'
    AND s2.period = 'Period_2'
ORDER BY (s2.revenue - s1.revenue) DESC;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 7. Products with Rating-Return Mismatch (Subquery & HAVING)
-- Goal: Find High Rating/High Return OR Low Rating/Low Return products.
-- Complexity: Subqueries, HAVING Clause with complex logic
-- ==================================================================================
SELECT p.name,
    p.platform,
    AVG(rev.rating) AS avg_rating,
    COUNT(DISTINCT pi.purchase_item_id) AS units_sold,
    COUNT(DISTINCT ri.return_item_id) AS units_returned,
    (
        COUNT(DISTINCT ri.return_item_id) / COUNT(DISTINCT pi.purchase_item_id)
    ) * 100 AS return_rate_pct
FROM Product p
    JOIN Inventory i ON p.product_id = i.product_id
    JOIN PurchaseItem pi ON i.inventory_id = pi.inventory_id
    LEFT JOIN Review rev ON p.product_id = rev.product_id
    LEFT JOIN ReturnItem ri ON pi.purchase_item_id = ri.purchase_item_id
GROUP BY p.product_id,
    p.name,
    p.platform
HAVING -- Scenario A: Good Rating (>4) but High Returns (>15%)
    (
        avg_rating >= 4.0
        AND return_rate_pct > 15
    )
    OR -- Scenario B: Bad Rating (<3) but Low Returns (<5%) - potentially suspicious
    (
        avg_rating <= 3.0
        AND return_rate_pct < 5
    )
ORDER BY return_rate_pct DESC;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 8. Cross-Store Inventory Transfer Recommendations (Self-Join + EXISTS)
-- Goal: Suggest transfers from Overstocked Store -> Understocked Store.
-- Complexity: Self-Join on Inventory, Logic Comparison
-- ==================================================================================
SELECT p.name AS product_name,
    s_source.store_name AS source_store,
    inv_source.quantity_available AS source_qty,
    s_dest.store_name AS dest_store,
    inv_dest.quantity_available AS dest_qty,
    FLOOR(
        (
            inv_source.quantity_available - inv_source.restock_threshold
        ) / 2
    ) AS transfer_suggestion
FROM Inventory inv_source
    JOIN Inventory inv_dest ON inv_source.product_id = inv_dest.product_id
    AND inv_source.store_id != inv_dest.store_id
    JOIN Product p ON inv_source.product_id = p.product_id
    JOIN Store s_source ON inv_source.store_id = s_source.store_id
    JOIN Store s_dest ON inv_dest.store_id = s_dest.store_id
WHERE -- Source is Overstocked (> 2x Threshold)
    inv_source.quantity_available > (inv_source.restock_threshold * 2) -- Destination is Understocked (Below Threshold)
    AND inv_dest.quantity_available < inv_dest.restock_threshold
ORDER BY p.name;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 9. Customer Purchase Pattern Analysis (Window Function LAG)
-- Goal: Calculate days since last purchase for repeat customers.
-- Complexity: Window Function (LAG), Date Difference
-- ==================================================================================
SELECT c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    p.purchase_date,
    -- Calculate days since previous purchase
    DATEDIFF(
        p.purchase_date,
        LAG(p.purchase_date) OVER (
            PARTITION BY c.customer_id
            ORDER BY p.purchase_date
        )
    ) AS days_since_last_purchase,
    p.total_amount
FROM Customer c
    JOIN Purchase p ON c.customer_id = p.customer_id
ORDER BY c.customer_id,
    p.purchase_date;
SELECT '===============================================================================' AS '';
-- ==================================================================================
-- 10. Margin Analysis by Category with Low-Margin High-Volume Alert (CTE)
-- Goal: Identify low margin items (<40% margin) that are in the top sales tier within their category.
-- Complexity: CTE, Window Function (NTILE), Margin Calculation
-- ==================================================================================
WITH ProductMargins AS (
    SELECT c.name AS category_name,
        p.name AS product_name,
        SUM(pi.quantity) AS total_sold,
        -- Margin = (Current Price - Purchase Price) / Current Price
        -- Note: using AVG prices from inventory for the calculation
        AVG(
            (i.current_price - i.purchase_price) / i.current_price
        ) * 100 AS margin_pct
    FROM Product p
        JOIN Category c ON p.category_id = c.category_id
        JOIN Inventory i ON p.product_id = i.product_id
        JOIN PurchaseItem pi ON i.inventory_id = pi.inventory_id
    GROUP BY c.name,
        p.product_id,
        p.name
),
RankedSales AS (
    SELECT *,
        -- Divide products into 4 quartiles based on sales volume within category
        NTILE(4) OVER (
            PARTITION BY category_name
            ORDER BY total_sold DESC
        ) AS sales_quartile
    FROM ProductMargins
)
SELECT category_name,
    product_name,
    total_sold,
    ROUND(margin_pct, 2) AS margin_pct,
    'High Volume / Low Margin' AS alert_type
FROM RankedSales
WHERE sales_quartile = 1 -- Top 25% by volume
    AND margin_pct < 40 -- Margin under 40% (adjusted for video game industry standards)
ORDER BY margin_pct ASC;