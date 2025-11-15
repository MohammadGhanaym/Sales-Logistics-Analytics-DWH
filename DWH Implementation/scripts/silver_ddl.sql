USE DWH_Supply_Chain

IF OBJECT_ID('silver.crm_customers', 'U') IS NOT NULL
	DROP TABLE silver.crm_customers
CREATE TABLE silver.crm_customers
(
	[Customer Id] INT,
	[Customer Fname] NVARCHAR(50),
	[Customer Lname] NVARCHAR(50),
	[Customer Segment] NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
)

IF OBJECT_ID('silver.erp_store_departments', 'U') IS NOT NULL
	DROP TABLE silver.erp_store_departments
CREATE TABLE silver.erp_store_departments
(
	[Department Id] INT,
	[Department Name] NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
)

IF OBJECT_ID('silver.erp_store_locations', 'U') IS NOT NULL
	DROP TABLE silver.erp_store_locations
CREATE TABLE silver.erp_store_locations
(
	location_key INT IDENTITY(1, 1),
	[Customer Country] NVARCHAR(50),
	[Customer State] NVARCHAR(5),
	[Customer City] NVARCHAR(50),
	[Customer Street] NVARCHAR(255),
	Latitude DECIMAL(11, 8),
    Longitude DECIMAL(11, 8),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
)


IF OBJECT_ID('silver.erp_order_headers', 'U') IS NOT NULL
	DROP TABLE silver.erp_order_headers
CREATE TABLE silver.erp_order_headers
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
	[Customer State] NVARCHAR(5),
	[Customer City] NVARCHAR(50),
	[Customer Street] NVARCHAR(255)
)

IF OBJECT_ID('silver.erp_order_items', 'U') IS NOT NULL
	DROP TABLE silver.erp_order_items
CREATE TABLE silver.erp_order_items
(
	[Order Item Id] INT,
	[Order Id] INT,
	[Order Item Cardprod Id] INT,
	[Order Item Quantity] INT,
	[Order Item product Price] DECIMAL(18, 4),
	[Order Item Discount] DECIMAL(18, 4),
	[Order Item Discount Rate] DECIMAL(5, 4),
	[Order Item Total] DECIMAL(18, 4),
	[Order Item Profit Ratio] DECIMAL(5, 4),
	[Sales] DECIMAL(18, 4),
	[Order Profit Per Order] DECIMAL(18, 4),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
)

IF OBJECT_ID('silver.erp_categories', 'U') IS NOT NULL
	DROP TABLE silver.erp_categories
CREATE TABLE silver.erp_categories
(
	[Category Id] INT,
	[Category Name] NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
)


IF OBJECT_ID('silver.erp_products', 'U') IS NOT NULL
	DROP TABLE silver.erp_products
CREATE TABLE silver.erp_products
(
	[Product Card Id] INT,
	[Product Name] NVARCHAR(255),
	[Product Price] DECIMAL(18, 4),
	[Product Status] BIT,
	[Product Description] NVARCHAR(500),
	[Product Image] NVARCHAR(255),
	[Category Id] INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
)



IF OBJECT_ID('silver.erp_shipping', 'U') IS NOT NULL
	DROP TABLE silver.erp_shipping
CREATE TABLE silver.erp_shipping
(
	[Order Id] INT,
	[shipping date] DATETIME,
	[Shipping Mode] NVARCHAR(50),
	[Days for shipping (real)] INT,
	[Days for shipping (scheduled)] INT,
	[Delivery Status] NVARCHAR(50),
	[Late_delivery_risk] BIT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
)