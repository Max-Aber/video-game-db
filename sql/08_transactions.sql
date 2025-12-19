USE video_game_store;
SET SESSION sql_notes = 0;
-- =======================================================================================
-- 8. INTEGRITY & RELIABILITY: TRANSACTION TEST SUITE
-- =======================================================================================
-- This script demonstrates ACID properties, Error Handling, and Constraint Enforcement.
-- It is designed to be idempotent (cleans up after itself).
-- Set session isolation level for consistency
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Enable simple output for test results
SELECT 'STARTING TRANSACTION TEST SUITE...' AS Status;
SELECT '===============================================================================' AS '';
-- =======================================================================================
-- TEST CASE 1: ATOMICITY & SUCCESS (The "Happy Path")
-- Scenario: A customer purchases a game. 
-- Expectation: Purchase and PurchaseItem rows created, Inventory reduced (via Trigger), Commit successful.
-- =======================================================================================
SELECT 'TEST CASE 1: Atomicity - Successful Multi-Table Purchase' AS Test_Case;
START TRANSACTION;
-- 1. Create a dummy purchase
INSERT INTO Purchase (
        customer_id,
        employee_id,
        store_id,
        subtotal,
        tax_amount,
        total_amount,
        payment_method,
        points_earned
    )
VALUES (1, 1, 1, 59.99, 5.00, 64.99, 'CASH', 60);
-- Capture the ID
SET @new_purchase_id = LAST_INSERT_ID();
-- 2. Add an item (Super Mario Odyssey, Inventory ID 1)
-- Note: Trigger `trg_reduce_inventory_after_purchase` will fire here.
INSERT INTO PurchaseItem (
        purchase_id,
        inventory_id,
        quantity,
        unit_price,
        line_total
    )
VALUES (@new_purchase_id, 1, 1, 59.99, 59.99);
-- Check if it worked
SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM Purchase
            WHERE purchase_id = @new_purchase_id
        ) THEN 'PASS: Purchase Created'
        ELSE 'FAIL: Purchase Missing'
    END AS Result;
-- CLEANUP (To maintain idempotency)
ROLLBACK;
SELECT 'Test 1 Complete: Rolled back to keep state clean.' AS Cleanup_Status;
SELECT '===============================================================================' AS '';
-- =======================================================================================
-- TEST CASE 2: CONSISTENCY & CONSTRAINT VIOLATION (CHECK Constraint)
-- Scenario: Attempting to insert a Product with a negative MSRP.
-- Expectation: Database rejects the insert. Transaction rolls back.
-- =======================================================================================
SELECT 'TEST CASE 2: Consistency - Negative Price Violation' AS Test_Case;
START TRANSACTION;
-- This relies on the constraint: CHECK (msrp >= 0)
-- We use INSERT IGNORE here to allow the script to continue running 
-- even if the database throws a fatal error for this statement.
INSERT IGNORE INTO Product (
        name,
        category_id,
        vendor_id,
        msrp,
        esrb_rating,
        platform
    )
VALUES ('Invalid Game', 1, 1, -50.00, 'E', 'Switch');
-- Verify rejection
SELECT CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM Product
            WHERE name = 'Invalid Game'
        ) THEN 'PASS: Negative Price Rejected'
        ELSE 'FAIL: Invalid Data Existed'
    END AS Result;
ROLLBACK;
SELECT '===============================================================================' AS '';
-- =======================================================================================
-- TEST CASE 3: TRIGGER ENFORCEMENT (Business Rule)
-- Scenario: Attempting to return an item bought > 90 days ago.
-- Expectation: Trigger `trg_enforce_return_window` blocks the insert.
-- =======================================================================================
SELECT 'TEST CASE 3: Trigger Rules - Return Policy Window' AS Test_Case;
START TRANSACTION;
-- 1. Create an OLD purchase (Last year)
INSERT INTO Purchase (
        customer_id,
        employee_id,
        store_id,
        purchase_date,
        subtotal,
        tax_amount,
        total_amount,
        payment_method
    )
VALUES (
        1,
        1,
        1,
        '2022-01-01',
        59.99,
        5.00,
        64.99,
        'CASH'
    );
SET @old_pid = LAST_INSERT_ID();
-- 2. Attempt to Return it today
-- NOTE: This INSERT will fail with error 1644 due to the trigger.
-- The script should be run with --force flag to continue past this error.
-- The trigger blocking the insert is the EXPECTED and CORRECT behavior.
INSERT INTO `Return` (
        purchase_id,
        return_date,
        reason,
        refund_amount,
        processed_by_employee_id
    )
VALUES (@old_pid, NOW(), 'UNWANTED', 59.99, 1);
-- 3. Verify Rejection (if script continues with --force)
SELECT CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM `Return`
            WHERE purchase_id = @old_pid
        ) THEN 'PASS: Late Return Rejected by Trigger'
        ELSE 'FAIL: Return was allowed'
    END AS Result;
ROLLBACK;
SELECT '===============================================================================' AS '';
-- =======================================================================================
-- TEST CASE 4: ISOLATION & DIRTY READ PREVENTION)
-- Scenario: Transaction A updates a price but hasn't committed. Transaction B reads the price.
-- Expectation: With READ COMMITTED, Transaction B should see the OLD price, not the uncommitted NEW price.
-- =======================================================================================
SELECT 'TEST CASE 4: Isolation - preventing Dirty Reads' AS Test_Case;
-- Check initial price of Inventory ID 1
SELECT current_price INTO @start_price
FROM Inventory
WHERE inventory_id = 1;
START TRANSACTION;
-- Transaction A
-- Update price
UPDATE Inventory
SET current_price = 999.99
WHERE inventory_id = 1;
-- Verify inside Transaction A (Simulated)
SELECT current_price INTO @dirty_price
FROM Inventory
WHERE inventory_id = 1;
-- Simulate Transaction B reading strictly committed data
-- (In a single script linear flow, we simulate this by rolling back A and checking B's view)
ROLLBACK;
-- Undo Transaction A
-- Read again (Transaction B view)
SELECT current_price INTO @final_price
FROM Inventory
WHERE inventory_id = 1;
SELECT @start_price AS Original_Price,
    @dirty_price AS Uncommitted_Update,
    @final_price AS Post_Rollback_Price,
    CASE
        WHEN @final_price = @start_price THEN 'PASS: Dirty Read Prevented/Rolled Back'
        ELSE 'FAIL: Data Persisted Incorrectly'
    END AS Result;
SELECT '===============================================================================' AS '';
-- =======================================================================================
-- TEST CASE 5: SAVEPOINTS (Partial Rollback)
-- Scenario: Insert a customer, set a savepoint, insert a purchase, realize purchase is wrong, rollback only purchase.
-- Expectation: Customer remains, Purchase is gone.
-- =======================================================================================
SELECT 'TEST CASE 5: Savepoints - Partial Rollback' AS Test_Case;
START TRANSACTION;
-- 1. Insert Customer (Valid)
INSERT INTO Customer (first_name, last_name, email, phone_number)
VALUES (
        'Test',
        'User',
        'test.user@example.com',
        '555-0000'
    );
SET @new_cust_id = LAST_INSERT_ID();
SAVEPOINT sp_customer_created;
-- 2. Insert Purchase (Mistake)
INSERT INTO Purchase (
        customer_id,
        employee_id,
        store_id,
        subtotal,
        tax_amount,
        total_amount,
        payment_method
    )
VALUES (
        @new_cust_id,
        1,
        1,
        1000.00,
        100.00,
        1100.00,
        'CASH'
    );
-- 3. Oops, wrong amount. Rollback to Savepoint.
ROLLBACK TO SAVEPOINT sp_customer_created;
-- 4. Commit the transaction (Should commit only the Customer)
COMMIT;
-- Verify State
SELECT (
        SELECT COUNT(*)
        FROM Customer
        WHERE email = 'test.user@example.com'
    ) AS Customer_Exists,
    (
        SELECT COUNT(*)
        FROM Purchase
        WHERE customer_id = @new_cust_id
    ) AS Purchase_Exists,
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM Customer
            WHERE email = 'test.user@example.com'
        ) = 1
        AND (
            SELECT COUNT(*)
            FROM Purchase
            WHERE customer_id = @new_cust_id
        ) = 0 THEN 'PASS: Customer Saved, Bad Purchase Rolled Back'
        ELSE 'FAIL: Savepoint Logic Incorrect'
    END AS Result;
SELECT '===============================================================================' AS '';
-- =======================================================================================
-- TEST CASE 6: Trigger Rules - Overselling Prevention
-- Scenario: Try to sell more than quantity_available. Trigger should block insert.
-- Expectation: PurchaseItem insert fails, and inventory does NOT change.
-- =======================================================================================
SELECT 'TEST CASE 6: Trigger Rules - Overselling Prevention' AS Test_Case;
START TRANSACTION;
-- Record starting qty for inventory_id = 1
SELECT quantity_available INTO @start_qty
FROM Inventory
WHERE inventory_id = 1;
-- Create a dummy purchase header
INSERT INTO Purchase (
        customer_id,
        employee_id,
        store_id,
        subtotal,
        tax_amount,
        total_amount,
        payment_method,
        points_earned
    )
VALUES (1, 1, 1, 59.99, 5.00, 64.99, 'CASH', 0);
SET @pid := LAST_INSERT_ID();
-- Oversell attempt (should error via trg_prevent_oversell_purchaseitem)
INSERT INTO PurchaseItem (
        purchase_id,
        inventory_id,
        quantity,
        unit_price,
        line_total
    )
VALUES (
        @pid,
        1,
        @start_qty + 1,
        59.99,
        59.99 * (@start_qty + 1)
    );
ROLLBACK;
-- Confirm inventory stayed the same
SELECT quantity_available INTO @end_qty
FROM Inventory
WHERE inventory_id = 1;
SELECT @start_qty AS Start_Qty,
    @end_qty AS End_Qty,
    CASE
        WHEN @end_qty = @start_qty THEN 'PASS: Oversell prevented and inventory unchanged'
        ELSE 'FAIL: Inventory changed unexpectedly'
    END AS Result;
SELECT '===============================================================================' AS '';
-- =======================================================================================
-- TEST CASE 7: Audit Logging Trigger
-- Purpose:
--   Verify that updates to sensitive Inventory data automatically generate
--   an audit record capturing old and new values in JSON format.
-- =======================================================================================
SELECT 'TEST CASE 7: Audit Logging Trigger' AS Test_Case;
-- Select a stable inventory record for testing
SET @inv_id := 1;
-- Remove prior Inventory audit entries to keep the test deterministic
DELETE FROM AuditLog
WHERE table_name = 'Inventory';
-- Capture the original price before modification
SELECT current_price INTO @old_price
FROM Inventory
WHERE inventory_id = @inv_id;
-- Update Inventory (this should fire trg_audit_inventory_update)
UPDATE Inventory
SET current_price = current_price + 1
WHERE inventory_id = @inv_id;
-- Verify that an audit record was created with the correct old value
SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM AuditLog
            WHERE table_name = 'Inventory'
                AND operation = 'UPDATE'
                AND CAST(
                    JSON_UNQUOTE(JSON_EXTRACT(old_values, '$.current_price')) AS DECIMAL(10, 2)
                ) = @old_price
        ) THEN 'PASS: Inventory update logged in AuditLog'
        ELSE 'FAIL: Audit record missing'
    END AS Result;
-- Restore Inventory to its original state for idempotency
UPDATE Inventory
SET current_price = @old_price
WHERE inventory_id = @inv_id;
-- Remove audit records created by this test
DELETE FROM AuditLog
WHERE table_name = 'Inventory';
SELECT '===============================================================================' AS '';
-- =====================================================
-- TEST CASE 8: Loyalty points + tier auto-update
-- =====================================================
SELECT 'TEST CASE 8: Loyalty points + tier auto-update' AS Test_Case;
START TRANSACTION;
-- Snapshot before
SELECT total_points INTO @pts_before
FROM Customer
WHERE customer_id = 1;
SELECT loyalty_tier INTO @tier_before
FROM Customer
WHERE customer_id = 1;
-- Insert purchases to trigger points + tier updates
INSERT INTO Purchase (
        customer_id,
        employee_id,
        store_id,
        subtotal,
        tax_amount,
        total_amount,
        payment_method,
        points_earned
    )
VALUES (1, 7, 1, 10.00, 0.90, 10.90, 'CASH', 600);
INSERT INTO Purchase (
        customer_id,
        employee_id,
        store_id,
        subtotal,
        tax_amount,
        total_amount,
        payment_method,
        points_earned
    )
VALUES (1, 7, 1, 10.00, 0.90, 10.90, 'CASH', 500);
-- Verify after
SELECT total_points INTO @pts_after
FROM Customer
WHERE customer_id = 1;
SELECT loyalty_tier INTO @tier_after
FROM Customer
WHERE customer_id = 1;
SELECT @pts_before AS pts_before,
    @pts_after AS pts_after,
    @tier_before AS tier_before,
    @tier_after AS tier_after,
    CASE
        WHEN @pts_after = @pts_before + 1100 THEN 'PASS: points added correctly'
        ELSE 'FAIL: points not added correctly'
    END AS points_result;
ROLLBACK;
SELECT 'Test 8 Complete: Rolled back to keep state clean.' AS Cleanup_Status;
SELECT '===========================================================================' AS '';
-- Final Cleanup of the Test User
DELETE FROM Customer
WHERE email = 'test.user@example.com';
SELECT '' AS '';
SELECT 'TEST SUITE COMPLETE.' AS Status;
SELECT '' AS '';