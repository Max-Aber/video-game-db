#!/bin/bash

# ==============================================================================
# MySQL Database Loader
# Usage: ./load.sh [--docker | --local] [port]
# 
# Options:
#   --docker    Run MySQL commands inside Docker container (default)
#   --local     Run MySQL commands using local MySQL client
#   [port]      Port number for local MySQL (default: 3306, ignored in docker mode)
#
# Examples:
#   ./load.sh                 # Docker mode (recommended)
#   ./load.sh --docker        # Docker mode (explicit)
#   ./load.sh --local         # Local MySQL on port 3306
#   ./load.sh --local 3307    # Local MySQL on port 3307
# ==============================================================================

# Default settings
CONTAINER_NAME="video_game_store_db"
DB_USER="root"
DB_NAME="video_game_store"
SQL_DIR="../sql"
USE_DOCKER=true
DB_PORT="3306"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --docker)
            USE_DOCKER=true
            shift
            ;;
        --local)
            USE_DOCKER=false
            shift
            ;;
        *)
            DB_PORT="$1"
            shift
            ;;
    esac
done

# 1. Capture Password Once (Hidden Input)
echo "-------------------------------------------------"
if [ "$USE_DOCKER" = true ]; then
    echo "  MySQL Database Loader (Docker Mode)"
else
    echo "  MySQL Database Loader (Local Mode - Port $DB_PORT)"
fi
echo "-------------------------------------------------"

# Check Docker container is running (if using Docker mode)
if [ "$USE_DOCKER" = true ]; then
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "❌ Docker container '$CONTAINER_NAME' is not running."
        echo "   Start it with: docker-compose up -d"
        exit 1
    fi
fi

read -s -p "Enter MySQL Password for user '$DB_USER': " DB_PASS
echo ""

# Function to execute MySQL command based on mode
exec_mysql() {
    local db_arg="$1"  # Optional: database name
    
    if [ "$USE_DOCKER" = true ]; then
        if [ -n "$db_arg" ]; then
            docker exec -i -e MYSQL_PWD="$DB_PASS" "$CONTAINER_NAME" mysql -u "$DB_USER" "$db_arg"
        else
            docker exec -i -e MYSQL_PWD="$DB_PASS" "$CONTAINER_NAME" mysql -u "$DB_USER"
        fi
    else
        export MYSQL_PWD="$DB_PASS"
        if [ -n "$db_arg" ]; then
            mysql -u "$DB_USER" --port="$DB_PORT" --database="$db_arg"
        else
            mysql -u "$DB_USER" --port="$DB_PORT"
        fi
    fi
}

# Function to execute MySQL with --force flag
exec_mysql_force() {
    local db_arg="$1"
    
    if [ "$USE_DOCKER" = true ]; then
        docker exec -i -e MYSQL_PWD="$DB_PASS" "$CONTAINER_NAME" mysql -u "$DB_USER" "$db_arg" --force
    else
        export MYSQL_PWD="$DB_PASS"
        mysql -u "$DB_USER" --port="$DB_PORT" --database="$db_arg" --force
    fi
}

# Function to run a specific SQL file
run_sql() {
    local file=$1
    echo "Processing $file..."
    
    exec_mysql "$DB_NAME" < "$SQL_DIR/$file"
    
    if [ $? -ne 0 ]; then
        echo "❌ Error processing $file. Stopping."
        [ "$USE_DOCKER" = false ] && unset MYSQL_PWD
        exit 1
    fi
}

# ==============================================================================
# EXECUTION ORDER
# ==============================================================================
# Step 1: Schema (DDL)
# We run this WITHOUT selecting a DB first, because 01_schema.sql usually 
# contains the "CREATE DATABASE" and "USE" commands.
echo "-------------------------------------------------"
echo "  Step 1: Rebuilding Schema (DDL)"
echo "-------------------------------------------------"
exec_mysql < "$SQL_DIR/01_schema.sql" 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Schema build failed. Check your SQL syntax or connection."
    [ "$USE_DOCKER" = false ] && unset MYSQL_PWD
    exit 1
fi
echo "✅ Schema created."

# Step 2: Seed Data
run_sql "02_seed.sql" "Step 2: Seeding Data"

# Step 3: Views
run_sql "03_views.sql" "Step 3: Creating Views"

# Step 4: Functions & Procedures
# IMPORTANT: Ensure 04_functions.sql uses DELIMITER // syntax!
run_sql "04_functions.sql" "Step 4: Loading Business Logic"

# Step 5: Triggers
# IMPORTANT: Ensure 05_triggers.sql uses DELIMITER // syntax!
run_sql "05_triggers.sql" "Step 5: Applying Triggers"

# Step 6: Indexes
run_sql "06_indexes.sql" "Step 6: Optimizing Performance"

# ==============================================================================
# VERIFICATION
# ==============================================================================

# Step 7: Run Transaction Tests (ACID checks)
echo "-------------------------------------------------"
echo "  Step 7: Running Transaction Test Suite"
echo "  (Note: You WILL see expected error messages below. This is normal!)"
echo "-------------------------------------------------"

# We run this manually (instead of using run_sql) so we can add the --force flag.
# --force tells MySQL to keep running even if a test case triggers an error.
exec_mysql_force "$DB_NAME" < "$SQL_DIR/08_transactions.sql"

echo "================================================="
echo "🎉 BUILD COMPLETE. Database is ready."
echo "   (Note: 07_queries.sql was skipped as it is for reporting only)"
echo "================================================="

# Security: Clear password from environment (local mode only)
[ "$USE_DOCKER" = false ] && unset MYSQL_PWD