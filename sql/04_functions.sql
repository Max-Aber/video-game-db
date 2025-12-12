USE video_game_store;

-- 1. Function: get_customer_loyalty_level
-- Purpose: Returns a text label ('Bronze', 'Silver', 'Gold') based on points.
DROP FUNCTION IF EXISTS get_customer_loyalty_level;

CREATE FUNCTION get_customer_loyalty_level(current_points INT) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE level_label VARCHAR(20);

    IF current_points >= 1000 THEN
        SET level_label = 'Gold';
    ELSEIF current_points >= 500 THEN
        SET level_label = 'Silver';
    ELSE
        SET level_label = 'Bronze';
    END IF;

    RETURN level_label;
END;

-- 2. Stored Procedure: sp_process_restock
-- Purpose: Handles inventory updates or inserts new inventory records safely.
DROP PROCEDURE IF EXISTS sp_process_restock;

CREATE PROCEDURE sp_process_restock(
    IN p_store_id INT,
    IN p_product_id INT,
    IN p_quantity_received INT
)
BEGIN
    -- Check if inventory record exists
    IF EXISTS (SELECT 1 FROM Inventory WHERE store_id = p_store_id AND product_id = p_product_id) THEN
        -- Update existing record
        UPDATE Inventory 
        SET quantity_available = quantity_available + p_quantity_received
        WHERE store_id = p_store_id AND product_id = p_product_id;
    ELSE
        -- Insert new record using default pricing logic
        INSERT INTO Inventory (store_id, product_id, purchase_price, current_price, quantity_available, restock_threshold)
        SELECT 
            p_store_id, 
            p_product_id, 
            msrp * 0.60, 
            msrp, 
            p_quantity_received, 
            5 
        FROM Product WHERE product_id = p_product_id;
    END IF;
END;

-- 3. Stored Procedure: sp_apply_category_discount
-- Purpose: Applies a percentage discount to a specific category at a specific store.
DROP PROCEDURE IF EXISTS sp_apply_category_discount;

CREATE PROCEDURE sp_apply_category_discount(
    IN p_store_id INT,
    IN p_category_name VARCHAR(50),
    IN p_discount_percentage DECIMAL(5,2)
)
BEGIN
    UPDATE Inventory i
    JOIN Product p ON i.product_id = p.product_id
    JOIN Category c ON p.category_id = c.category_id
    SET i.current_price = i.current_price * (1 - p_discount_percentage)
    WHERE i.store_id = p_store_id 
    AND c.name = p_category_name;
END;