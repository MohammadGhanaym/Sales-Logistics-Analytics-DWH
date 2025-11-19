USE DWH_Supply_Chain
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	BEGIN TRY
		DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

		SET @batch_start_time = GETDATE();

		PRINT '==========================================================='
		PRINT 'Loading Silver Layer'
		PRINT '==========================================================='

		PRINT '-----------------------------------------------------------'
		PRINT 'Loading CRM Tables'
		PRINT '-----------------------------------------------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.crm_customers'
		TRUNCATE TABLE silver.crm_customers
		PRINT '>> Inserting Data into: silver.crm_customers'
		INSERT INTO silver.crm_customers
		(
			[Customer Id],
			[Customer Fname],
			[Customer Lname],
			[Customer Segment],
			[Customer Zipcode]
		)
		SELECT 
			[Customer Id],
			ISNULL(UPPER(LEFT([Customer Fname], 1)) + 
			LOWER(SUBSTRING([Customer Fname], 2, LEN([Customer Fname])-1)), 'Unknown') AS Customer_FirstName,
			ISNULL(UPPER(LEFT([Customer Lname], 1)) + 
			LOWER(SUBSTRING([Customer Lname], 2, LEN([Customer Lname])-1)), 'Unknown') AS Customer_LastName,
			CASE WHEN TRIM([Customer Segment]) = 'consumer' THEN 'Consumer'
			WHEN TRIM([Customer Segment]) = 'home office' THEN 'Home Office'
			WHEN [Customer Segment] IS NULL THEN 'Unknown'
			ELSE TRIM([Customer Segment])
			END [Customer Segment],
			ISNULL(RIGHT('00000' + REPLACE(TRIM([Customer Zipcode]), '.0', ''), 5), 'N/A') AS [Customer_Zipcode]
		FROM (
		SELECT *,
			ROW_NUMBER() OVER(PARTITION BY [Customer Id] ORDER BY [Customer Id]) keep_flag
		FROM bronze.crm_customers
		WHERE [Customer Id] IS NOT NULL
		) t
		WHERE keep_flag = 1

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		PRINT '-----------------------------------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '-----------------------------------------------------------'
		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_store_departments'
		TRUNCATE TABLE [silver].[erp_store_departments]

		PRINT '>> Inserting Data into: [silver].erp_store_departments'
		INSERT INTO [silver].[erp_store_departments]
		(
			[Department Id],
			[Department Name]
		)
		SELECT 
			[Department Id],
			ISNULL([Department Name], 'Unknown') [Department Name]
		FROM [bronze].[erp_store_departments]

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_store_locations'
		TRUNCATE TABLE silver.erp_store_locations

		PRINT '>> Inserting Data into: silver.erp_store_locations'
		INSERT INTO silver.erp_store_locations
		(
			[Customer Country],
			[Customer State],
			[Customer City],
			[Customer Street],
			[Latitude],
			[Longitude]
		)
		SELECT 
			CASE 
				WHEN [Customer Country] = 'EE. UU.' THEN 'United States'
				WHEN [Customer Country] IS NULL THEN 'Unknown'
				ELSE [Customer Country] END [Customer Country],
			CASE 
				WHEN [Customer State] IN ('95758', '91732') THEN [Customer City]
				WHEN [Customer State] IS NULL THEN 'Unknown'
				ELSE [Customer State] END [Customer State],
			CASE 
				WHEN [Customer State] IN ('95758', '91732') THEN [Customer Street]
				WHEN [Customer City] IS NULL THEN 'Unknown'
				ELSE [Customer City] END [Customer City],
			CASE 
				WHEN [Customer State] IN ('95758', '91732') OR [Customer Street] IS NULL THEN 'Unknown'
				ELSE [Customer Street] END [Customer Street],
			[Latitude],
			[Longitude]
		FROM bronze.erp_store_locations

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		-- Apply same transformation on Customer State
		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_order_headers'
		TRUNCATE TABLE silver.erp_order_headers

		PRINT '>> Inserting Data into: silver.erp_order_headers'
		INSERT INTO silver.erp_order_headers
		(
			[Order Id],
			[Order Customer Id],
			[Order Date],
			[Order Status],
			Type,
			Market,
			[Order Region],
			[Order Country],
			[Order State],
			[Order City],
			[Order Zip Code],
			[Customer State],
			[Customer City],
			[Customer Street]
		)
		SELECT 
			[Order Id],
			[Order Customer Id],
			[Order Date],
			LOWER(TRIM([Order Status])) AS [Order Status],
			LOWER(TRIM([Type])) AS [Type],
			[Market],
			CASE 
				WHEN [Order Region] IN (
					'Central Africa', 'East Africa', 'North Africa', 
					'Southern Africa', 'West Africa'
				) THEN 'Africa'
        
				WHEN [Order Region] IN (
					'Central Asia', 'Eastern Asia', 'South Asia', 
					'Southeast Asia', 'West Asia'
				) THEN 'Asia'
        
				WHEN [Order Region] IN (
					'Eastern Europe', 'Northern Europe', 'Southern Europe', 'Western Europe'
				) THEN 'Europe'
        
				WHEN [Order Region] IN (
					'Caribbean', 'Central America', 'South America'
				) THEN 'Latin America & Caribbean'
        
				WHEN TRIM([Order Region]) IN (
					'Canada', 'East of USA', 'South of  USA', 'US Center', 'West of USA'
				) THEN 'North America'
        
				WHEN [Order Region] = 'Oceania' THEN 'Oceania'
        
				ELSE 'Unknown' -- Good practice to catch any others
			END AS [Order Region],
			[Order Country],
			[Order State],
			[Order City],
			ISNULL(RIGHT('00000' + REPLACE(TRIM([Order Zip Code]), '.0', ''), 5), 'N/A') AS [Order Zip Code],
			CASE 
				WHEN [Customer State] IN ('95758', '91732') THEN [Customer City]
				WHEN [Customer State] IS NULL THEN 'Unknown'
				ELSE [Customer State] END [Customer State],
			CASE 
				WHEN [Customer State] IN ('95758', '91732') THEN [Customer Street]
				WHEN [Customer City] IS NULL THEN 'Unknown'
				ELSE [Customer City] END [Customer City],
			CASE 
				WHEN [Customer State] IN ('95758', '91732') OR [Customer Street] IS NULL THEN 'Unknown'
				ELSE [Customer Street] END [Customer Street]
		  FROM [bronze].[erp_order_headers]

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'
  
		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_order_items'
		TRUNCATE TABLE silver.erp_order_items

		PRINT '>> Inserting Data into: silver.erp_order_items'
		INSERT INTO silver.erp_order_items
		(
			[Order Item Id],
			[Order Id],
			[Order Item Cardprod Id],
			[Order Department Id],
			[Order Item Quantity],
			[Order Item product Price],
			[Order Item Discount],
			[Order Item Discount Rate],
			[Order Item Total],
			[Order Item Profit Ratio],
			[Sales],
			[Order Profit Per Order]
		)
		SELECT 
			[Order Item Id],
			[Order Id],
			[Order Item Cardprod Id],
			[Order Department Id],
			[Order Item Quantity],
			[Order Item product Price],
			[Order Item Discount],
			[Order Item Discount Rate],
			[Order Item Total],
			[Order Item Profit Ratio],
			CASE 
				WHEN Sales IS NULL THEN [Order Item Quantity] * [Order Item product Price]
				ELSE Sales
			END Sales,
			[Order Profit Per Order]
		  FROM [DWH_Supply_Chain].[bronze].[erp_order_items]

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_categories'
		TRUNCATE TABLE silver.erp_categories

		PRINT '>> Inserting Data into: silver.erp_categories'
		INSERT INTO silver.erp_categories
		(
			[Category Id],
			[Category Name]
		)
		SELECT 
  			[Category Id],
			ISNULL([Category Name], 'Unknown') [Category Name]
		FROM bronze.erp_categories
		WHERE [Category Id] != 37 -- the other key for `Electronics`
		UNION ALL
		SELECT -1, 'Unknown'

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_products'
		TRUNCATE TABLE silver.erp_products

		PRINT '>> Inserting Data into: silver.erp_products'
		INSERT INTO silver.erp_products
		(
			[Product Card Id],
			[Product Name],
			[Product Price],
			[Product Status],
			[Product Description],
			[Product Image],
			[Category Id]
		)
		SELECT 
			[Product Card Id],
			[Product Name],
			[Product Price],
			[Product Status],
			[Product Description],
			[Product Image],
			CASE 
				WHEN [Category Id] IS NULL THEN -1 -- Set to 'Unknown'
				WHEN [Category Id] = 37 THEN 13 -- Keep only 13 for 'Electronics'
				ELSE [Category Id]
			END [Category Id]
		FROM 
			[DWH_Supply_Chain].[bronze].[erp_products];

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.erp_shipping'
		TRUNCATE TABLE silver.erp_shipping

		PRINT '>> Inserting Data into: silver.erp_shipping'
		INSERT INTO silver.erp_shipping
		(
			[Order Id]
			,[shipping date]
			,[Shipping Mode]
			,[Days for shipping (real)]
			,[Days for shipping (scheduled)]
			,[Delivery Status]
			,[Late_delivery_risk]
		)
		SELECT [Order Id]
			  ,[shipping date]
			  ,ISNULL([Shipping Mode], 'Unknown') [Shipping Mode]
			  ,[Days for shipping (real)]
			  ,[Days for shipping (scheduled)]
			  ,ISNULL([Delivery Status], 'Unknown') [Delivery Status]
			  ,[Late_delivery_risk]
		 FROM [DWH_Supply_Chain].[bronze].[erp_shipping]
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @batch_end_time = GETDATE();
		PRINT 'Batch Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + ' seconds';
		PRINT '>> ------------'

	 END TRY
	 BEGIN CATCH
		PRINT '===========================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '==========================================================='
	 END CATCH
END