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

# 2) Inventory Check Across Stores
# Note: your schema already has idx_inventory_store + idx_inventory_product.
# This query benefits most from inventory(product_id, store_id) style access;
# we demonstrate by toggling idx_inventory_product (simple + safe).
run_explain_case \
  "Inventory Check Across Stores" \
  "Find stores that have a specific product in stock" \
  "SELECT s.store_name, s.city, i.quantity_available
   FROM Store s
   JOIN Inventory i ON s.store_id = i.store_id
   WHERE i.product_id = (
     SELECT product_id FROM Product WHERE name = 'The Last of Us Part II' LIMIT 1
   )
   AND i.quantity_available > 0
   ORDER BY i.quantity_available DESC;" \
  "DROP INDEX idx_inventory_product ON Inventory;" \
  "CREATE INDEX idx_inventory_product ON Inventory(product_id);"

# 3) Best Sellers Report
run_explain_case \
  "Best Sellers Report" \
  "Top-selling products by revenue" \
  "SELECT p.name AS product_name,
          SUM(pi.quantity * pi.unit_price) AS total_revenue,
          SUM(pi.quantity) AS units_sold
   FROM PurchaseItem pi
   JOIN Inventory i ON pi.inventory_id = i.inventory_id
   JOIN Product p ON i.product_id = p.product_id
   GROUP BY p.product_id, p.name
   ORDER BY total_revenue DESC
   LIMIT 10;" \
  "DROP INDEX idx_purchaseitem_inventory ON PurchaseItem;" \
  "CREATE INDEX idx_purchaseitem_inventory ON PurchaseItem(inventory_id);"

# 4) Customer Lifetime Value
run_explain_case \
  "Customer Lifetime Value" \
  "Top customers by total spending" \
  "SELECT c.customer_id,
          CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
          COUNT(DISTINCT pu.purchase_id) AS total_orders,
          SUM(pu.total_amount) AS lifetime_value
   FROM Customer c
   JOIN Purchase pu ON c.customer_id = pu.customer_id
   GROUP BY c.customer_id, c.first_name, c.last_name
   ORDER BY lifetime_value DESC
   LIMIT 20;" \
  "DROP INDEX idx_purchase_customer ON Purchase;" \
  "CREATE INDEX idx_purchase_customer ON Purchase(customer_id);"

# 5) Store Performance Comparison
run_explain_case \
  "Store Performance Comparison" \
  "Compare sales metrics across stores" \
  "SELECT s.store_name,
          COUNT(DISTINCT pu.purchase_id) AS order_count,
          SUM(pu.total_amount) AS total_revenue,
          ROUND(AVG(pu.total_amount), 2) AS avg_order_value
   FROM Store s
   LEFT JOIN Purchase pu ON s.store_id = pu.store_id
   GROUP BY s.store_id, s.store_name
   ORDER BY total_revenue DESC;" \
  "DROP INDEX idx_purchase_store ON Purchase;" \
  "CREATE INDEX idx_purchase_store ON Purchase(store_id);"

# 6) Low Stock Items Report
run_explain_case \
  "Low Stock Items Report" \
  "Items that need reordering" \
  "SELECT s.store_name,
          p.name AS product_name,
          i.quantity_available,
          i.restock_threshold
   FROM Inventory i
   JOIN Store s ON i.store_id = s.store_id
   JOIN Product p ON i.product_id = p.product_id
   WHERE i.quantity_available <= i.restock_threshold
   ORDER BY i.quantity_available ASC;" \
  "DROP INDEX idx_inventory_low_stock ON Inventory;" \
  "CREATE INDEX idx_inventory_low_stock ON Inventory(quantity_available);"

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
