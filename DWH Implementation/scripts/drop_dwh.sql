-- ======================================================
-- Step 1: Drop Fact Tables
-- (Must be dropped first to remove foreign key dependencies)
-- ======================================================
DROP TABLE IF EXISTS gold.fact_sales;
DROP TABLE IF EXISTS gold.fact_shipping;

-- ======================================================
-- Step 2: Drop Dimension Tables
-- (Can now be dropped safely)
-- ======================================================
DROP TABLE IF EXISTS gold.dim_customers;
DROP TABLE IF EXISTS gold.dim_products;
DROP TABLE IF EXISTS gold.dim_store_departments;
DROP TABLE IF EXISTS gold.dim_store_locations;
DROP TABLE IF EXISTS gold.dim_order_geography;
DROP TABLE IF EXISTS gold.dim_transactions_info;
DROP TABLE IF EXISTS gold.dim_date;
-- DROP TABLE IF EXISTS gold.dim_time;