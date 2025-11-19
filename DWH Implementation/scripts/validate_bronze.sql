USE DWH_Supply_Chain

-- ==================================
-- crm_customers
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.crm_customers

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.crm_customers

-- Check for NULLS or duplicates in the primary key
-- Expectation: No result
SELECT 
	[Customer Id],
	COUNT(*)
FROM bronze.crm_customers
GROUP BY [Customer Id]
HAVING COUNT(*) > 1 OR [Customer Id] IS NULL


-- Check for unwanted spaces 
SELECT [Customer Segment]
FROM bronze.crm_customers
WHERE [Customer Segment] != TRIM([Customer Segment])

-- Check for Data standardization and consistency issues
SELECT DISTINCT [Customer Segment]
FROM bronze.crm_customers


-- ==================================
-- store_departments
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_store_departments

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_store_departments

-- Check primary key is unique and not null
SELECT 
	[Department Id],
	COUNT(*)
FROM bronze.erp_store_departments
GROUP BY [Department Id]
HAVING COUNT(*) > 1 OR [Department Id] IS NULL

-- Check for unwanted spaces
SELECT [Department Name]
FROM bronze.erp_store_departments
WHERE [Department Name] != TRIM([Department Name])

-- Check for inconsistency issues
SELECT DISTINCT [Department Name]
FROM bronze.erp_store_departments

-- ==================================
-- store_locations
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_store_locations

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_store_locations

-- Check inconsistency issues
SELECT *
FROM bronze.erp_store_locations 
WHERE [Customer State] NOT IN
(SELECT [State_Abbreviation] FROM [silver].[state_lookup])

-- Check for unwanted spaces
SELECT DISTINCT [Customer City]
FROM bronze.erp_store_locations 
WHERE [Customer City] != TRIM([Customer City])

SELECT DISTINCT [Customer Street]
FROM bronze.erp_store_locations 
WHERE [Customer Street] != TRIM([Customer Street])
-- ==================================
-- erp_order_headers
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_order_headers

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_order_headers

-- Check the primary key is unique and not null
SELECT [Order Id], COUNT(*)
FROM [bronze].[erp_order_headers]
GROUP BY [Order Id]
HAVING COUNT(*) > 1 OR [Order Id] IS NULL

-- Check the Order Customer Id do not have null
SELECT *
FROM [bronze].[erp_order_headers]
WHERE [Order Customer Id] IS NULL

-- Check key integrity ([Order Customer Id], [Order Department Id])
SELECT * 
FROM bronze.erp_order_headers
WHERE [Order Customer Id] NOT IN (SELECT DISTINCT [Customer Id] FROM silver.crm_customers)

-- Check the [Order Date] do not have null
SELECT *
FROM [bronze].[erp_order_headers]
WHERE [Order Date] IS NULL

-- Check for unwanted spaces
SELECT *
FROM [bronze].[erp_order_headers]
WHERE [Customer Street]!= TRIM([Customer Street])

-- Check for inconsistency issues
SELECT DISTINCT [Order Region] 
FROM [bronze].[erp_order_headers]
ORDER BY [Order Region] 

-- Check for incorrect entries (same problem as we found in the store_locations table)
SELECT *
FROM bronze.[erp_order_headers] 
WHERE [Customer State] NOT IN
(SELECT [State_Abbreviation] FROM [silver].[state_lookup])

-- ==================================
-- erp_order_items
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_order_items

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_order_items

-- Check the primary key is unique and not null
SELECT [Order Item Id], COUNT(*)
FROM bronze.erp_order_items
GROUP BY [Order Item Id]
HAVING COUNT(*) > 1 OR [Order Item Id] IS NULL

-- Check the key integrity ([Order Id],[Order Item Cardprod Id])
SELECT *
FROM bronze.erp_order_items
WHERE [Order Id] NOT IN (SELECT DISTINCT [Order Id] FROM [silver].[erp_order_headers])

SELECT *
FROM bronze.erp_order_items
WHERE [Order Item Cardprod Id] NOT IN (SELECT DISTINCT [Product Card Id] FROM [bronze].[erp_products])

SELECT * 
FROM bronze.erp_order_items
WHERE [Order Department Id] NOT IN (SELECT DISTINCT [Department Id] FROM silver.erp_store_departments)

-- Check the [Order Department Id] do not have null
SELECT *
FROM [bronze].erp_order_items
WHERE [Order Department Id] IS NULL

-- Validate business rules
-- [Order Item Quantity] * [Order Item product Price] = [Sales]
-- [Sales] - [Order Item Discount] = [Order Item Total]
-- [Order Item Profit Ratio] = [Order Profit Per Order] / [Order Item Total]
SELECT *
FROM bronze.erp_order_items
WHERE Sales != [Order Item Quantity] * [Order Item product Price]
	OR Sales <= 0 OR Sales IS NULL

SELECT *
FROM bronze.erp_order_items
	-- Is there is a difference more than one cent?
WHERE ABS([Order Item Total] - (Sales - [Order Item Discount])) > 0.01
	OR [Order Item Total] <= 0 OR [Order Item Total] IS NULL

SELECT DISTINCT [Order Status]
FROM [bronze].[erp_order_headers]
WHERE [Order Id] 
	IN (SELECT [Order Id] 
		FROM [bronze].[erp_order_items] 
		WHERE [Order Item Profit Ratio] < 0)

SELECT *
FROM bronze.erp_order_items
WHERE ROUND([Order Item Profit Ratio], 2) != ROUND([Order Profit Per Order] / [Order Item Total], 2)
	OR [Order Item Profit Ratio] IS NULL

SELECT *
FROM bronze.erp_order_items
WHERE [Order Item product Price] IS NULL OR [Order Item product Price] <= 0
OR [Order Item Discount] IS NULL OR [Order Item Discount] < 0
OR [Order Item Total] IS NULL OR [Order Item Total] <= 0

-- ==================================
-- erp_categories
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_categories

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_categories

-- Check the primary key is unique and not null
SELECT [Category Id], COUNT(*)
FROM bronze.erp_categories
GROUP BY [Category Id]
HAVING COUNT(*) > 1 OR [Category Id] IS NULL

-- check for duplicates
SELECT DISTINCT [Category Name]
FROM bronze.erp_categories

SELECT [Category Name], COUNT(*)
FROM bronze.erp_categories
GROUP BY [Category Name]
HAVING COUNT(*) > 1

SELECT *
FROM bronze.erp_categories
WHERE [Category Name] = 'Electronics'

-- Check for unwanted spaces
SELECT [Category Name]
FROM bronze.erp_categories
WHERE [Category Name] != TRIM([Category Name])
-- ==================================
-- erp_products
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_products

-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_products

-- Check the primary key is unique and not null
SELECT [Product Card Id], COUNT(*)
FROM bronze.erp_products
GROUP BY [Product Card Id]
HAVING COUNT(*) > 1 OR [Product Card Id] IS NULL

-- Check for unwanted spaces
SELECT *
FROM bronze.erp_products
WHERE [Product Name] != TRIM([Product Name])

-- Check for inconsistency issues
SELECT DISTINCT [Product Status]
FROM bronze.erp_products

SELECT [Product Price]
FROM bronze.erp_products
WHERE [Product Price] IS NULL OR [Product Price] <= 0

-- Check key integrity
SELECT *
FROM bronze.erp_products
WHERE [Category Id] NOT IN(SELECT [Category Id] FROM bronze.erp_categories)

SELECT *
FROM bronze.erp_products
WHERE [Category Id] IS NULL


-- ==================================
-- erp_shipping
-- ==================================
-- Check the data are loaded into the correct columns
SELECT *
FROM bronze.erp_shipping


-- Check the number of rows matches the number of rows in the source
SELECT COUNT(*)
FROM bronze.erp_shipping

-- Check the primary key is unique and not null
SELECT [Order Id], COUNT(*)
FROM [bronze].erp_shipping
GROUP BY [Order Id]
HAVING COUNT(*) > 1 OR [Order Id] IS NULL

-- Check for inconsistency issues
SELECT DISTINCT [Shipping Mode]
FROM bronze.erp_shipping

SELECT DISTINCT [Delivery Status], Late_delivery_risk
FROM bronze.erp_shipping

-- Check business rule by calculating the difference between order date and shipping date
SELECT SUM(CASE WHEN [Days for shipping (real)] = cal_days THEN 1 ELSE 0 END)
FROM
(
SELECT 
	[Days for shipping (real)], 
	[Days for shipping (scheduled)],
	DATEDIFF(DAY, o.[Order Date], s.[shipping date]) cal_days
FROM bronze.erp_shipping s
INNER JOIN bronze.erp_order_headers o
ON s.[Order Id] = o.[Order Id]
) t
-- Run the load_bronze that is responsible for loading the data into the Bronze tables
EXEC bronze.load_bronze




