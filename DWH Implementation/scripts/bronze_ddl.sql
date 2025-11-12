USE DWH_Supply_Chain

IF OBJECT_ID('bronze.crm_customers', 'U') IS NOT NULL
	DROP TABLE bronze.crm_customers
CREATE TABLE bronze.crm_customers
(
	[Customer Id] INT,
	[Customer Fname] NVARCHAR(50),
	[Customer Lname] NVARCHAR(50),
	[Customer Email] NVARCHAR(255),
	[Customer Password] NVARCHAR(255),
	[Customer Segment] NVARCHAR(50)
)

IF OBJECT_ID('bronze.store_departments', 'U') IS NOT NULL
	DROP TABLE bronze.store_departments
CREATE TABLE bronze.store_departments
(
	[Department Id] INT,
	[Department Name] NVARCHAR(50)
)

IF OBJECT_ID('bronze.store_locations', 'U') IS NOT NULL
	DROP TABLE bronze.store_locations
CREATE TABLE bronze.store_locations
(
	[Department Id] INT,
	Latitude DECIMAL(11, 8),
    Longitude DECIMAL(11, 8),
	[Customer City] NVARCHAR(50),
	[Customer Country] NVARCHAR(50),
	[Customer State] NVARCHAR(5),
	[Customer Street] NVARCHAR(255)
)

IF OBJECT_ID('bronze.erp_order_headers', 'U') IS NOT NULL
	DROP TABLE bronze.erp_order_headers
CREATE TABLE bronze.erp_order_headers
(
	[Order Id] INT,
	[Order Customer Id] INT,
	[Order Department Id] INT,
	[Order Date] DATETIME,
	[Order Status] NVARCHAR(50),
	Type NVARCHAR(50),
	Market NVARCHAR(50),
	[Order Region] NVARCHAR(50),
	[Order Country] NVARCHAR(50),
	[Order State] NVARCHAR(50),
	[Order City] NVARCHAR(50),
	[Order Zip Code] NVARCHAR(20),
	[Customer Stree] NVARCHAR(255)
)


IF OBJECT_ID('bronze.erp_order_items', 'U') IS NOT NULL
	DROP TABLE bronze.erp_order_items
CREATE TABLE bronze.erp_order_items
(
	[Order Item Id] INT,
	[Order Id] INT,
	[Order Item Cardprod Id] INT,
	[Order Item Quantity] INT,
	[Order Item product Price] DECIMAL(18, 4),
	[Order Item Discount] DECIMAL(18, 4),
	[Order Item Discount Rate] DECIMAL(5, 4),
	[Order Item Total] DECIMAL(18, 4),
	[Benefit per Order] DECIMAL(18, 4),
	[Order Item Profit Ratio] DECIMAL(5, 4),
	[Sales] DECIMAL(18, 4),
	[Order Profit Per Order] DECIMAL(18, 4),
	[Sales per customer] DECIMAL(18, 4)
)


IF OBJECT_ID('bronze.erp_products', 'U') IS NOT NULL
	DROP TABLE bronze.erp_products
CREATE TABLE bronze.erp_products
(
	[Product Card Id] INT,
	[Product Name] NVARCHAR(255),
	[Product Price] DECIMAL(18, 4),
	[Product Status] BIT,
	[Product Description] NVARCHAR(500),
	[Product Image] NVARCHAR(255),
	[Category Id] INT
)

IF OBJECT_ID('bronze.erp_products_staging', 'U') IS NOT NULL
	DROP TABLE bronze.erp_products_staging
CREATE TABLE bronze.erp_products_staging
(
    [Product Card Id] NVARCHAR(100),
    [Product Name] NVARCHAR(255),
    [Product Price] NVARCHAR(100),
    [Product Status] NVARCHAR(100),
    [Product Description] NVARCHAR(500),
    [Product Image] NVARCHAR(255),
    [Category Id] NVARCHAR(100) -- Import as text
);
GO

IF OBJECT_ID('bronze.erp_categories', 'U') IS NOT NULL
	DROP TABLE bronze.erp_categories
CREATE TABLE bronze.erp_categories
(
	[Category Id] INT,
	[Category Name] NVARCHAR(50)
)

IF OBJECT_ID('bronze.erp_shipping', 'U') IS NOT NULL
	DROP TABLE bronze.erp_shipping
CREATE TABLE bronze.erp_shipping
(
	[Order Id] INT,
	[shipping date] DATETIME,
	[Shipping Mode] NVARCHAR(50),
	[Days for shipping (real)] INT,
	[Days for shipping (scheduled)] INT,
	[Delivery Status] NVARCHAR(50),
	[Late_delivery_risk] BIT
)