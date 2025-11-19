CREATE OR ALTER VIEW gold.dim_customers AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY [Customer Id]) customers_key,
    [Customer Id] customer_id,
    [Customer Fname] customer_first_name,
    [Customer Lname] customer_last_name,
    [Customer Segment] customer_segment,
    [Customer Zipcode] customer_zipcode
  FROM [DWH_Supply_Chain].[silver].[crm_customers]

GO

CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY [Product Card Id]) products_key,
    [Product Card Id] product_id,
    [Product Name] product_name,
    [Product Price] product_price,
    [Product Status] product_status,
    c.[Category Id] category_id,
    c.[Category Name] category_name
FROM [silver].[erp_products] p
LEFT JOIN [silver].[erp_categories] c
ON p.[Category Id] = c.[Category Id]

GO

CREATE OR ALTER VIEW gold.dim_store_departments AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY [Department Id]) store_departments_key,
    [Department Id],
    [Department Name]
FROM silver.erp_store_departments

GO

CREATE OR ALTER VIEW gold.dim_store_locations AS

WITH DistinctLocations AS (
    SELECT DISTINCT
        [Customer Country] AS store_country,
        [Customer State] AS store_state,
        [Customer City] AS store_city,
        [Customer Street] AS store_street
    FROM 
        [silver].[erp_store_locations]
)
SELECT 
    ROW_NUMBER() OVER(
        ORDER BY
            store_country,
            store_state,
            store_city,
            store_street
    ) AS store_locations_key,
    store_country,
    store_state,
    store_city,
    store_street
FROM 
    DistinctLocations;
GO

GO

CREATE OR ALTER VIEW gold.[dim_order_geography] AS

WITH DistinctGeography AS (
    SELECT DISTINCT
        [Market] AS order_market,
        [Order Region] AS order_region,
        [Order Country] AS order_country,
        [Order State] AS order_state,
        [Order City] AS order_city,
        [Order Zip Code] AS order_zipcode
    FROM 
        [silver].[erp_order_headers]
)
SELECT 
    ROW_NUMBER() OVER(
        ORDER BY 
            order_market, 
            order_region, 
            order_country, 
            order_state, 
            order_city, 
            order_zipcode
    ) AS order_geography_key,
    *
FROM 
    DistinctGeography;

GO

CREATE OR ALTER VIEW gold.dim_transactions_info AS

WITH DistinctTransInfo AS (
    SELECT DISTINCT
        [Order Status] order_status,
        [Type] payment_type,
        [Shipping Mode] shipping_mode,
        [Delivery Status] delivery_status
    FROM 
        [silver].[erp_order_headers] o
    LEFT JOIN [silver].[erp_shipping] s
    ON o.[Order Id] = s.[Order Id]
)
SELECT 
    ROW_NUMBER() OVER(
        ORDER BY 
            order_status, 
            payment_type, 
            shipping_mode, 
            delivery_status
    ) AS transactions_info_key,
    *
FROM 
    DistinctTransInfo;

GO
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT 
    oi.[Order Item Id],
    oi.[Order Id],
    p.products_key,
    sl.store_locations_key,
    og.order_geography_key,
    sd.store_departments_key,
    ti.transactions_info_key,
    c.customers_key,
    CONVERT(INT, CONVERT(VARCHAR(8), oh.[Order Date], 112)) order_date_key,
    CAST(FORMAT(DATEADD(MINUTE, DATEDIFF(MINUTE, 0, oh.[Order Date]), 0), 'HHmmss') AS INT) AS order_time_key,
    oi.[Order Item Quantity] item_quantity,
    oi.[Order Item product Price] item_price,
    oi.[Order Item Discount] item_discount,
    oi.[Order Item Total] item_total,
    oi.Sales sales,
    oi.Sales - oi.[Order Profit Per Order] item_cost,
    oi.[Order Profit Per Order] item_profit
FROM [silver].[erp_order_items] oi
LEFT JOIN [silver].[erp_order_headers] oh
ON oi.[Order Id] = oh.[Order Id]
LEFT JOIN [silver].[erp_shipping] s
ON oh.[Order Id] = s.[Order Id]
LEFT JOIN gold.dim_products p
ON oi.[Order Item Cardprod Id] = p.product_id
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
LEFT JOIN gold.dim_store_departments sd
ON sd.[Department Id] = oi.[Order Department Id]
LEFT JOIN gold.dim_transactions_info ti
ON ti.order_status = oh.[Order Status]
   AND ti.payment_type = oh.Type
   AND ti.shipping_mode = s.[Shipping Mode]
   AND ti.delivery_status = s.[Delivery Status]
LEFT JOIN gold.dim_customers c
ON oh.[Order Customer Id] = c.customer_id


GO

CREATE OR ALTER VIEW gold.fact_shipping AS
SELECT 
    oh.[Order Id],
    c.customers_key,
    sl.store_locations_key,
    og.order_geography_key,
    ti.transactions_info_key,
    CONVERT(INT, CONVERT(VARCHAR(8), oh.[Order Date], 112)) order_date_key,
    CAST(FORMAT(DATEADD(MINUTE, DATEDIFF(MINUTE, 0, oh.[Order Date]), 0), 'HHmmss') AS INT) AS order_time_key,
    CONVERT(INT, CONVERT(VARCHAR(8), s.[shipping date], 112)) shipping_date_key,
    s.[Days for shipping (real)] shipping_days_real,
    s.[Days for shipping (scheduled)] shipping_days_scheduled,
    s.Late_delivery_risk late_delivery
FROM [silver].[erp_order_headers] oh
LEFT JOIN [silver].[erp_shipping] s
ON oh.[Order Id] = s.[Order Id]
LEFT JOIN gold.dim_customers c
ON oh.[Order Customer Id] = c.customer_id
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
   AND ti.delivery_status = s.[Delivery Status]



-- DROP VIEW IF EXISTS gold.fact_sales;
-- DROP VIEW IF EXISTS gold.fact_shipping;
-- DROP VIEW IF EXISTS gold.dim_customers;
-- DROP VIEW IF EXISTS gold.dim_products;
-- DROP VIEW IF EXISTS gold.dim_store_departments;
-- DROP VIEW IF EXISTS gold.dim_store_locations;
-- DROP VIEW IF EXISTS gold.dim_order_geography;
-- DROP VIEW IF EXISTS gold.dim_transactions_info;