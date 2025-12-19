#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Video Game Store DB - EXPLAIN Script (Schema-aligned)
# - Runs EXPLAIN before/after dropping + recreating a relevant index
# - Shows index inventory for all existing tables
# - Supports Docker mode (matches load.sh style)
# ==============================================================================

# ----------------------------
# Defaults (match your setup)
# ----------------------------
USE_DOCKER=true
CONTAINER_NAME="video_game_store_db"

DB_NAME="video_game_store"
DB_USER="root"
DB_HOST="localhost"
DB_PORT="3307"   # mapped port in docker-compose (local mode only)

# ----------------------------
# Parse args
# ----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --docker) USE_DOCKER=true; shift ;;
    --local)  USE_DOCKER=false; shift ;;
    --port)   DB_PORT="${2:-3306}"; shift 2 ;;
    *)        shift ;;
  esac
done

# ----------------------------
# Colors
# ----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
  echo -e "${BLUE}============================================================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}============================================================================${NC}"
}
print_subheader() { echo -e "${MAGENTA}--- $1 ---${NC}"; }
print_info()      { echo -e "${YELLOW}ℹ $1${NC}"; }
print_success()   { echo -e "${GREEN}✓ $1${NC}"; }
print_error()     { echo -e "${RED}✗ $1${NC}"; }
print_observation() { echo -e "${CYAN}  • $1${NC}"; }

# ----------------------------
# Password (hidden prompt)
# ----------------------------
if [[ -z "${DB_PASSWORD:-}" ]]; then
  read -s -p "Enter MySQL Password for user '$DB_USER': " DB_PASSWORD
  echo ""
fi

# ----------------------------
# MySQL runner
#   - Uses MYSQL_PWD to avoid "password on CLI" warning (like load.sh)
#   - Docker mode runs mysql inside container
# ----------------------------
mysql_exec() {
  local query="$1"

  if [[ "$USE_DOCKER" == true ]]; then
    docker exec -i -e MYSQL_PWD="$DB_PASSWORD" "$CONTAINER_NAME" \
      mysql -u "$DB_USER" -D "$DB_NAME" -e "$query"
  else
    MYSQL_PWD="$DB_PASSWORD" \
      mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -e "$query"
  fi
}

# Same as mysql_exec, but prints vertical output (better for EXPLAIN readability)
mysql_exec_vertical() {
  local query="$1"
  mysql_exec "$query\\G"
}

# Run a statement but don't fail the script if it errors (e.g., index doesn't exist)
mysql_try() {
  local query="$1"
  set +e
  mysql_exec "$query" >/dev/null 2>&1
  set -e
}

# ----------------------------
# Query + index toggle runner
# ----------------------------
run_explain_case() {
  local title="$1"
  local desc="$2"
  local sql="$3"
  local drop_stmt="$4"
  local create_stmt="$5"

  echo ""
  print_header "$title"
  print_info "$desc"
  print_subheader "Query"
  echo "$sql"
  echo ""

  # WITHOUT index
  print_subheader "EXPLAIN (Without Index)"
  if [[ -n "$drop_stmt" ]]; then
    mysql_try "$drop_stmt"
    print_info "Dropped (if existed): $drop_stmt"
  fi
  mysql_exec_vertical "EXPLAIN $sql"
  echo ""

  # WITH index
  print_subheader "EXPLAIN (With Index)"
  if [[ -n "$create_stmt" ]]; then
    mysql_try "$create_stmt"
    print_info "Created (if needed): $create_stmt"
  fi
  mysql_exec_vertical "EXPLAIN $sql"
  echo ""
}

# ----------------------------
# Query + IGNORE INDEX runner (for queries with pre-existing indexes)
# ----------------------------
run_explain_case_ignore() {
  local title="$1"
  local desc="$2"
  local sql_without="$3"  # Query WITH IGNORE INDEX
  local sql_with="$4"     # Query WITHOUT IGNORE INDEX (normal)

  echo ""
  print_header "$title"
  print_info "$desc"
  
  print_subheader "Query (Forced No Index via IGNORE INDEX)"
  echo "$sql_without"
  echo ""
  
  print_subheader "EXPLAIN (Without Index)"
  print_info "Using IGNORE INDEX to force table scan"
  mysql_exec_vertical "EXPLAIN $sql_without"
  echo ""

  print_subheader "Query (With Index - Normal Optimizer)"
  echo "$sql_with"
  echo ""
  
  print_subheader "EXPLAIN (With Index)"
  print_info "Optimizer free to choose best index"
  mysql_exec_vertical "EXPLAIN $sql_with"
  echo ""
}

print_header "Query Performance Analysis with EXPLAIN"

echo ""
print_info "PURPOSE:"
echo "  This script demonstrates the impact of indexes on query performance"
echo "  by running EXPLAIN on various queries with and without indexes."
echo ""
print_info "WHAT IT DOES:"
echo "  1. Analyzes complex queries from the video game store database"
echo "  2. Shows EXPLAIN output before and after adding indexes"
echo "  3. Compares performance metrics (type, rows examined, key usage)"
echo "  4. Displays index inventory for all tables"
echo "  5. Provides recommendations for query optimization"
echo ""
print_info "Database: $DB_NAME @ $DB_HOST:$DB_PORT"
if [[ "$USE_DOCKER" == true ]]; then
  print_info "Mode: Docker (container: $CONTAINER_NAME)"
else
  print_info "Mode: Local MySQL"
fi
echo ""
print_info "Mode: $([[ "$USE_DOCKER" == true ]] && echo Docker || echo Local)"
echo ""

# ==============================================================================
# Queries (these match your actual schema tables: Product, Review, Inventory, etc.)
# ==============================================================================

# 1) Game Catalog Lookup by Platform
run_explain_case \
  "Game Catalog Lookup by Platform" \
  "Browse products for a platform + average review rating" \
  "SELECT
     p.name AS product_name,
     p.platform,
     p.esrb_rating,
     c.name AS category,
     v.name AS vendor,
     p.msrp,
     ROUND(AVG(r.rating), 2) AS avg_rating
   FROM Product p
   LEFT JOIN Category c ON p.category_id = c.category_id
   LEFT JOIN Vendor v ON p.vendor_id = v.vendor_id
   LEFT JOIN Review r ON p.product_id = r.product_id
   WHERE p.platform = 'PlayStation 5'
   GROUP BY p.product_id, p.name, p.platform, p.esrb_rating, c.name, v.name, p.msrp
   ORDER BY avg_rating DESC;" \
  "DROP INDEX idx_product_platform ON Product;" \
  "CREATE INDEX idx_product_platform ON Product(platform);"

print_subheader "Key Observations"
print_observation "97% row reduction (30→1): Full table scan with 10% filtered vs. direct index access to single PlayStation 5 product"
print_observation "Access type improved ALL→ref: Table scan eliminated; 'ref' with 'const' means compile-time index lookup"
print_observation "'Using where' eliminated: Filter satisfied during index lookup instead of post-read processing"
echo ""

# 2) Inventory Check Across Stores
run_explain_case_ignore \
  "Inventory Check Across Stores" \
  "Find stores that have a specific product in stock" \
  "SELECT s.store_name, s.city, i.quantity_available
   FROM Store s
   JOIN Inventory i IGNORE INDEX (idx_inventory_product, uk_inventory_store_product, idx_inventory_low_stock, idx_inventory_range)
     ON s.store_id = i.store_id
   WHERE i.product_id = (SELECT product_id FROM Product WHERE name = 'Super Mario Odyssey' LIMIT 1)
     AND i.quantity_available > 0
   ORDER BY i.quantity_available DESC;" \
  "SELECT s.store_name, s.city, i.quantity_available
   FROM Store s
   JOIN Inventory i ON s.store_id = i.store_id
   WHERE i.product_id = (SELECT product_id FROM Product WHERE name = 'Super Mario Odyssey' LIMIT 1)
     AND i.quantity_available > 0
   ORDER BY i.quantity_available DESC;"

print_subheader "Key Observations"
print_observation "94% row reduction (100→6): Forced full scan with 1.11% selectivity vs. idx_inventory_product direct retrieval"
print_observation "Type ALL→ref on Inventory: Table scan becomes indexed lookup; key column changes from NULL to idx_inventory_product"
print_observation "Filtered improved 1.11%→100%: Poor selectivity estimate without index vs. perfect targeting with index"
echo ""

# 3) Purchase Line Items Report
run_explain_case \
  "Purchase Line Items Report" \
  "Retrieve purchase details for specific inventory range" \
  "SELECT purchase_id, inventory_id, quantity, unit_price
   FROM PurchaseItem
   WHERE inventory_id BETWEEN 10 AND 50
   ORDER BY inventory_id;" \
  "DROP INDEX idx_purchaseitem_covering ON PurchaseItem;" \
  "CREATE INDEX idx_purchaseitem_covering ON PurchaseItem(inventory_id, purchase_id, quantity, unit_price);"

print_subheader "Key Observations"
print_observation "60% row reduction (101→40) with range scan: Type ALL→range efficiently skips non-matching index entries"
print_observation "Covering index 'Using index': All SELECT columns in index—zero table access, drastically reduced I/O"
print_observation "Filesort eliminated: ORDER BY satisfied by index order; no in-memory sorting of 101 rows"
echo ""

# 4) Customer Purchase History
run_explain_case \
  "Customer Purchase History" \
  "View recent orders for a specific customer" \
  "SELECT purchase_id, customer_id, purchase_date, total_amount
   FROM Purchase
   WHERE customer_id = 5
   ORDER BY purchase_date DESC
   LIMIT 10;" \
  "DROP INDEX idx_purchase_cust_date ON Purchase;" \
  "CREATE INDEX idx_purchase_cust_date ON Purchase(customer_id, purchase_date);"

print_subheader "Key Observations"
print_observation "Filesort eliminated via 'Backward index scan': Composite index stores data sorted by (customer_id, purchase_date)"
print_observation "MySQL 8.0 optimization: Reads composite index in reverse for DESC without creating sorted result set"
print_observation "Same rows (2) but zero sorting overhead: Prevents expensive disk-based temp tables for larger result sets"
echo ""

# 5) Store Performance Comparison
run_explain_case_ignore \
  "Store Performance Comparison" \
  "Compare sales metrics across stores" \
  "SELECT s.store_name,
          COUNT(DISTINCT pu.purchase_id) AS order_count,
          SUM(pu.total_amount) AS total_revenue,
          ROUND(AVG(pu.total_amount), 2) AS avg_order_value
   FROM Store s
   LEFT JOIN Purchase pu IGNORE INDEX (idx_purchase_store, idx_purchase_employee, idx_purchase_date, idx_purchase_cust_date, idx_purchase_customer)
     ON s.store_id = pu.store_id
   GROUP BY s.store_id, s.store_name
   ORDER BY total_revenue DESC;" \
  "SELECT s.store_name,
          COUNT(DISTINCT pu.purchase_id) AS order_count,
          SUM(pu.total_amount) AS total_revenue,
          ROUND(AVG(pu.total_amount), 2) AS avg_order_value
   FROM Store s
   LEFT JOIN Purchase pu ON s.store_id = pu.store_id
   GROUP BY s.store_id, s.store_name
   ORDER BY total_revenue DESC;"

print_subheader "Key Observations"
print_observation "83% row reduction (80→13 per store): Sequential scan of all purchases vs. ref lookup per store_id"
print_observation "Join strategy hash join→indexed nested loop: Memory-loaded buffer vs. efficient per-store ref lookups"
print_observation "Type ALL→ref on Purchase: Full table scan becomes idx_purchase_store access for LEFT JOIN efficiency"
echo ""

# 6) Low Stock Alert for Specific Store
run_explain_case \
  "Low Stock Alert for Specific Store" \
  "Find items running low at a particular store location" \
  "SELECT store_id, product_id, quantity_available, current_price
   FROM Inventory
   WHERE store_id = 1 AND quantity_available < 10
   ORDER BY quantity_available;" \
  "DROP INDEX idx_inventory_range ON Inventory;" \
  "CREATE INDEX idx_inventory_range ON Inventory(store_id, quantity_available);"

print_subheader "Key Observations"
print_observation "37.5% row reduction (16→10) with type ref→range: Single-column ref vs. composite index range scan"
print_observation "'Using index condition' (ICP): Quantity filter evaluated during index traversal"
print_observation "Filtered 60%→100%: Fetch-then-filter (16 rows) vs. composite index direct navigation to matching rows"
echo ""

# ==============================================================================
# Index inventory for all existing tables (no hardcoded, no missing-table errors)
# ==============================================================================
print_header "Index Inventory (All Tables)"

# Get tables (skip header row) and iterate
tables="$(mysql_exec "SHOW TABLES;" | awk 'NR>1 {print $1}')"

while read -r tbl; do
  [[ -z "$tbl" ]] && continue
  print_subheader "SHOW INDEX FROM $tbl"
  mysql_exec "SHOW INDEX FROM \`$tbl\`;"
  echo ""
done <<< "$tables"

print_header "Done"
print_success "EXPLAIN analysis complete."
