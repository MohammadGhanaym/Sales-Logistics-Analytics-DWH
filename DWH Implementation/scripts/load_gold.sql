USE DWH_Supply_Chain
GO

CREATE OR ALTER PROCEDURE gold.load_gold
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    SET @batch_start_time = GETDATE();

    PRINT '===========================================================';
    PRINT 'Loading Gold Layer (Physical Tables)';
    PRINT '===========================================================';

    BEGIN TRY
        
        -- -----------------------------------------------------
        -- Step 1: Load Dimension Tables
        -- -----------------------------------------------------
        PRINT '-----------------------------------------------------------';
        PRINT 'Loading Dimension Tables...';
        PRINT '-----------------------------------------------------------';

        -- Truncate all tables
        TRUNCATE TABLE gold.fact_sales;
        TRUNCATE TABLE gold.fact_shipping;
        PRINT '>> Fact tables truncated.';
        DELETE FROM gold.dim_customers;
        DELETE FROM gold.dim_products;
        DELETE FROM gold.dim_store_departments;
        DELETE FROM gold.dim_store_locations;
        DELETE FROM gold.dim_order_geography;
        DELETE FROM gold.dim_transactions_info;
        DELETE FROM gold.dim_date;
        PRINT '>> All dimension tables truncated.';

        -- === Load dim_date ===
        -- (This table is loaded first as it's non-IDENTITY)
        SET @start_time = GETDATE();
        PRINT '>> Populating gold.dim_date...';
        INSERT INTO gold.dim_date (
            date_key, 
            full_date, 
            date_number_of_week, 
            day_name_of_week, 
            day_number_of_month, 
            month_name, 
            month_number_of_year, 
            [quarter], 
            [year]
        )
        VALUES (-1, '1900-01-01', 0, 'Unknown', 0, 'Unknown', 0, 0, 0);
        DECLARE @MinDate DATE, @MaxDate DATE;
        SELECT @MinDate = MIN(DateValue), @MaxDate = MAX(DateValue) FROM (
            SELECT CONVERT(DATE, [Order Date]) AS DateValue FROM [DWH_Supply_Chain].bronze.erp_order_headers WHERE [Order Date] IS NOT NULL
            UNION ALL
            SELECT CONVERT(DATE, [shipping date]) AS DateValue FROM [DWH_Supply_Chain].bronze.erp_shipping WHERE [shipping date] IS NOT NULL
        ) AS AllDates;
        DECLARE @CurrentDate DATE = @MinDate;
        WHILE @CurrentDate <= @MaxDate
        BEGIN
            INSERT INTO gold.[dim_date] (
                date_key, 
                full_date, 
                date_number_of_week, 
                day_name_of_week, 
                day_number_of_month, 
                month_name, 
                month_number_of_year, 
                [quarter], 
                [year]
            ) VALUES (
                CONVERT(INT, CONVERT(VARCHAR(8), @CurrentDate, 112)), @CurrentDate, DATEPART(weekday, @CurrentDate), DATENAME(weekday, @CurrentDate),
                DATEPART(day, @CurrentDate), DATENAME(month, @CurrentDate), DATEPART(month, @CurrentDate), DATEPART(quarter, @CurrentDate), DATEPART(year, @CurrentDate)
            );
            SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
        END;
        SET @end_time = GETDATE();
        PRINT '>> gold.dim_date loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';

        -- === Load dim_customers ===
        SET @start_time = GETDATE();
        SET IDENTITY_INSERT gold.dim_customers ON;
        INSERT INTO gold.dim_customers
        (
            customers_key, 
            customer_id, 
            customer_first_name,
            customer_last_name, 
            customer_segment, 
            customer_zipcode
        )
        VALUES (-1, -1, 'Unknown', 'Unknown', 'Unknown', 'N/A');
        SET IDENTITY_INSERT gold.dim_customers OFF;
        -- Let IDENTITY auto-generate keys
        INSERT INTO gold.dim_customers 
        (
            customer_id, 
            customer_first_name, 
            customer_last_name, 
            customer_segment, 
            customer_zipcode
        )
        SELECT 
            [Customer Id], [Customer Fname], [Customer Lname], [Customer Segment], [Customer Zipcode]
        FROM [silver].[crm_customers];
        SET @end_time = GETDATE();
        PRINT '>> gold.dim_customers loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';

        -- === Load dim_products ===
        SET @start_time = GETDATE();
        SET IDENTITY_INSERT gold.dim_products ON;
        INSERT INTO gold.dim_products 
        (
            products_key, 
            product_id, 
            product_name, 
            product_price, 
            product_status, 
            category_id, 
            category_name
        )
        VALUES (-1, -1, 'Unknown', 0, -1, -1, 'Unknown');
        SET IDENTITY_INSERT gold.dim_products OFF;
        -- Let IDENTITY auto-generate keys
        INSERT INTO gold.dim_products 
        (
            product_id, 
            product_name, 
            product_price, 
            product_status, 
            category_id, 
            category_name
        )
        SELECT 
            [Product Card Id], [Product Name], [Product Price], [Product Status], c.[Category Id], c.[Category Name]
        FROM [silver].[erp_products] p
        LEFT JOIN [silver].[erp_categories] c ON p.[Category Id] = c.[Category Id];
        SET @end_time = GETDATE();
        PRINT '>> gold.dim_products loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';

        -- === Load dim_store_departments ===
        SET @start_time = GETDATE();
        SET IDENTITY_INSERT gold.dim_store_departments ON;
        INSERT INTO gold.dim_store_departments 
        (
            store_departments_key, 
            [Department Id], 
            [Department Name]
        )
        VALUES (-1, -1, 'Unknown');
        SET IDENTITY_INSERT gold.dim_store_departments OFF;
        -- Let IDENTITY auto-generate keys
        INSERT INTO gold.dim_store_departments 
        (
            [Department Id], 
            [Department Name]
        )
        SELECT [Department Id], [Department Name] FROM silver.erp_store_departments;
        SET @end_time = GETDATE();
        PRINT '>> gold.dim_store_departments loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';

        -- === Load dim_store_locations ===
        SET @start_time = GETDATE();
        SET IDENTITY_INSERT gold.dim_store_locations ON;
        INSERT INTO gold.dim_store_locations 
        (
            store_locations_key, 
            store_country, 
            store_state, 
            store_state_name,
            store_city, 
            store_street,
            city_latitude,
            city_longitude
        )
        VALUES (-1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', -1, -1);
        SET IDENTITY_INSERT gold.dim_store_locations OFF;
        -- Let IDENTITY auto-generate keys
        INSERT INTO gold.dim_store_locations 
        (
            store_country, 
            store_state, 
            store_state_name,
            store_city, 
            store_street,
            [city_latitude],
            city_longitude
        )
        SELECT
            [Customer Country], 
            [Customer State], 
            s.[State_Name],
            [Customer City], 
            [Customer Street], 
            [Latitude], 
            [Longitude]
        FROM [silver].[erp_store_locations] l
        LEFT JOIN [silver].[state_lookup] s
        ON l.[Customer State] = s.[State_Abbreviation]

        SET @end_time = GETDATE();
        PRINT '>> gold.dim_store_locations loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';

        -- === Load dim_order_geography ===
        SET @start_time = GETDATE();
        SET IDENTITY_INSERT gold.dim_order_geography ON;
        INSERT INTO gold.dim_order_geography 
        (
            order_geography_key, 
            order_market, 
            order_region, 
            order_country, 
            order_state, 
            order_city, 
            order_zipcode
        )
        VALUES (-1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'N/A');
        SET IDENTITY_INSERT gold.dim_order_geography OFF;
        -- Let IDENTITY auto-generate keys
        INSERT INTO gold.dim_order_geography 
        (
            order_market, 
            order_region, 
            order_country, 
            order_state, 
            order_city, 
            order_zipcode
        )
        SELECT DISTINCT
            [Market], [Order Region], [Order Country], [Order State], [Order City], [Order Zip Code]
        FROM [silver].[erp_order_headers];
        SET @end_time = GETDATE();
        PRINT '>> gold.dim_order_geography loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';

        -- === Load dim_transactions_info ===
        SET @start_time = GETDATE();
        SET IDENTITY_INSERT gold.dim_transactions_info ON;
        INSERT INTO gold.dim_transactions_info 
        (
            transactions_info_key, 
            order_status, 
            payment_type, 
            shipping_mode, 
            delivery_status
        )
        VALUES (-1, 'Unknown', 'Unknown', 'Unknown', 'Unknown');
        SET IDENTITY_INSERT gold.dim_transactions_info OFF;
        -- Let IDENTITY auto-generate keys
        INSERT INTO gold.dim_transactions_info 
        (
            order_status, 
            payment_type, 
            shipping_mode, 
            delivery_status
        )
        SELECT DISTINCT
            [Order Status], [Type], [Shipping Mode], [Delivery Status]
        FROM [silver].[erp_order_headers] o
        LEFT JOIN [silver].[erp_shipping] s ON o.[Order Id] = s.[Order Id];
        SET @end_time = GETDATE();
        PRINT '>> gold.dim_transactions_info loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';


        -- -----------------------------------------------------
        -- Step 2: Load Fact Tables
        -- -----------------------------------------------------
        PRINT '-----------------------------------------------------------';
        PRINT 'Loading Fact Tables...';
        PRINT '-----------------------------------------------------------';

        -- Load fact_sales
        SET @start_time = GETDATE();
        INSERT INTO gold.fact_sales (
            [Order Item Id], [Order Id], products_key, store_locations_key, 
            order_geography_key, store_departments_key, transactions_info_key, 
            customers_key, order_date_key, order_time_key, item_quantity, 
            item_price, item_discount, item_total, sales, item_cost, item_profit
        )
        SELECT 
            oi.[Order Item Id],
            oi.[Order Id],
            ISNULL(p.products_key, -1) AS products_key,
            ISNULL(sl.store_locations_key, -1) AS store_locations_key,
            ISNULL(og.order_geography_key, -1) AS order_geography_key,
            ISNULL(sd.store_departments_key, -1) AS store_departments_key,
            ISNULL(ti.transactions_info_key, -1) AS transactions_info_key,
            ISNULL(c.customers_key, -1) AS customers_key,
            ISNULL(CONVERT(INT, CONVERT(VARCHAR(8), oh.[Order Date], 112)), -1) AS order_date_key,
            ISNULL(CAST(FORMAT(DATEADD(MINUTE, DATEDIFF(MINUTE, 0, oh.[Order Date]), 0), 'HHmmss') AS INT), -1) AS order_time_key,
            oi.[Order Item Quantity] AS item_quantity,
            oi.[Order Item product Price] AS item_price,
            oi.[Order Item Discount] AS item_discount,
            oi.[Order Item Total] AS item_total,
            oi.Sales AS sales,
            oi.Sales - oi.[Order Profit Per Order] AS item_cost,
            oi.[Order Profit Per Order] AS item_profit
        FROM [silver].[erp_order_items] oi
        LEFT JOIN [silver].[erp_order_headers] oh ON oi.[Order Id] = oh.[Order Id]
        LEFT JOIN [silver].[erp_shipping] s ON oh.[Order Id] = s.[Order Id]
        LEFT JOIN gold.dim_products p ON oi.[Order Item Cardprod Id] = p.product_id
        LEFT JOIN gold.dim_store_locations sl
            ON sl.store_state = oh.[Customer State]
            AND sl.store_city = oh.[Customer City]
            AND sl.store_street = oh.[Customer Street]
        LEFT JOIN gold.dim_order_geography og
            ON og.order_market = oh.Market
            AND og.order_region = oh.[Order Region]
            AND og.order_country = oh.[Order Country]
            AND og.order_state = oh.[Order State]
            AND og.order_city = oh.[Order City]
            AND og.order_zipcode = oh.[Order Zip Code]
        LEFT JOIN gold.dim_store_departments sd ON sd.[Department Id] = oi.[Order Department Id]
        LEFT JOIN gold.dim_transactions_info ti
            ON ti.order_status = oh.[Order Status]
            AND ti.payment_type = oh.Type
            AND ti.shipping_mode = s.[Shipping Mode]
            AND ti.delivery_status = s.[Delivery Status]
        LEFT JOIN gold.dim_customers c ON oh.[Order Customer Id] = c.customer_id;
        
        SET @end_time = GETDATE();
        PRINT '>> gold.fact_sales loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';

        -- Load fact_shipping
        SET @start_time = GETDATE();
        INSERT INTO gold.fact_shipping (
            [Order Id], customers_key, store_locations_key, order_geography_key, 
            transactions_info_key, order_date_key, order_time_key, shipping_date_key, 
            shipping_days_real, shipping_days_scheduled, late_delivery
        )
        SELECT 
            oh.[Order Id],
            ISNULL(c.customers_key, -1) AS customers_key,
            ISNULL(sl.store_locations_key, -1) AS store_locations_key,
            ISNULL(og.order_geography_key, -1) AS order_geography_key,
            ISNULL(ti.transactions_info_key, -1) AS transactions_info_key,
            ISNULL(CONVERT(INT, CONVERT(VARCHAR(8), oh.[Order Date], 112)), -1) AS order_date_key,
            ISNULL(CAST(FORMAT(DATEADD(MINUTE, DATEDIFF(MINUTE, 0, oh.[Order Date]), 0), 'HHmmss') AS INT), -1) AS order_time_key,
            ISNULL(CONVERT(INT, CONVERT(VARCHAR(8), s.[shipping date], 112)), -1) AS shipping_date_key,
            s.[Days for shipping (real)] AS shipping_days_real,
            s.[Days for shipping (scheduled)] AS shipping_days_scheduled,
            s.Late_delivery_risk AS late_delivery
        FROM [silver].[erp_order_headers] oh
        LEFT JOIN [silver].[erp_shipping] s ON oh.[Order Id] = s.[Order Id]
        LEFT JOIN gold.dim_customers c ON oh.[Order Customer Id] = c.customer_id
        LEFT JOIN gold.dim_store_locations sl
            ON sl.store_state = oh.[Customer State]
            AND sl.store_city = oh.[Customer City]
            AND sl.store_street = oh.[Customer Street]
        LEFT JOIN gold.dim_order_geography og
            ON og.order_market = oh.Market
            AND og.order_region = oh.[Order Region]
            AND og.order_country = oh.[Order Country]
            AND og.order_state = oh.[Order State]
            AND og.order_city = oh.[Order City]
            AND og.order_zipcode = oh.[Order Zip Code]
        LEFT JOIN gold.dim_transactions_info ti
            ON ti.order_status = oh.[Order Status]
            AND ti.payment_type = oh.Type
            AND ti.shipping_mode = s.[Shipping Mode]
            AND ti.delivery_status = s.[Delivery Status];
        
        SET @end_time = GETDATE();
        PRINT '>> gold.fact_shipping loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + 's';

        SET @batch_end_time = GETDATE();
        PRINT '===========================================================';
        PRINT 'Gold Layer Load Complete';
        PRINT 'Total Batch Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + 's';
        PRINT '===========================================================';

    END TRY
    BEGIN CATCH
        PRINT '===========================================================';
        PRINT 'ERROR OCCURED DURING LOADING GOLD LAYER';
        PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '===========================================================';
    END CATCH
END;
GO