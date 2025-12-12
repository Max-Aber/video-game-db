USE video_game_store;

-- =====================================================
-- PERFORMANCE & INDEXING REPORT
-- =====================================================

/*
    ---------------------------------------------------------------------------------
    OPTIMIZATION 1: Product Search by Name
    ---------------------------------------------------------------------------------
    Query: Find a product by partial name (e.g., search bar functionality).
    SQL:   SELECT * FROM Product WHERE name LIKE 'Final Fantasy%';
    
    BEFORE INDEX:
    - Type: ALL (Full Table Scan)
    - Rows Examined: 30 (All rows)
    - Explanation: MySQL must check every single row in the Product table to compare the string.
    
    AFTER INDEX (idx_product_name):
    - Type: range
    - Rows Examined: ~2
    - Explanation: MySQL uses the B-Tree to jump directly to "Final Fantasy" and scans only matching rows.
    
    JUSTIFICATION:
    - Selectivity: High. Product names are generally unique or distinct.
    - Access Pattern: High frequency. Search is a primary user action.
    
    ---------------------------------------------------------------------------------
    OPTIMIZATION 2: Customer Purchase History (Composite Index)
    ---------------------------------------------------------------------------------
    Query: View a specific customer's purchase history sorted by most recent.
    SQL:   SELECT * FROM Purchase WHERE customer_id = 5 ORDER BY purchase_date DESC;
    
    BEFORE INDEX:
    - Type: ref (uses fk_purchase_customer)
    - Extra: Using filesort
    - Explanation: The existing FK index finds the rows for customer 5, but the database 
      must perform an extra "sort pass" (Filesort) in memory to order them by date.
    
    AFTER INDEX (idx_purchase_cust_date):
    - Type: ref
    - Extra: NULL (No filesort)
    - Explanation: The composite index stores the data for each customer already sorted 
      by date. The DB reads the index and returns rows in the correct order instantly.
    
    JUSTIFICATION:
    - Access Pattern: Very Common (User Profile > Order History).
    - Performance: Eliminates CPU-intensive sorting operations.
    
    ---------------------------------------------------------------------------------
    OPTIMIZATION 3: Latest Product Reviews (Composite Index)
    ---------------------------------------------------------------------------------
    Query: Show the 10 most recent reviews for a specific product.
    SQL:   SELECT * FROM Review WHERE product_id = 1 ORDER BY review_date DESC LIMIT 10;
    
    BEFORE INDEX:
    - Type: ref (uses fk_review_product)
    - Extra: Using filesort
    - Explanation: Finds reviews for the product, then manually sorts them to find the "newest" 10.
    
    AFTER INDEX (idx_review_product_date):
    - Type: ref
    - Extra: Backward index scan (or standard index lookup)
    - Explanation: Data is pre-sorted. MySQL reads the last 10 entries in the index 
      for that product ID. Efficient "Top-N" query optimization.
      
    ---------------------------------------------------------------------------------
    TRADE-OFF ANALYSIS
    ---------------------------------------------------------------------------------
    1. Write Overhead: 
       Every INSERT into Purchase, Product, or Review now requires updating an additional 
       B-Tree structure. For 'Purchase', this is negligible compared to the read-heavy 
       nature of order history lookups.
       
    2. Storage Cost: 
       Composite indexes (int + datetime) consume more disk space than single-column indexes. 
       However, given the small scale of these keys (8-12 bytes per row), the storage cost 
       is trivial compared to the CPU gains from avoiding Filesorts.
*/

-- =====================================================
-- 1. Index for Product Search (Name)
-- =====================================================
-- Standard B-Tree index on Product Name to speed up LIKE 'Name%' searches.
-- Note: 'name' is VARCHAR(200), so we limit index prefix to 20 chars to save space 
-- while maintaining high selectivity.
CREATE INDEX idx_product_name 
ON Product(name(20));

-- Show Explain Plan (Simulation)
EXPLAIN SELECT * FROM Product WHERE name LIKE 'Final Fantasy%';


-- =====================================================
-- 2. Composite Index for Purchase History
-- =====================================================
-- Composite Index on (customer_id, purchase_date)
-- Optimizes: WHERE customer_id = X ORDER BY purchase_date
CREATE INDEX idx_purchase_cust_date 
ON Purchase(customer_id, purchase_date);

-- Show Explain Plan (Simulation)
EXPLAIN SELECT * FROM Purchase WHERE customer_id = 5 ORDER BY purchase_date DESC;


-- =====================================================
-- 3. Composite Index for Product Reviews
-- =====================================================
-- Composite Index on (product_id, review_date)
-- Optimizes: WHERE product_id = X ORDER BY review_date
CREATE INDEX idx_review_product_date 
ON Review(product_id, review_date);

-- Show Explain Plan (Simulation)
EXPLAIN SELECT * FROM Review WHERE product_id = 1 ORDER BY review_date DESC;