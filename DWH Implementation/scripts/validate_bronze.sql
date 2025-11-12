
-- ==================================
-- crm_customers
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.crm_customers

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.crm_customers


-- ==================================
-- store_departments
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.store_departments

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.store_departments

-- ==================================
-- store_locations
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.store_locations

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.store_locations

-- ==================================
-- erp_order_headers
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_order_headers

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_order_headers

-- ==================================
-- erp_order_items
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_order_items

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_order_items

-- ==================================
-- erp_products
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_products

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_products

-- ==================================
-- erp_categories
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_categories

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_categories

-- ==================================
-- erp_shipping
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_shipping

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_shipping


-- Run the load_bronze that is responsible for loading the data into the Bronze tables
bronze.load_bronze