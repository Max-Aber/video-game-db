#!/bin/bash

# ==============================================================================
# MySQL Database Loader
# Usage: ./load.sh
# ==============================================================================

DB_USER="root"
DB_NAME="video_game_store"
SQL_DIR="../sql"

# 1. Capture Password Once (Hidden Input)
echo "-------------------------------------------------"
echo "  MySQL Database Loader"
echo "-------------------------------------------------"
read -s -p "Enter MySQL Password for user '$DB_USER': " DB_PASS
echo "" 
export MYSQL_PWD=$DB_PASS  # Temporarily export for this session only

# Function to run a specific SQL file
run_sql() {
    local file=$1
    echo "Processing $file..."
    
    # We add -v (verbose) to see output, and --force to not stop on warnings
    mysql -u "$DB_USER" --database="$DB_NAME" < "$SQL_DIR/$file"
    
    if [ $? -ne 0 ]; then
        echo "❌ Error processing $file. Stopping."
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
mysql -u "$DB_USER" < "$SQL_DIR/01_schema.sql"
if [ $? -ne 0 ]; then
    echo "❌ Schema build failed. Check your SQL syntax or connection."
    unset MYSQL_PWD
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
mysql -u "$DB_USER" --database="$DB_NAME" --force < "$SQL_DIR/08_transactions.sql"

echo "================================================="
echo "🎉 BUILD COMPLETE. Database is ready."
echo "   (Note: 07_queries.sql was skipped as it is for reporting only)"
echo "================================================="

# Security: Clear password from environment
unset MYSQL_PWD