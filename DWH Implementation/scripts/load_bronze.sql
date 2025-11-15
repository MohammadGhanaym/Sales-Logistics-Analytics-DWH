USE DWH_Supply_Chain
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	BEGIN TRY
		DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

		SET @batch_start_time = GETDATE();

		PRINT '==========================================================='
		PRINT 'Loading Bronze Layer'
		PRINT '==========================================================='

		PRINT '-----------------------------------------------------------'
		PRINT 'Loading CRM Tables'
		PRINT '-----------------------------------------------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.crm_customers'
		TRUNCATE TABLE bronze.crm_customers

		PRINT '>> Inserting Data into: bronze.crm_customers'
		BULK INSERT bronze.crm_customers
		FROM 'F:\Workspace\Data-Analysis-Projects-2025\Sales-Logistics-Analytics-DWH\datasets\CRM\customers.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		PRINT '-----------------------------------------------------------'
		PRINT 'Loading Store Tables'
		PRINT '-----------------------------------------------------------'
		
		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_store_departments'
		TRUNCATE TABLE bronze.erp_store_departments

		PRINT '>> Inserting Data into: bronze.erp_store_departments'
		BULK INSERT bronze.erp_store_departments
		FROM 'F:\Workspace\Data-Analysis-Projects-2025\Sales-Logistics-Analytics-DWH\datasets\ERP\departments.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_store_locations'
		TRUNCATE TABLE bronze.erp_store_locations

		PRINT '>> Inserting Data into: bronze.erp_store_locations'
		BULK INSERT bronze.erp_store_locations
		FROM 'F:\Workspace\Data-Analysis-Projects-2025\Sales-Logistics-Analytics-DWH\datasets\ERP\locations.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		PRINT '-----------------------------------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '-----------------------------------------------------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_order_headers'
		TRUNCATE TABLE bronze.erp_order_headers

		PRINT '>> Inserting Data into: bronze.erp_order_headers'
		BULK INSERT bronze.erp_order_headers
		FROM 'F:\Workspace\Data-Analysis-Projects-2025\Sales-Logistics-Analytics-DWH\datasets\ERP\order_headers.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_order_items'
		TRUNCATE TABLE bronze.erp_order_items

		PRINT '>> Inserting Data into: bronze.erp_order_items'
		BULK INSERT bronze.erp_order_items
		FROM 'F:\Workspace\Data-Analysis-Projects-2025\Sales-Logistics-Analytics-DWH\datasets\ERP\order_items.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_products_staging'
		TRUNCATE TABLE bronze.erp_products_staging;

		PRINT '>> Inserting Data into Staging: bronze.erp_products_staging'
		BULK INSERT bronze.erp_products_staging
		FROM 'F:\Workspace\Data-Analysis-Projects-2025\Sales-Logistics-Analytics-DWH\datasets\ERP\products.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001',
			TABLOCK
			-- No KEEPNULLS or ALTER needed here
		);

		PRINT '>> Truncating Table: bronze.erp_products'
		TRUNCATE TABLE bronze.erp_products;

		PRINT '>> Cleaning and Inserting Data into: bronze.erp_products'
		INSERT INTO bronze.erp_products
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
			TRY_CAST([Product Card Id] AS INT),
			[Product Name],
			TRY_CAST([Product Price] AS DECIMAL(18, 4)),
			TRY_CAST([Product Status] AS BIT),
			[Product Description],
			[Product Image],
			-- This safely converts "73.0" to 73 and "" to NULL
			TRY_CAST(TRY_CAST([Category Id] AS FLOAT) AS INT) 
		FROM
			bronze.erp_products_staging;

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';
		PRINT '>> --------------'

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_categories'
		TRUNCATE TABLE bronze.erp_categories

		PRINT '>> Inserting Data into: bronze.erp_categories'
		BULK INSERT bronze.erp_categories
		FROM 'F:\Workspace\Data-Analysis-Projects-2025\Sales-Logistics-Analytics-DWH\datasets\ERP\categories.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds';

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: bronze.erp_shipping'
		TRUNCATE TABLE bronze.erp_shipping

		PRINT '>> Inserting Data into: bronze.erp_shipping'
		BULK INSERT bronze.erp_shipping
		FROM 'F:\Workspace\Data-Analysis-Projects-2025\Sales-Logistics-Analytics-DWH\datasets\ERP\shipping.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			CODEPAGE = '65001',
			TABLOCK
		);

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