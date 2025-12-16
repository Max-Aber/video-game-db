# Video Game Store Database: Design Rationale

**Project:** Video Game Retail Management System  
**Date:** December 2025

---

## 1. Introduction

This document details the architectural decisions, logical modeling, and schema implementation for the Video Game Store relational database. The goal of this system is to support the daily operations of a multi-location retail chain, similar to GameStop, handling inventory management, customer loyalty programs, sales processing, and analytics.

The design prioritizes data integrity (ACID compliance), historical accuracy of financial records, and query performance for high-frequency operations.

---

## 2. Requirements Analysis

Before defining the schema, the following core functional requirements and business rules were identified:

### 2.1 Core Entities

- **Inventory Management:** Must track products distinct from their physical stock levels at specific locations.
- **Sales Processing:** Must support multi-item transactions, distinct payment methods, and tax calculations.
- **Returns:** Must link specific returned items to their original purchase to prevent fraud (e.g., returning an item not bought there).
- **Staffing:** Must track employees, their specific store assignments, and hierarchy (Managers vs. Cashiers).
- **Customer Loyalty:** Must track customer points and purchase history for analytics.

### 2.2 Key Business Rules

- **Price Volatility:** Product MSRP may change, but historical sales records must preserve the exact price paid at the moment of purchase.
- **Inventory Control:** Sales cannot occur if stock is insufficient.
- **Return Window:** Returns are only valid within 90 days of purchase.
- **One Review Per Product:** A customer cannot review the same game twice to prevent rating manipulation.
- **Managerial Assignment:** Every store must have a manager, who is also an employee.

---

## 3. Conceptual Data Model

The transition from requirements to model resulted in a Normalized Relational Model. Key modeling decisions include:

### 3.1 Separation of Product and Inventory

A naive design might place a quantity column directly in the Product table. However, since this is a multi-store system, we separated these entities:

- **Product:** Represents the "metadata" (Name, ESRB Rating, Global MSRP). This data is constant across all stores.
- **Inventory:** Represents the physical stock. It is a composite entity linking Store and Product. This allows Store A to have 5 copies while Store B has 0.

### 3.2 The Purchase vs. PurchaseItem Header-Line Pattern

To handle transactions containing multiple unique items, the standard Header-Line Item pattern was adopted:

- **Purchase (Header):** Stores transaction-level data (Date, Total, Customer, Employee).
- **PurchaseItem (Line):** Stores item-level data (Product ID, Quantity, Line Total).

**Rationale:** This prevents data redundancy. Storing item details in the header would violate First Normal Form (repeating groups).

### 3.3 Circular Dependency Handling (Store & Employee)

A "Chicken and Egg" problem exists in the model:

- An Employee works at a Store.
- A Store is managed by a Manager (who is an Employee).

**Solution:** Both foreign keys are included (`Employee.store_id` and `Store.manager_id`). In the physical implementation, one field is made nullable or constraints are temporarily disabled during seeding to resolve the insertion cycle.

---

## 4. Schema Design & Key Decisions

### 4.1 Normalization Strategy (3NF)

The schema is designed to be in Third Normal Form (3NF) to minimize redundancy and update anomalies.

- **1NF (Atomic Values):** No columns contain lists (e.g., a "Skills" column for employees).
- **2NF (Partial Dependencies):** All bridge tables (PurchaseItem, Inventory) rely on the full composite primary key or a new surrogate key.
- **3NF (Transitive Dependencies):**
  - *Decision:* Customer addresses were removed to keep the scope manageable, but Vendor country codes are stored directly.
  - *Decision:* Product contains `category_id` rather than a Category Name string, ensuring that if a category is renamed (e.g., "RPG" to "Role-Playing"), it updates globally without modifying thousands of product rows.

### 4.2 Handling Historical Financial Data

One of the most critical design decisions was data denormalization for history.

**The Problem:** If a Product's price is updated from $59.99 to $29.99 today, old reports should not recalculate last year's revenue using today's price.

**The Solution:** The `PurchaseItem` table includes a `unit_price` column.

**Rationale:** This copies the price at the time of sale into the transaction record. This redundancy is intentional and necessary for financial auditing.

### 4.3 Surrogate Keys vs. Natural Keys

**Decision:** Integer `AUTO_INCREMENT` surrogate keys (e.g., `product_id`, `vendor_id`) are used for all primary keys.

**Rationale:** While "Vendor Name" or "UPC" could be natural keys, they are subject to change or external formatting issues. Surrogate keys provide immutable, efficient indexing references.

---

## 5. Integrity & Constraints

### 5.1 Data Constraints

**ENUM Types:** Used for `esrb_rating` ('E', 'T', 'M') and `condition` ('NEW', 'USED'). This enforces data consistency at the database level, preventing typos like 'Teen' vs 'T'.

**CHECK Constraints:**

- `msrp >= 0`: Prevents negative pricing errors.
- `rating BETWEEN 1 AND 5`: Ensures review scores remain on the 5-star scale.

### 5.2 Business Logic Implementation

Since SQL constraints cannot easily reference other tables or dates, Triggers were used for complex logic:

- **Inventory Automation (`trg_reduce_inventory_after_purchase`):** Automatically decrements stock upon sale. This prevents "phantom inventory" where the database says an item is in stock, but it was just sold.
- **Return Policy Enforcement (`trg_enforce_return_window`):** Calculates the delta between `purchase_date` and `return_date`. If >90 days, the transaction is rejected. This moves business rule enforcement from the application layer to the database layer, ensuring consistency regardless of which app accesses the DB.

---

## 6. Performance Optimization

### 6.1 Indexing Strategy

Indexes were applied based on anticipated query patterns:

- **Search Optimization:** A partial index on `Product(name)` speeds up search bar queries (`LIKE 'Mario%'`) without indexing the full 200-character width.
- **Sorting Optimization:** Composite index on `Purchase(customer_id, purchase_date)` allows the "Order History" page to load instantly without performing a CPU-intensive "Filesort."
- **FK Indexing:** All Foreign Keys are indexed to prevent full table scans during JOIN operations.

### 6.2 Views for Security and Usability

- **Security:** `v_employee_public_directory` exposes staff names and locations but explicitly hides sensitive `hourly_wage` and `phone_number` columns.
- **Usability:** `v_restock_urgency_list` pre-calculates the logic `quantity <= threshold`. This creates a simplified interface for application developers, who simply `SELECT * FROM v_restock` rather than writing complex filtering logic.

---

## 7. Assumptions & Limitations

### 7.1 Assumptions

- **Currency:** All monetary values are assumed to be in a single currency (USD). No currency conversion table exists.
- **Single Tax Rate:** The `tax_amount` is calculated and stored at the transaction level. The schema assumes tax logic is handled by the Point-of-Sale application before insertion.
- **Physical Inventory:** We assume Inventory represents "Sellable Stock." Damaged items returned are tracked in ReturnItem but do not automatically increment the sellable Inventory count (requires manual clerk review).

### 7.2 Limitations / Future Work

- **Transfer Logic:** Currently, moving stock from Store A to Store B requires a manual decrement and increment transaction. A dedicated Transfer table would improve audit trails for inter-store shipments.
- **Complex Promotions:** Discounts are currently handled via a flat `discount_amount` column. A dedicated Promotions engine (Buy One Get One, Coupon Codes) would require a more complex many-to-many schema.
- **Address Validation:** Customer addresses are simple strings. A robust system would normalize City/State/Zip into separate lookup tables or integrate with an address verification API.

---

## 8. Conclusion

The Video Game Store database schema successfully maps complex retail requirements into a robust, normalized relational structure. By utilizing triggers for business rules, composite indexes for performance, and strict foreign key constraints for integrity, the system ensures reliable operation. The design balances strict normalization with necessary denormalization (historical pricing) to support both operational speed and analytical accuracy.