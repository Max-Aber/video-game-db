USE video_game_store;

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