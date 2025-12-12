USE video_game_store;

-- 1. Security View: v_employee_public_directory
-- Purpose: Hides sensitive salary (hourly_wage) and personal contact info.
CREATE OR REPLACE VIEW v_employee_public_directory AS
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    e.email AS work_email,
    s.store_name,
    s.city AS store_location,
    e.role,
    e.hire_date
FROM Employee e
JOIN Store s ON e.store_id = s.store_id;

-- 2. Reporting View: v_monthly_store_performance
-- Purpose: Aggregates high-level KPIs by Store and Month.
CREATE OR REPLACE VIEW v_monthly_store_performance AS
SELECT 
    s.store_name,
    DATE_FORMAT(p.purchase_date, '%Y-%m') AS sales_month,
    COUNT(DISTINCT p.purchase_id) AS total_transactions,
    SUM(p.total_amount) AS total_revenue,
    SUM(pi.quantity) AS total_items_sold
FROM Store s
JOIN Purchase p ON s.store_id = p.store_id
JOIN PurchaseItem pi ON p.purchase_id = pi.purchase_id
GROUP BY s.store_id, s.store_name, sales_month;

-- 3. Operational View: v_restock_urgency_list
-- Purpose: Pre-filters inventory to show only items needing attention.
CREATE OR REPLACE VIEW v_restock_urgency_list AS
SELECT 
    s.store_name,
    v.name AS vendor_name,
    p.name AS product_name,
    i.quantity_available,
    i.restock_threshold,
    (i.restock_threshold - i.quantity_available) + 10 AS suggested_reorder_amount,
    v.contact_email
FROM Inventory i
JOIN Store s ON i.store_id = s.store_id
JOIN Product p ON i.product_id = p.product_id
JOIN Vendor v ON p.vendor_id = v.vendor_id
WHERE i.quantity_available <= i.restock_threshold;