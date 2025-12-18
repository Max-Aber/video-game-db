USE video_game_store;

-- 0. Trigger: trg_prevent_oversell_purchaseitem
-- Purpose: Prevents overselling by blocking a PurchaseItem insert when
--          available inventory is insufficient for the requested quantity.

DROP TRIGGER IF EXISTS trg_prevent_oversell_purchaseitem;
DELIMITER //
CREATE TRIGGER trg_prevent_oversell_purchaseitem
BEFORE INSERT ON PurchaseItem
FOR EACH ROW
BEGIN
    DECLARE v_available INT;

    SELECT quantity_available
    INTO v_available
    FROM Inventory
    WHERE inventory_id = NEW.inventory_id
    FOR UPDATE;

    IF v_available IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Invalid inventory_id on PurchaseItem.';
    END IF;

    IF v_available < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Oversell blocked. Insufficient inventory.';
    END IF;
END //
DELIMITER ;


-- 1. Trigger: trg_reduce_inventory_after_purchase
-- Purpose: Automatically subtracts sold quantity from inventory.
DROP TRIGGER IF EXISTS trg_reduce_inventory_after_purchase;
DELIMITER //
CREATE TRIGGER trg_reduce_inventory_after_purchase
AFTER INSERT ON PurchaseItem
FOR EACH ROW
BEGIN
    -- Update the inventory using the store_id found via the purchase_id
    UPDATE Inventory
    SET quantity_available = quantity_available - NEW.quantity
    WHERE inventory_id = NEW.inventory_id;
END //
DELIMITER ;

-- 2. Trigger: trg_enforce_return_window
-- Purpose: Rejects returns if the purchase was made more than 90 days ago.
DROP TRIGGER IF EXISTS trg_enforce_return_window;
DELIMITER //
CREATE TRIGGER trg_enforce_return_window
BEFORE INSERT ON `Return`
FOR EACH ROW
BEGIN
    DECLARE v_purchase_date DATETIME;
    
    -- Get the original purchase date
    SELECT purchase_date INTO v_purchase_date
    FROM Purchase
    WHERE purchase_id = NEW.purchase_id;
    
    -- Check if date difference exceeds 90 days
    IF DATEDIFF(NEW.return_date, v_purchase_date) > 90 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Return rejected. Purchase exceeds the 90-day return policy window.';
    END IF;
END //
DELIMITER ;

-- 3. Audit log for Purchase updates
DROP TRIGGER IF EXISTS trg_audit_purchase_update;
DELIMITER //
CREATE TRIGGER trg_audit_purchase_update
AFTER UPDATE ON Purchase
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (
        table_name,
        operation,
        primary_key_value,
        changed_by,
        old_values,
        new_values
    )
    VALUES (
        'Purchase',
        'UPDATE',
        CAST(NEW.purchase_id AS CHAR),
        CURRENT_USER(),
        JSON_OBJECT(
            'customer_id', OLD.customer_id,
            'employee_id', OLD.employee_id,
            'store_id', OLD.store_id,
            'subtotal', OLD.subtotal,
            'tax_amount', OLD.tax_amount,
            'total_amount', OLD.total_amount,
            'payment_method', OLD.payment_method,
            'points_earned', OLD.points_earned
        ),
        JSON_OBJECT(
            'customer_id', NEW.customer_id,
            'employee_id', NEW.employee_id,
            'store_id', NEW.store_id,
            'subtotal', NEW.subtotal,
            'tax_amount', NEW.tax_amount,
            'total_amount', NEW.total_amount,
            'payment_method', NEW.payment_method,
            'points_earned', NEW.points_earned
        )
    );
END //
DELIMITER ;

-- 4. Audit log for Inventory updates
DROP TRIGGER IF EXISTS trg_audit_inventory_update;
DELIMITER //
CREATE TRIGGER trg_audit_inventory_update
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (
        table_name,
        operation,
        primary_key_value,
        changed_by,
        old_values,
        new_values
    )
    VALUES (
        'Inventory',
        'UPDATE',
        CAST(NEW.inventory_id AS CHAR),
        CURRENT_USER(),
        JSON_OBJECT(
            'store_id', OLD.store_id,
            'product_id', OLD.product_id,
            'purchase_price', OLD.purchase_price,
            'current_price', OLD.current_price,
            'quantity_available', OLD.quantity_available,
            'restock_threshold', OLD.restock_threshold
        ),
        JSON_OBJECT(
            'store_id', NEW.store_id,
            'product_id', NEW.product_id,
            'purchase_price', NEW.purchase_price,
            'current_price', NEW.current_price,
            'quantity_available', NEW.quantity_available,
            'restock_threshold', NEW.restock_threshold
        )
    );
END //
DELIMITER ;


-- =====================================================
-- Loyalty Points Accumulation
-- =====================================================
-- Adds points from a purchase into the customer's total_points.
-- This ensures loyalty data cannot drift from purchase history.

DROP TRIGGER IF EXISTS trg_add_points_after_purchase;
DELIMITER //

CREATE TRIGGER trg_add_points_after_purchase
AFTER INSERT ON Purchase
FOR EACH ROW
BEGIN
    IF NEW.customer_id IS NOT NULL THEN
        UPDATE Customer
        SET total_points = total_points + IFNULL(NEW.points_earned, 0)
        WHERE customer_id = NEW.customer_id;
    END IF;
END//

DELIMITER ;


-- =====================================================
-- Automatic Loyalty Tier Updates
-- =====================================================
-- Keeps loyalty_tier consistent with total_points.
-- Bronze  < 500
-- Silver ≥ 500
-- Gold   ≥ 1000

DROP TRIGGER IF EXISTS trg_auto_loyalty_tier_update;
DELIMITER //

CREATE TRIGGER trg_auto_loyalty_tier_update
BEFORE UPDATE ON Customer
FOR EACH ROW
BEGIN
    IF NEW.total_points <> OLD.total_points THEN
        SET NEW.loyalty_tier =
            CASE
                WHEN NEW.total_points >= 1000 THEN 'Gold'
                WHEN NEW.total_points >= 500 THEN 'Silver'
                ELSE 'Bronze'
            END;
    END IF;
END//

DELIMITER ;
