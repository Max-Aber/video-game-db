DROP DATABASE IF EXISTS video_game_store;
create database video_game_store;
use video_game_store;

-- =====================================================

DROP TABLE IF EXISTS Review;
DROP TABLE IF EXISTS ReturnItem;
DROP TABLE IF EXISTS `Return`;
DROP TABLE IF EXISTS PurchaseItem;
DROP TABLE IF EXISTS Purchase;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Store;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS Vendor;
-- =====================================================

CREATE TABLE Vendor (
    vendor_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    country VARCHAR(50) NOT NULL,
    UNIQUE KEY uk_vendor_name (name)
) ENGINE=InnoDB;


CREATE TABLE Category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    UNIQUE KEY uk_category_name (name)
) ENGINE=InnoDB;


CREATE TABLE Product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category_id INT NOT NULL,
    vendor_id INT NOT NULL,
    msrp DECIMAL(10, 2) NOT NULL,
    esrb_rating ENUM('E', 'E10+', 'T', 'M', 'AO', 'RP') NOT NULL,
    release_date DATE,
    platform VARCHAR(50) NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT fk_product_category 
        FOREIGN KEY (category_id) REFERENCES Category(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_product_vendor 
        FOREIGN KEY (vendor_id) REFERENCES Vendor(vendor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_product_msrp 
        CHECK (msrp >= 0),
    
    -- Indexes for common queries
    INDEX idx_product_category (category_id),
    INDEX idx_product_vendor (vendor_id),
    INDEX idx_product_platform (platform)
) ENGINE=InnoDB;

-- =====================================================
-- 4. EMPLOYEE TABLE (defined before Store due to FK)
-- =====================================================
CREATE TABLE Employee (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    store_id INT,  -- FK added after Store is created
    hire_date DATE NOT NULL,
    role ENUM('CASHIER', 'MANAGER', 'STOCK_CLERK') NOT NULL,
    hourly_wage DECIMAL(6, 2) NOT NULL,
    
    -- Constraints
    UNIQUE KEY uk_employee_email (email),
    
    CONSTRAINT chk_employee_wage 
        CHECK (hourly_wage >= 0)
) ENGINE=InnoDB;

-- =====================================================
-- 5. STORE TABLE
-- =====================================================
CREATE TABLE Store (
    store_id INT AUTO_INCREMENT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    street_address VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state CHAR(2) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    manager_id INT,  -- Can be NULL initially
    
    -- Foreign Key
    CONSTRAINT fk_store_manager 
        FOREIGN KEY (manager_id) REFERENCES Employee(employee_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    -- Indexes
    INDEX idx_store_manager (manager_id),
    INDEX idx_store_location (city, state)
) ENGINE=InnoDB;

-- Add FK from Employee to Store (circular dependency resolution)
ALTER TABLE Employee
    ADD CONSTRAINT fk_employee_store
        FOREIGN KEY (store_id) REFERENCES Store(store_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    ADD INDEX idx_employee_store (store_id);

-- =====================================================
-- 6. INVENTORY TABLE
-- =====================================================
CREATE TABLE Inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    purchase_price DECIMAL(10, 2) NOT NULL,
    current_price DECIMAL(10, 2) NOT NULL,
    quantity_available INT NOT NULL DEFAULT 0,
    restock_threshold INT NOT NULL DEFAULT 5,
    
    -- Foreign Keys
    CONSTRAINT fk_inventory_store 
        FOREIGN KEY (store_id) REFERENCES Store(store_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_inventory_product 
        FOREIGN KEY (product_id) REFERENCES Product(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_inventory_purchase_price 
        CHECK (purchase_price >= 0),
    
    CONSTRAINT chk_inventory_current_price 
        CHECK (current_price >= 0),
    
    CONSTRAINT chk_inventory_quantity 
        CHECK (quantity_available >= 0),
    
    CONSTRAINT chk_inventory_threshold 
        CHECK (restock_threshold >= 0),
    
    -- Unique constraint: one product per store per condition
    UNIQUE KEY uk_inventory_store_product (store_id, product_id),
    
    -- Indexes
    INDEX idx_inventory_store (store_id),
    INDEX idx_inventory_product (product_id),
    INDEX idx_inventory_low_stock (quantity_available)
) ENGINE=InnoDB;

-- =====================================================
-- 7. CUSTOMER TABLE
-- =====================================================
CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    join_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    total_points INT NOT NULL DEFAULT 0,
    
    -- Constraints
    UNIQUE KEY uk_customer_email (email),
    
    CONSTRAINT chk_customer_points 
        CHECK (total_points >= 0),
    
    -- Indexes
    INDEX idx_customer_name (last_name, first_name),
    INDEX idx_customer_points (total_points)
) ENGINE=InnoDB;

-- =====================================================
-- 8. PURCHASE TABLE
-- =====================================================
CREATE TABLE Purchase (
    purchase_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,  -- NULL for walk-in customers
    employee_id INT NOT NULL,
    store_id INT NOT NULL,
    purchase_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('CASH', 'CREDIT', 'DEBIT') NOT NULL,
    points_earned INT NOT NULL DEFAULT 0,
    
    -- Foreign Keys
    CONSTRAINT fk_purchase_customer 
        FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_purchase_employee 
        FOREIGN KEY (employee_id) REFERENCES Employee(employee_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_purchase_store 
        FOREIGN KEY (store_id) REFERENCES Store(store_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_purchase_subtotal 
        CHECK (subtotal >= 0),
    
    CONSTRAINT chk_purchase_tax 
        CHECK (tax_amount >= 0),
    
    CONSTRAINT chk_purchase_total 
        CHECK (total_amount >= 0),
    
    CONSTRAINT chk_purchase_points 
        CHECK (points_earned >= 0),
    
    -- Indexes
    INDEX idx_purchase_customer (customer_id),
    INDEX idx_purchase_employee (employee_id),
    INDEX idx_purchase_store (store_id),
    INDEX idx_purchase_date (purchase_date)
) ENGINE=InnoDB;

-- =====================================================
-- 9. PURCHASEITEM TABLE (Bridge Table)
-- =====================================================
CREATE TABLE PurchaseItem (
    purchase_item_id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id INT NOT NULL,
    inventory_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    line_total DECIMAL(10, 2) NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT fk_purchaseitem_purchase 
        FOREIGN KEY (purchase_id) REFERENCES Purchase(purchase_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_purchaseitem_inventory 
        FOREIGN KEY (inventory_id) REFERENCES Inventory(inventory_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_purchaseitem_quantity 
        CHECK (quantity > 0),
    
    CONSTRAINT chk_purchaseitem_unit_price 
        CHECK (unit_price >= 0),
    
    CONSTRAINT chk_purchaseitem_discount 
        CHECK (discount_amount >= 0),
    
    CONSTRAINT chk_purchaseitem_line_total 
        CHECK (line_total >= 0),
    
    -- Indexes
    INDEX idx_purchaseitem_purchase (purchase_id),
    INDEX idx_purchaseitem_inventory (inventory_id)
) ENGINE=InnoDB;

-- =====================================================
-- 10. RETURN TABLE
-- =====================================================
CREATE TABLE `Return` (
    return_id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id INT NOT NULL,
    return_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason ENUM('DEFECTIVE', 'UNWANTED', 'WRONG_ITEM', 'OTHER') NOT NULL,
    refund_amount DECIMAL(10, 2) NOT NULL,
    restocking_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
    processed_by_employee_id INT NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT fk_return_purchase 
        FOREIGN KEY (purchase_id) REFERENCES Purchase(purchase_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_return_employee 
        FOREIGN KEY (processed_by_employee_id) REFERENCES Employee(employee_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_return_refund 
        CHECK (refund_amount >= 0),
    
    CONSTRAINT chk_return_restocking_fee 
        CHECK (restocking_fee >= 0),
    
    -- Indexes
    INDEX idx_return_purchase (purchase_id),
    INDEX idx_return_employee (processed_by_employee_id),
    INDEX idx_return_date (return_date)
) ENGINE=InnoDB;

-- =====================================================
-- 11. RETURNITEM TABLE (Bridge Table)
-- =====================================================
CREATE TABLE ReturnItem (
    return_item_id INT AUTO_INCREMENT PRIMARY KEY,
    return_id INT NOT NULL,
    purchase_item_id INT NOT NULL,
    quantity_returned INT NOT NULL,
    condition_returned ENUM('NEW', 'USED', 'DAMAGED') NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT fk_returnitem_return 
        FOREIGN KEY (return_id) REFERENCES `Return`(return_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_returnitem_purchaseitem 
        FOREIGN KEY (purchase_item_id) REFERENCES PurchaseItem(purchase_item_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_returnitem_quantity 
        CHECK (quantity_returned > 0),
    
    -- Indexes
    INDEX idx_returnitem_return (return_id),
    INDEX idx_returnitem_purchaseitem (purchase_item_id)
) ENGINE=InnoDB;

-- =====================================================
-- 12. REVIEW TABLE
-- =====================================================
CREATE TABLE Review (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating INT NOT NULL,
    review_text TEXT,
    review_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    CONSTRAINT fk_review_product 
        FOREIGN KEY (product_id) REFERENCES Product(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_review_customer 
        FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT chk_review_rating 
        CHECK (rating >= 1 AND rating <= 5),
    
    -- Unique constraint: one review per customer per product
    UNIQUE KEY uk_review_product_customer (product_id, customer_id),
    
    -- Indexes
    INDEX idx_review_product (product_id),
    INDEX idx_review_customer (customer_id),
    INDEX idx_review_rating (rating)
) ENGINE=InnoDB;

-- =====================================================
-- END OF SCHEMA
-- =====================================================