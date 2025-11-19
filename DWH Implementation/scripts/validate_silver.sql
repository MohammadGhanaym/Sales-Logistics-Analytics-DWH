USE DWH_Supply_Chain

-- ==================================
-- crm_customers
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM silver.crm_customers

-- Check for NULLS or duplicates in the primary key
-- Expectation: No result
SELECT 
	[Customer Id],
	COUNT(*)
FROM silver.crm_customers
GROUP BY [Customer Id]
HAVING COUNT(*) > 1 OR [Customer Id] IS NULL


-- Check for unwanted spaces 
SELECT [Customer Segment]
FROM silver.crm_customers
WHERE [Customer Segment] != TRIM([Customer Segment])

-- Check for Data standardization and consistency issues
SELECT DISTINCT [Customer Segment]
FROM silver.crm_customers


-- ==================================
-- store_departments
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM silver.erp_store_departments


-- ==================================
-- store_locations
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM silver.erp_store_locations

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM silver.erp_store_locations

-- Check inconsistency issues
SELECT *
FROM silver.erp_store_locations 
WHERE [Customer State] NOT IN
(SELECT [State_Abbreviation] FROM [silver].[state_lookup])
 

SELECT DISTINCT [Customer Country]
FROM silver.erp_store_locations 

-- ==================================
-- erp_order_headers
-- ==================================
SELECT *
FROM silver.erp_order_headers


SELECT *
FROM silver.[erp_order_headers] 
WHERE [Customer State] NOT IN
(SELECT [State_Abbreviation] FROM [silver].[state_lookup])

SELECT DISTINCT [Order Region]
FROM silver.erp_order_headers


-- ==================================
-- erp_order_items
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM silver.erp_order_items


SELECT *
FROM silver.erp_order_items
WHERE Sales != [Order Item Quantity] * [Order Item product Price]
	OR Sales <= 0 OR Sales IS NULL

-- ==================================
-- erp_categories
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM silver.erp_categories

SELECT [Category Name], COUNT(*)
FROM silver.erp_categories
GROUP BY [Category Name]
HAVING COUNT(*) > 1


-- ==================================
-- erp_products
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM silver.erp_products

SELECT *
FROM silver.erp_products
WHERE [Category Id] = -1

-- ==================================
-- erp_shipping
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM silver.erp_shipping


-- run load_silver
EXEC silver.load_silver