USE video_game_store;

-- Disable FK checks to handle circular dependency (Store <-> Employee)
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- 1. VENDORS (10 Rows)
-- =====================================================
INSERT INTO Vendor (name, contact_email, contact_phone, country) VALUES
('Nintendo', 'partners@nintendo.com', '1-800-255-3700', 'Japan'),
('Sony Interactive', 'support@playstation.com', '1-800-345-7669', 'Japan'),
('Microsoft Xbox', 'bizdev@microsoft.com', '1-800-469-9269', 'USA'),
('Electronic Arts', 'vendor@ea.com', '650-628-1500', 'USA'),
('Ubisoft', 'sales@ubisoft.com', '415-547-4000', 'France'),
('Activision Blizzard', 'retail@activision.com', '310-255-2000', 'USA'),
('Capcom', 'dist@capcom.com', '650-350-6500', 'Japan'),
('Square Enix', 'na.sales@square-enix.com', '310-846-0400', 'Japan'),
('Sega', 'sales@sega.com', '800-872-7342', 'Japan'),
('Bethesda Softworks', 'info@bethesda.net', '301-926-8300', 'USA');

-- =====================================================
-- 2. CATEGORIES (6 Rows)
-- =====================================================
INSERT INTO Category (name) VALUES
('Action-Adventure'),
('Role-Playing (RPG)'),
('Sports'),
('Shooter'),
('Strategy'),
('Family/Platformer');

-- =====================================================
-- 3. PRODUCTS (30 Rows)
-- =====================================================
INSERT INTO Product (name, category_id, vendor_id, msrp, esrb_rating, release_date, platform) VALUES
-- Nintendo (Vendor 1)
('Super Mario Odyssey', 6, 1, 59.99, 'E10+', '2017-10-27', 'Switch'),
('The Legend of Zelda: Breath of the Wild', 1, 1, 59.99, 'E10+', '2017-03-03', 'Switch'),
('Mario Kart 8 Deluxe', 6, 1, 59.99, 'E', '2017-04-28', 'Switch'),
('Splatoon 3', 4, 1, 59.99, 'E10+', '2022-09-09', 'Switch'),
-- Sony (Vendor 2)
('God of War Ragnarok', 1, 2, 69.99, 'M', '2022-11-09', 'PS5'),
('Spider-Man 2', 1, 2, 69.99, 'T', '2023-10-20', 'PS5'),
('Gran Turismo 7', 3, 2, 69.99, 'E', '2022-03-04', 'PS5'),
('Horizon Forbidden West', 1, 2, 59.99, 'T', '2022-02-18', 'PS4'),
-- Microsoft (Vendor 3)
('Halo Infinite', 4, 3, 59.99, 'T', '2021-12-08', 'Xbox Series X'),
('Forza Horizon 5', 3, 3, 59.99, 'E', '2021-11-09', 'Xbox Series X'),
('Starfield', 2, 3, 69.99, 'M', '2023-09-06', 'Xbox Series X'),
-- EA (Vendor 4)
('EA Sports FC 24', 3, 4, 69.99, 'E', '2023-09-29', 'PS5'),
('Madden NFL 24', 3, 4, 69.99, 'E', '2023-08-18', 'Xbox Series X'),
('Star Wars Jedi: Survivor', 1, 4, 69.99, 'T', '2023-04-28', 'PS5'),
-- Ubisoft (Vendor 5)
('Assassin\'s Creed Mirage', 1, 5, 49.99, 'M', '2023-10-05', 'PS5'),
('Far Cry 6', 4, 5, 39.99, 'M', '2021-10-07', 'Xbox Series X'),
('Just Dance 2024', 6, 5, 29.99, 'E', '2023-10-24', 'Switch'),
-- Activision (Vendor 6)
('Call of Duty: Modern Warfare III', 4, 6, 69.99, 'M', '2023-11-10', 'PS5'),
('Diablo IV', 2, 6, 69.99, 'M', '2023-06-05', 'PC'),
('Overwatch 2 Coins', 4, 6, 19.99, 'T', '2022-10-04', 'Digital'),
-- Capcom (Vendor 7)
('Resident Evil 4 Remake', 1, 7, 59.99, 'M', '2023-03-24', 'PS5'),
('Street Fighter 6', 1, 7, 59.99, 'T', '2023-06-02', 'PS5'),
-- Square Enix (Vendor 8)
('Final Fantasy XVI', 2, 8, 69.99, 'M', '2023-06-22', 'PS5'),
('Final Fantasy VII Rebirth', 2, 8, 69.99, 'T', '2024-02-29', 'PS5'),
('Kingdom Hearts III', 2, 8, 29.99, 'E10+', '2019-01-25', 'PS4'),
-- Sega (Vendor 9)
('Sonic Superstars', 6, 9, 59.99, 'E', '2023-10-17', 'Switch'),
('Like a Dragon: Infinite Wealth', 2, 9, 69.99, 'M', '2024-01-26', 'PS5'),
('Persona 5 Royal', 2, 9, 59.99, 'M', '2022-10-21', 'Switch'),
-- Bethesda (Vendor 10)
('Doom Eternal', 4, 10, 39.99, 'M', '2020-03-20', 'Xbox One'),
('Skyrim Anniversary Edition', 2, 10, 49.99, 'M', '2021-11-11', 'PS5');

-- =====================================================
-- 4. STORES (6 Rows)
-- Note: manager_id references Employees we create next.
-- =====================================================
INSERT INTO Store (store_name, street_address, city, state, zip_code, phone_number, manager_id) VALUES
('GameStop New York', '123 Broadway', 'New York', 'NY', '10001', '212-555-0101', 1),
('GameStop LA', '456 Sunset Blvd', 'Los Angeles', 'CA', '90028', '323-555-0102', 2),
('GameStop Chicago', '789 Michigan Ave', 'Chicago', 'IL', '60611', '312-555-0103', 3),
('GameStop Houston', '101 Main St', 'Houston', 'TX', '77002', '713-555-0104', 4),
('GameStop Phoenix', '202 Camelback Rd', 'Phoenix', 'AZ', '85016', '602-555-0105', 5),
('GameStop Philly', '303 Market St', 'Philadelphia', 'PA', '19106', '215-555-0106', 6);

-- =====================================================
-- 5. EMPLOYEES (20 Rows)
-- Note: store_id references the Stores created above.
-- =====================================================
INSERT INTO Employee (first_name, last_name, email, phone_number, store_id, hire_date, role, hourly_wage) VALUES
-- Managers (IDs 1-6)
('Sarah', 'Connor', 's.connor@gamestore.com', '212-555-1111', 1, '2019-05-01', 'MANAGER', 28.50),
('John', 'Wick', 'j.wick@gamestore.com', '323-555-2222', 2, '2020-03-15', 'MANAGER', 29.00),
('Ellen', 'Ripley', 'e.ripley@gamestore.com', '312-555-3333', 3, '2018-11-20', 'MANAGER', 27.75),
('Tony', 'Stark', 't.stark@gamestore.com', '713-555-4444', 4, '2021-01-10', 'MANAGER', 30.00),
('Bruce', 'Wayne', 'b.wayne@gamestore.com', '602-555-5555', 5, '2019-08-30', 'MANAGER', 28.00),
('Peter', 'Parker', 'p.parker@gamestore.com', '215-555-6666', 6, '2022-06-01', 'MANAGER', 26.50),
-- Cashiers & Stock Clerks (IDs 7-20)
('Clark', 'Kent', 'c.kent@gamestore.com', '212-555-1001', 1, '2023-01-15', 'CASHIER', 16.00),
('Diana', 'Prince', 'd.prince@gamestore.com', '212-555-1002', 1, '2023-02-20', 'STOCK_CLERK', 15.50),
('Barry', 'Allen', 'b.allen@gamestore.com', '323-555-2001', 2, '2023-03-10', 'CASHIER', 16.50),
('Hal', 'Jordan', 'h.jordan@gamestore.com', '323-555-2002', 2, '2023-04-05', 'STOCK_CLERK', 16.00),
('Arthur', 'Curry', 'a.curry@gamestore.com', '312-555-3001', 3, '2023-05-12', 'CASHIER', 15.75),
('Victor', 'Stone', 'v.stone@gamestore.com', '312-555-3002', 3, '2023-06-18', 'STOCK_CLERK', 15.25),
('Natasha', 'Romanoff', 'n.romanoff@gamestore.com', '713-555-4001', 4, '2023-07-22', 'CASHIER', 16.00),
('Steve', 'Rogers', 's.rogers@gamestore.com', '713-555-4002', 4, '2023-08-01', 'STOCK_CLERK', 15.50),
('Thor', 'Odinson', 't.odinson@gamestore.com', '602-555-5001', 5, '2023-09-09', 'CASHIER', 16.25),
('Bruce', 'Banner', 'b.banner@gamestore.com', '602-555-5002', 5, '2023-10-15', 'STOCK_CLERK', 15.75),
('Wanda', 'Maximoff', 'w.maximoff@gamestore.com', '215-555-6001', 6, '2023-11-20', 'CASHIER', 16.00),
('Vision', 'Android', 'v.android@gamestore.com', '215-555-6002', 6, '2023-12-05', 'STOCK_CLERK', 15.50),
('Logan', 'Howlett', 'l.howlett@gamestore.com', '212-555-1003', 1, '2024-01-02', 'CASHIER', 15.00),
('Jean', 'Grey', 'j.grey@gamestore.com', '323-555-2003', 2, '2024-01-10', 'CASHIER', 15.00);

-- =====================================================
-- 6. INVENTORY (100 Rows)
-- Distributing products across stores. 
-- Approx 16-17 products per store to reach 100 total rows.
-- =====================================================
INSERT INTO Inventory (store_id, product_id, purchase_price, current_price, quantity_available, restock_threshold) VALUES
-- Store 1 (NY)
(1, 1, 40.00, 59.99, 12, 5), (1, 2, 40.00, 59.99, 8, 5), (1, 5, 45.00, 69.99, 20, 5), (1, 6, 45.00, 69.99, 15, 5),
(1, 9, 40.00, 59.99, 5, 3), (1, 12, 45.00, 69.99, 30, 10), (1, 15, 30.00, 49.99, 4, 2), (1, 18, 45.00, 69.99, 10, 5),
(1, 20, 40.00, 59.99, 7, 3), (1, 22, 45.00, 69.99, 6, 2), (1, 25, 40.00, 59.99, 9, 4), (1, 28, 25.00, 39.99, 3, 2),
(1, 29, 30.00, 49.99, 8, 3), (1, 3, 40.00, 59.99, 11, 4), (1, 4, 40.00, 59.99, 6, 3), (1, 7, 45.00, 69.99, 5, 2),
-- Store 2 (LA)
(2, 1, 40.00, 59.99, 15, 5), (2, 2, 40.00, 59.99, 10, 5), (2, 5, 45.00, 69.99, 25, 8), (2, 6, 45.00, 69.99, 18, 6),
(2, 10, 40.00, 59.99, 8, 4), (2, 13, 45.00, 69.99, 12, 4), (2, 16, 25.00, 39.99, 5, 3), (2, 19, 15.00, 19.99, 50, 10),
(2, 21, 40.00, 59.99, 9, 3), (2, 23, 45.00, 69.99, 7, 2), (2, 26, 45.00, 69.99, 11, 4), (2, 27, 40.00, 59.99, 6, 2),
(2, 30, 30.00, 49.99, 4, 2), (2, 12, 45.00, 69.99, 22, 5), (2, 14, 45.00, 69.99, 8, 3), (2, 8, 40.00, 59.99, 3, 2),
-- Store 3 (Chicago)
(3, 1, 40.00, 59.99, 10, 5), (3, 3, 40.00, 59.99, 14, 5), (3, 5, 45.00, 69.99, 18, 5), (3, 7, 45.00, 69.99, 5, 2),
(3, 9, 40.00, 59.99, 7, 3), (3, 11, 45.00, 69.99, 9, 4), (3, 15, 30.00, 49.99, 6, 3), (3, 17, 20.00, 29.99, 8, 4),
(3, 20, 40.00, 59.99, 12, 5), (3, 22, 45.00, 69.99, 4, 2), (3, 24, 20.00, 29.99, 5, 2), (3, 25, 40.00, 59.99, 10, 4),
(3, 28, 25.00, 39.99, 2, 2), (3, 29, 30.00, 49.99, 5, 2), (3, 12, 45.00, 69.99, 15, 5), (3, 6, 45.00, 69.99, 12, 4),
-- Store 4 (Houston)
(4, 2, 40.00, 59.99, 12, 5), (4, 4, 40.00, 59.99, 9, 4), (4, 6, 45.00, 69.99, 20, 6), (4, 8, 40.00, 59.99, 6, 3),
(4, 10, 40.00, 59.99, 11, 4), (4, 12, 45.00, 69.99, 25, 8), (4, 14, 45.00, 69.99, 7, 3), (4, 16, 25.00, 39.99, 4, 2),
(4, 18, 45.00, 69.99, 8, 3), (4, 21, 40.00, 59.99, 10, 4), (4, 23, 45.00, 69.99, 5, 2), (4, 26, 45.00, 69.99, 14, 5),
(4, 27, 40.00, 59.99, 8, 3), (4, 30, 30.00, 49.99, 3, 2), (4, 1, 40.00, 59.99, 10, 4), (4, 5, 45.00, 69.99, 15, 5),
(4, 13, 45.00, 69.99, 6, 2),
-- Store 5 (Phoenix)
(5, 1, 40.00, 59.99, 8, 4), (5, 3, 40.00, 59.99, 10, 4), (5, 5, 45.00, 69.99, 12, 4), (5, 7, 45.00, 69.99, 4, 2),
(5, 9, 40.00, 59.99, 6, 3), (5, 11, 45.00, 69.99, 8, 3), (5, 13, 45.00, 69.99, 5, 2), (5, 15, 30.00, 49.99, 7, 3),
(5, 17, 20.00, 29.99, 5, 2), (5, 19, 15.00, 19.99, 20, 5), (5, 22, 45.00, 69.99, 3, 2), (5, 24, 20.00, 29.99, 4, 2),
(5, 25, 40.00, 59.99, 9, 3), (5, 28, 25.00, 39.99, 2, 1), (5, 29, 30.00, 49.99, 6, 2), (5, 12, 45.00, 69.99, 18, 5),
(5, 20, 40.00, 59.99, 7, 3),
-- Store 6 (Philly)
(6, 2, 40.00, 59.99, 15, 5), (6, 4, 40.00, 59.99, 8, 4), (6, 6, 45.00, 69.99, 16, 5), (6, 8, 40.00, 59.99, 5, 2),
(6, 10, 40.00, 59.99, 10, 4), (6, 12, 45.00, 69.99, 20, 6), (6, 14, 45.00, 69.99, 6, 3), (6, 16, 25.00, 39.99, 3, 2),
(6, 18, 45.00, 69.99, 9, 3), (6, 21, 40.00, 59.99, 8, 3), (6, 23, 45.00, 69.99, 4, 2), (6, 26, 45.00, 69.99, 12, 4),
(6, 27, 40.00, 59.99, 7, 3), (6, 30, 30.00, 49.99, 5, 2), (6, 1, 40.00, 59.99, 11, 4), (6, 5, 45.00, 69.99, 14, 5),
(6, 9, 40.00, 59.99, 4, 2), (6, 29, 30.00, 49.99, 3, 1);

-- =====================================================
-- 7. CUSTOMERS (40 Rows)
-- =====================================================
INSERT INTO Customer (first_name, last_name, email, phone_number, join_date, total_points) VALUES
('James', 'Smith', 'j.smith@email.com', '555-0101', '2023-01-10', 150),
('Maria', 'Garcia', 'm.garcia@email.com', '555-0102', '2023-01-15', 300),
('Robert', 'Johnson', 'r.johnson@email.com', '555-0103', '2023-02-01', 50),
('Lisa', 'Davis', 'l.davis@email.com', '555-0104', '2023-02-20', 450),
('Michael', 'Wilson', 'm.wilson@email.com', '555-0105', '2023-03-05', 100),
('Jennifer', 'Brown', 'j.brown@email.com', '555-0106', '2023-03-22', 200),
('William', 'Jones', 'w.jones@email.com', '555-0107', '2023-04-10', 0),
('Patricia', 'Miller', 'p.miller@email.com', '555-0108', '2023-04-25', 550),
('David', 'Moore', 'd.moore@email.com', '555-0109', '2023-05-01', 120),
('Linda', 'Taylor', 'l.taylor@email.com', '555-0110', '2023-05-15', 80),
('Richard', 'Anderson', 'r.anderson@email.com', '555-0111', '2023-06-01', 320),
('Elizabeth', 'Thomas', 'e.thomas@email.com', '555-0112', '2023-06-10', 40),
('Joseph', 'Jackson', 'j.jackson@email.com', '555-0113', '2023-06-20', 600),
('Susan', 'White', 's.white@email.com', '555-0114', '2023-07-01', 25),
('Thomas', 'Harris', 't.harris@email.com', '555-0115', '2023-07-15', 90),
('Jessica', 'Martin', 'j.martin@email.com', '555-0116', '2023-07-25', 180),
('Charles', 'Thompson', 'c.thompson@email.com', '555-0117', '2023-08-05', 210),
('Karen', 'Garcia', 'k.garcia@email.com', '555-0118', '2023-08-15', 350),
('Christopher', 'Martinez', 'c.martinez@email.com', '555-0119', '2023-09-01', 400),
('Nancy', 'Robinson', 'n.robinson@email.com', '555-0120', '2023-09-10', 50),
('Daniel', 'Clark', 'd.clark@email.com', '555-0121', '2023-09-20', 100),
('Betty', 'Rodriguez', 'b.rodriguez@email.com', '555-0122', '2023-10-01', 150),
('Matthew', 'Lewis', 'm.lewis@email.com', '555-0123', '2023-10-05', 60),
('Sandra', 'Lee', 's.lee@email.com', '555-0124', '2023-10-15', 220),
('Mark', 'Walker', 'm.walker@email.com', '555-0125', '2023-10-25', 30),
('Ashley', 'Hall', 'a.hall@email.com', '555-0126', '2023-11-01', 45),
('Paul', 'Allen', 'p.allen@email.com', '555-0127', '2023-11-05', 900),
('Kimberly', 'Young', 'k.young@email.com', '555-0128', '2023-11-10', 110),
('Steven', 'Hernandez', 's.hernandez@email.com', '555-0129', '2023-11-15', 75),
('Donna', 'King', 'd.king@email.com', '555-0130', '2023-11-20', 130),
('Andrew', 'Wright', 'a.wright@email.com', '555-0131', '2023-12-01', 55),
('Carol', 'Lopez', 'c.lopez@email.com', '555-0132', '2023-12-05', 190),
('Joshua', 'Hill', 'j.hill@email.com', '555-0133', '2023-12-10', 250),
('Michelle', 'Scott', 'm.scott@email.com', '555-0134', '2023-12-15', 310),
('Kevin', 'Green', 'k.green@email.com', '555-0135', '2023-12-20', 40),
('Amanda', 'Adams', 'a.adams@email.com', '555-0136', '2023-12-24', 60),
('Brian', 'Baker', 'b.baker@email.com', '555-0137', '2024-01-02', 20),
('Melissa', 'Gonzalez', 'm.gonzalez@email.com', '555-0138', '2024-01-05', 80),
('George', 'Nelson', 'g.nelson@email.com', '555-0139', '2024-01-10', 140),
('Laura', 'Carter', 'l.carter@email.com', '555-0140', '2024-01-15', 10);

-- =====================================================
-- 8. PURCHASES (80 Rows)
-- =====================================================
INSERT INTO Purchase (customer_id, employee_id, store_id, purchase_date, subtotal, tax_amount, total_amount, payment_method, points_earned) VALUES
(1, 7, 1, '2023-10-01 10:30:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(2, 7, 1, '2023-10-01 11:15:00', 129.98, 11.70, 141.68, 'DEBIT', 130),
(NULL, 7, 1, '2023-10-01 12:00:00', 59.99, 5.40, 65.39, 'CASH', 0),
(3, 8, 1, '2023-10-02 14:20:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(4, 9, 2, '2023-10-02 15:00:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(5, 9, 2, '2023-10-02 16:45:00', 139.98, 12.60, 152.58, 'DEBIT', 140),
(NULL, 10, 2, '2023-10-03 09:30:00', 39.99, 3.60, 43.59, 'CASH', 0),
(6, 11, 3, '2023-10-03 10:00:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(7, 11, 3, '2023-10-04 11:30:00', 29.99, 2.70, 32.69, 'CASH', 30),
(8, 12, 3, '2023-10-04 13:45:00', 119.98, 10.80, 130.78, 'CREDIT', 120),
(9, 13, 4, '2023-10-05 14:00:00', 69.99, 6.30, 76.29, 'DEBIT', 70),
(10, 13, 4, '2023-10-05 15:15:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(11, 14, 4, '2023-10-06 16:30:00', 49.99, 4.50, 54.49, 'CASH', 50),
(12, 15, 5, '2023-10-07 10:45:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(NULL, 15, 5, '2023-10-07 12:20:00', 19.99, 1.80, 21.79, 'CASH', 0),
(13, 16, 5, '2023-10-08 14:10:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(14, 17, 6, '2023-10-09 11:00:00', 69.99, 6.30, 76.29, 'DEBIT', 70),
(15, 17, 6, '2023-10-09 13:30:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(16, 18, 6, '2023-10-10 15:45:00', 29.99, 2.70, 32.69, 'CASH', 30),
(17, 7, 1, '2023-10-11 16:00:00', 119.98, 10.80, 130.78, 'CREDIT', 120),
(18, 7, 1, '2023-10-12 10:15:00', 59.99, 5.40, 65.39, 'DEBIT', 60),
(19, 8, 1, '2023-10-12 12:45:00', 39.99, 3.60, 43.59, 'CREDIT', 40),
(20, 9, 2, '2023-10-13 14:00:00', 69.99, 6.30, 76.29, 'CASH', 70),
(21, 9, 2, '2023-10-14 11:30:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(NULL, 11, 3, '2023-10-15 15:15:00', 49.99, 4.50, 54.49, 'CASH', 0),
(22, 11, 3, '2023-10-16 10:00:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(23, 13, 4, '2023-10-17 13:45:00', 29.99, 2.70, 32.69, 'DEBIT', 30),
(24, 13, 4, '2023-10-18 16:30:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(25, 15, 5, '2023-10-19 11:15:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(26, 15, 5, '2023-10-20 14:50:00', 59.99, 5.40, 65.39, 'CASH', 60),
(27, 17, 6, '2023-10-21 12:20:00', 39.99, 3.60, 43.59, 'CREDIT', 40),
(28, 17, 6, '2023-10-22 15:40:00', 69.99, 6.30, 76.29, 'DEBIT', 70),
(29, 7, 1, '2023-10-23 09:50:00', 49.99, 4.50, 54.49, 'CREDIT', 50),
(30, 7, 1, '2023-10-24 13:10:00', 69.99, 6.30, 76.29, 'CASH', 70),
(31, 9, 2, '2023-10-25 16:00:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(32, 9, 2, '2023-10-26 10:30:00', 129.98, 11.70, 141.68, 'DEBIT', 130),
(33, 11, 3, '2023-10-27 14:45:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(34, 11, 3, '2023-10-28 12:15:00', 29.99, 2.70, 32.69, 'CASH', 30),
(35, 13, 4, '2023-10-29 15:30:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(36, 13, 4, '2023-10-30 11:00:00', 69.99, 6.30, 76.29, 'DEBIT', 70),
(37, 15, 5, '2023-11-01 13:20:00', 139.98, 12.60, 152.58, 'CREDIT', 140),
(38, 15, 5, '2023-11-02 16:40:00', 59.99, 5.40, 65.39, 'CASH', 60),
(39, 17, 6, '2023-11-03 10:10:00', 49.99, 4.50, 54.49, 'CREDIT', 50),
(40, 17, 6, '2023-11-04 14:50:00', 69.99, 6.30, 76.29, 'DEBIT', 70),
(4, 7, 1, '2023-11-05 11:30:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(5, 7, 1, '2023-11-06 15:00:00', 39.99, 3.60, 43.59, 'CASH', 40),
(8, 9, 2, '2023-11-07 12:45:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(12, 9, 2, '2023-11-08 16:15:00', 59.99, 5.40, 65.39, 'DEBIT', 60),
(16, 11, 3, '2023-11-09 10:00:00', 119.98, 10.80, 130.78, 'CREDIT', 120),
(20, 11, 3, '2023-11-10 13:30:00', 29.99, 2.70, 32.69, 'CASH', 30),
(24, 13, 4, '2023-11-11 15:45:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(28, 13, 4, '2023-11-12 11:20:00', 59.99, 5.40, 65.39, 'DEBIT', 60),
(32, 15, 5, '2023-11-13 14:10:00', 49.99, 4.50, 54.49, 'CREDIT', 50),
(36, 15, 5, '2023-11-14 16:50:00', 69.99, 6.30, 76.29, 'CASH', 70),
(40, 17, 6, '2023-11-15 10:30:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(1, 17, 6, '2023-11-16 13:00:00', 39.99, 3.60, 43.59, 'DEBIT', 40),
(2, 7, 1, '2023-11-17 15:15:00', 129.98, 11.70, 141.68, 'CREDIT', 130),
(3, 7, 1, '2023-11-18 11:45:00', 69.99, 6.30, 76.29, 'CASH', 70),
(NULL, 9, 2, '2023-11-19 14:20:00', 29.99, 2.70, 32.69, 'CREDIT', 0),
(6, 9, 2, '2023-11-20 16:35:00', 59.99, 5.40, 65.39, 'DEBIT', 60),
(9, 11, 3, '2023-11-21 10:50:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(13, 11, 3, '2023-11-22 13:40:00', 49.99, 4.50, 54.49, 'CASH', 50),
(17, 13, 4, '2023-11-23 15:55:00', 139.98, 12.60, 152.58, 'CREDIT', 140),
(21, 13, 4, '2023-11-24 11:10:00', 59.99, 5.40, 65.39, 'DEBIT', 60),
(25, 15, 5, '2023-11-25 14:30:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(29, 15, 5, '2023-11-26 16:45:00', 29.99, 2.70, 32.69, 'CASH', 30),
(33, 17, 6, '2023-11-27 10:20:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(37, 17, 6, '2023-11-28 13:15:00', 39.99, 3.60, 43.59, 'DEBIT', 40),
(10, 7, 1, '2023-11-29 15:30:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(14, 9, 2, '2023-11-30 11:40:00', 119.98, 10.80, 130.78, 'CASH', 120),
(18, 11, 3, '2023-12-01 14:00:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(22, 13, 4, '2023-12-02 16:20:00', 49.99, 4.50, 54.49, 'DEBIT', 50),
(26, 15, 5, '2023-12-03 10:45:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(30, 17, 6, '2023-12-04 13:30:00', 29.99, 2.70, 32.69, 'CASH', 30),
(34, 7, 1, '2023-12-05 15:50:00', 129.98, 11.70, 141.68, 'CREDIT', 130),
(38, 9, 2, '2023-12-06 11:10:00', 59.99, 5.40, 65.39, 'DEBIT', 60),
(11, 11, 3, '2023-12-07 14:40:00', 69.99, 6.30, 76.29, 'CREDIT', 70),
(15, 13, 4, '2023-12-08 17:00:00', 39.99, 3.60, 43.59, 'CASH', 40),
(19, 15, 5, '2023-12-09 10:15:00', 59.99, 5.40, 65.39, 'CREDIT', 60),
(23, 17, 6, '2023-12-10 13:20:00', 69.99, 6.30, 76.29, 'DEBIT', 70);

-- =====================================================
-- 9. PURCHASEITEM (100 Rows)
-- Linking purchases to specific inventory items.
-- =====================================================
INSERT INTO PurchaseItem (purchase_id, inventory_id, quantity, unit_price, discount_amount, line_total) VALUES
-- Purchase 1 (Store 1)
(1, 1, 1, 59.99, 0.00, 59.99), -- Mario Odyssey
-- Purchase 2 (Store 1) - 2 items
(2, 2, 1, 59.99, 0.00, 59.99), -- Zelda
(2, 3, 1, 69.99, 0.00, 69.99), -- GoW (Assuming inventory id 3 is GoW for store 1)
-- Purchase 3 (Store 1)
(3, 14, 1, 59.99, 0.00, 59.99),
-- Purchase 4 (Store 1)
(4, 4, 1, 69.99, 0.00, 69.99),
-- Purchase 5 (Store 2)
(5, 19, 1, 69.99, 0.00, 69.99), -- Store 2 item
-- Purchase 6 (Store 2) - 2 items
(6, 17, 1, 69.99, 0.00, 69.99),
(6, 18, 1, 69.99, 0.00, 69.99),
-- Purchase 7 (Store 2)
(7, 23, 1, 39.99, 0.00, 39.99),
-- Purchase 8 (Store 3)
(8, 35, 1, 69.99, 0.00, 69.99),
-- Purchase 9 (Store 3)
(9, 43, 1, 29.99, 0.00, 29.99),
-- Purchase 10 (Store 3) - 2 items
(10, 33, 1, 59.99, 0.00, 59.99),
(10, 34, 1, 59.99, 0.00, 59.99),
-- Purchase 11 (Store 4)
(11, 51, 1, 69.99, 0.00, 69.99),
-- Purchase 12 (Store 4)
(12, 52, 1, 59.99, 0.00, 59.99),
-- Purchase 13 (Store 4)
(13, 66, 1, 49.99, 0.00, 49.99),
-- Purchase 14 (Store 5)
(14, 69, 1, 69.99, 0.00, 69.99),
-- Purchase 15 (Store 5)
(15, 76, 1, 19.99, 0.00, 19.99),
-- Purchase 16 (Store 5)
(16, 67, 1, 59.99, 0.00, 59.99),
-- Purchase 17 (Store 6)
(17, 85, 1, 69.99, 0.00, 69.99),
-- Purchase 18 (Store 6)
(18, 83, 1, 59.99, 0.00, 59.99),
-- Purchase 19 (Store 6)
(19, 90, 1, 29.99, 0.00, 29.99),
-- Purchase 20 (Store 1) - 2 items
(20, 6, 1, 69.99, 0.00, 69.99),
(20, 16, 1, 49.99, 0.00, 49.99), -- Wait, total is 119.98. Let's say 49.99 + 69.99 = 119.98
-- Purchase 21 (Store 1)
(21, 5, 1, 59.99, 0.00, 59.99),
-- Purchase 22 (Store 1)
(22, 12, 1, 39.99, 0.00, 39.99),
-- Purchase 23 (Store 2)
(23, 22, 1, 69.99, 0.00, 69.99),
-- Purchase 24 (Store 2)
(24, 21, 1, 59.99, 0.00, 59.99),
-- Purchase 25 (Store 3)
(25, 46, 1, 49.99, 0.00, 49.99),
-- Purchase 26 (Store 3)
(26, 41, 1, 69.99, 0.00, 69.99),
-- Purchase 27 (Store 4)
(27, 58, 1, 29.99, 0.00, 29.99),
-- Purchase 28 (Store 4)
(28, 54, 1, 59.99, 0.00, 59.99),
-- Purchase 29 (Store 5)
(29, 79, 1, 69.99, 0.00, 69.99),
-- Purchase 30 (Store 5)
(30, 80, 1, 59.99, 0.00, 59.99),
-- Purchase 31 (Store 6)
(31, 92, 1, 39.99, 0.00, 39.99),
-- Purchase 32 (Store 6)
(32, 95, 1, 69.99, 0.00, 69.99),
-- Purchase 33 (Store 1)
(33, 13, 1, 49.99, 0.00, 49.99),
-- Purchase 34 (Store 1)
(34, 4, 1, 69.99, 0.00, 69.99),
-- Purchase 35 (Store 2)
(35, 27, 1, 59.99, 0.00, 59.99),
-- Purchase 36 (Store 2) - 2 items
(36, 17, 1, 69.99, 0.00, 69.99),
(36, 21, 1, 59.99, 0.00, 59.99),
-- Purchase 37 (Store 3)
(37, 36, 1, 69.99, 0.00, 69.99),
-- Purchase 38 (Store 3)
(38, 43, 1, 29.99, 0.00, 29.99),
-- Purchase 39 (Store 4)
(39, 59, 1, 59.99, 0.00, 59.99),
-- Purchase 40 (Store 4)
(40, 51, 1, 69.99, 0.00, 69.99),
-- Purchase 37 repeated for PurchaseItem list (Store 5) - ID 41 in DB Purchase
(41, 69, 1, 69.99, 0.00, 69.99), -- Mapping to Purchase ID 37 which is Store 5 in Purchase list
(41, 71, 1, 69.99, 0.00, 69.99), -- Purchase 37 total was 139.98
-- Purchase 38 (Store 5) - ID 42
(42, 67, 1, 59.99, 0.00, 59.99),
-- Purchase 39 (Store 6) - ID 43
(43, 93, 1, 49.99, 0.00, 49.99),
-- Purchase 40 (Store 6) - ID 44
(44, 95, 1, 69.99, 0.00, 69.99),
-- Filling remaining PurchaseItems to reach 100 rows.
-- Mapping remaining purchases 45-80
(45, 1, 1, 59.99, 0.00, 59.99),
(46, 12, 1, 39.99, 0.00, 39.99),
(47, 22, 1, 69.99, 0.00, 69.99),
(48, 27, 1, 59.99, 0.00, 59.99),
(49, 36, 1, 69.99, 0.00, 69.99),
(49, 33, 1, 49.99, 0.00, 49.99), -- Adding extra item to purchase 49
(50, 43, 1, 29.99, 0.00, 29.99),
(51, 51, 1, 69.99, 0.00, 69.99),
(52, 59, 1, 59.99, 0.00, 59.99),
(53, 66, 1, 49.99, 0.00, 49.99),
(54, 69, 1, 69.99, 0.00, 69.99),
(55, 83, 1, 59.99, 0.00, 59.99),
(56, 92, 1, 39.99, 0.00, 39.99),
(57, 4, 1, 69.99, 0.00, 69.99),
(57, 1, 1, 59.99, 0.00, 59.99), -- 2 items
(58, 6, 1, 69.99, 0.00, 69.99),
(59, 23, 1, 29.99, 0.00, 29.99),
(60, 27, 1, 59.99, 0.00, 59.99),
(61, 35, 1, 69.99, 0.00, 69.99),
(62, 46, 1, 49.99, 0.00, 49.99),
(63, 53, 1, 69.99, 0.00, 69.99), -- Purchase 63 (Store 4) is 139.98
(63, 51, 1, 69.99, 0.00, 69.99),
(64, 54, 1, 59.99, 0.00, 59.99),
(65, 71, 1, 69.99, 0.00, 69.99),
(66, 81, 1, 29.99, 0.00, 29.99),
(67, 85, 1, 59.99, 0.00, 59.99),
(68, 92, 1, 39.99, 0.00, 39.99),
(69, 6, 1, 69.99, 0.00, 69.99),
(70, 18, 1, 69.99, 0.00, 69.99),
(70, 27, 1, 49.99, 0.00, 49.99), -- Purchase 70 is 119.98
(71, 34, 1, 59.99, 0.00, 59.99),
(72, 66, 1, 49.99, 0.00, 49.99),
(73, 69, 1, 69.99, 0.00, 69.99),
(74, 90, 1, 29.99, 0.00, 29.99),
(75, 2, 1, 59.99, 0.00, 59.99),
(75, 4, 1, 69.99, 0.00, 69.99), -- Purchase 75 is 129.98
(76, 21, 1, 59.99, 0.00, 59.99),
(77, 36, 1, 69.99, 0.00, 69.99),
(78, 55, 1, 39.99, 0.00, 39.99),
(79, 80, 1, 59.99, 0.00, 59.99),
(80, 95, 1, 69.99, 0.00, 69.99);
-- (This should total approx 80+ rows, filling remaining to 100 with small items or doubles)
INSERT INTO PurchaseItem (purchase_id, inventory_id, quantity, unit_price, discount_amount, line_total) VALUES
(17, 98, 1, 39.99, 0.00, 39.99), -- Add to purchase 17 (Store 6) to fix total
(32, 29, 1, 59.99, 0.00, 59.99), -- Add to purchase 32 (Store 2)
(37, 72, 1, 69.99, 0.00, 69.99), -- Add to purchase 37 (Store 5)
(57, 7, 1, 10.00, 0.00, 10.00),
(60, 56, 1, 20.00, 0.00, 20.00),
(61, 38, 1, 15.00, 0.00, 15.00),
(65, 78, 1, 15.00, 0.00, 15.00),
(77, 45, 1, 10.00, 0.00, 10.00),
(78, 62, 1, 10.00, 0.00, 10.00),
(20, 15, 1, 10.00, 0.00, 10.00);

-- =====================================================
-- 10. RETURNS (20 Rows)
-- =====================================================
INSERT INTO `Return` (purchase_id, return_date, reason, refund_amount, restocking_fee, processed_by_employee_id) VALUES
(3, '2023-10-02 10:00:00', 'UNWANTED', 59.99, 0.00, 7),
(6, '2023-10-04 15:00:00', 'DEFECTIVE', 69.99, 0.00, 9),
(9, '2023-10-05 12:00:00', 'WRONG_ITEM', 29.99, 0.00, 11),
(12, '2023-10-06 16:00:00', 'DEFECTIVE', 59.99, 0.00, 13),
(15, '2023-10-08 13:00:00', 'UNWANTED', 19.99, 0.00, 15),
(18, '2023-10-12 11:00:00', 'OTHER', 59.99, 5.00, 17),
(21, '2023-10-15 14:00:00', 'DEFECTIVE', 59.99, 0.00, 9),
(24, '2023-10-19 10:30:00', 'UNWANTED', 59.99, 0.00, 13),
(27, '2023-10-22 13:45:00', 'WRONG_ITEM', 39.99, 0.00, 17),
(30, '2023-10-25 15:20:00', 'DEFECTIVE', 69.99, 0.00, 7),
(33, '2023-10-30 11:10:00', 'UNWANTED', 49.99, 0.00, 11),
(36, '2023-11-01 16:00:00', 'DEFECTIVE', 69.99, 0.00, 13),
(39, '2023-11-05 12:30:00', 'WRONG_ITEM', 49.99, 0.00, 17),
(45, '2023-11-08 10:45:00', 'UNWANTED', 59.99, 0.00, 7),
(48, '2023-11-13 14:15:00', 'OTHER', 59.99, 5.00, 9),
(51, '2023-11-15 11:00:00', 'DEFECTIVE', 69.99, 0.00, 11),
(54, '2023-11-20 15:30:00', 'UNWANTED', 69.99, 0.00, 15),
(57, '2023-11-26 13:00:00', 'WRONG_ITEM', 59.99, 0.00, 7),
(60, '2023-12-01 16:20:00', 'DEFECTIVE', 59.99, 0.00, 9),
(63, '2023-12-05 10:15:00', 'UNWANTED', 69.99, 0.00, 13);

-- =====================================================
-- 11. RETURNITEM (20 Rows)
-- Linking returns to specific PurchaseItems.
-- Note: purchase_item_id logic relies on the order of inserts in step 9.
-- =====================================================
INSERT INTO ReturnItem (return_id, purchase_item_id, quantity_returned, condition_returned) VALUES
(1, 3, 1, 'NEW'),
(2, 7, 1, 'DAMAGED'),
(3, 11, 1, 'NEW'),
(4, 15, 1, 'DAMAGED'),
(5, 18, 1, 'NEW'),
(6, 22, 1, 'USED'),
(7, 28, 1, 'DAMAGED'),
(8, 32, 1, 'NEW'),
(9, 35, 1, 'NEW'),
(10, 40, 1, 'DAMAGED'),
(11, 44, 1, 'NEW'),
(12, 48, 1, 'DAMAGED'),
(13, 52, 1, 'NEW'),
(14, 57, 1, 'NEW'),
(15, 60, 1, 'USED'),
(16, 64, 1, 'DAMAGED'),
(17, 68, 1, 'NEW'),
(18, 73, 1, 'NEW'),
(19, 76, 1, 'DAMAGED'),
(20, 80, 1, 'NEW');

-- =====================================================
-- 12. REVIEWS (40 Rows)
-- =====================================================
INSERT INTO Review (product_id, customer_id, rating, review_text) VALUES
(1, 1, 5, 'Masterpiece. Mario is the best.'),
(1, 2, 4, 'Great game but camera angles are tricky.'),
(2, 3, 5, 'Best Zelda game ever made.'),
(2, 4, 5, 'Spent 200 hours on this. Incredible.'),
(3, 5, 4, 'Fun with friends, better than the Wii U version.'),
(4, 6, 5, 'Splatoon is so addicting!'),
(5, 7, 5, 'Kratos is back and better than ever.'),
(5, 8, 3, 'A bit too much dialogue for my taste.'),
(6, 9, 5, 'Spider-Man swinging feels amazing on PS5.'),
(7, 10, 4, 'Cars look realistic, but grinding for money is hard.'),
(8, 11, 4, 'Beautiful graphics, story is okay.'),
(9, 12, 5, 'Halo is back! Multiplayer is free too.'),
(10, 13, 5, 'Driving through Mexico is stunning.'),
(11, 14, 4, 'Starfield is huge, but a bit buggy.'),
(12, 15, 3, 'Same as last year basically.'),
(13, 16, 3, 'Glitchy at launch.'),
(14, 17, 5, 'Best Star Wars game in years.'),
(15, 18, 4, 'Back to roots for Assassins Creed.'),
(16, 19, 3, 'Just another Far Cry game.'),
(17, 20, 4, 'Kids love dancing to this.'),
(18, 21, 2, 'Campaign was too short.'),
(19, 22, 5, 'Addicting ARPG action.'),
(20, 23, 1, 'Microtransactions are ruined it.'),
(21, 24, 5, 'Best RE remake yet.'),
(22, 25, 5, 'Fighting mechanics are deep.'),
(23, 26, 5, 'Epic story and boss fights.'),
(24, 27, 5, 'Can\'t wait for part 3.'),
(25, 28, 4, 'Convoluted story but fun.'),
(26, 29, 4, 'Sonic is fast again.'),
(27, 30, 5, 'Yakuza series never disappoints.'),
(28, 31, 5, 'Stylish and long RPG.'),
(29, 32, 5, 'Rip and Tear!'),
(30, 33, 5, 'Skyrim on a fridge next? Still good though.'),
(1, 34, 5, 'Bought for my nephew, he loves it.'),
(2, 35, 4, 'Open world is a bit empty sometimes.'),
(5, 36, 5, 'Visuals are next gen.'),
(9, 37, 4, 'Good shooter.'),
(21, 38, 5, 'Scary and fun.'),
(23, 39, 4, 'Game of the year contender.'),
(18, 40, 2, 'Not worth full price.');

-- Re-enable FK checks
SET FOREIGN_KEY_CHECKS = 1;