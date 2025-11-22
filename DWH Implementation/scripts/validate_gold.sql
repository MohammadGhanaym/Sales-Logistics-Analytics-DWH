
EXEC gold.load_gold

SELECT *
FROM gold.dim_customers


SELECT *
FROM gold.dim_products


SELECT *
FROM gold.dim_store_departments


SELECT *
FROM gold.dim_date


SELECT *
FROM gold.dim_time


SELECT *
FROM gold.dim_store_locations

SELECT *
FROM gold.dim_order_geography

SELECT *
FROM gold.dim_transactions_info

SELECT *
FROM gold.fact_sales
WHERE order_date_key NOT IN (SELECT date_key FROM gold.dim_date)
OR order_time_key NOT IN (SELECT time_key FROM gold.dim_time)


SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN products_key IS NULL THEN 1 ELSE 0 END) AS null_product_keys,
    SUM(CASE WHEN store_locations_key IS NULL THEN 1 ELSE 0 END) AS null_location_keys,
    SUM(CASE WHEN order_geography_key IS NULL THEN 1 ELSE 0 END) AS null_geography_keys,
    SUM(CASE WHEN store_departments_key IS NULL THEN 1 ELSE 0 END) AS null_department_keys,
    SUM(CASE WHEN transactions_info_key IS NULL THEN 1 ELSE 0 END) AS null_transaction_keys,
    SUM(CASE WHEN customers_key IS NULL THEN 1 ELSE 0 END) AS null_customer_keys,
    SUM(CASE WHEN order_date_key IS NULL THEN 1 ELSE 0 END) AS null_date_keys,
    SUM(CASE WHEN order_time_key IS NULL THEN 1 ELSE 0 END) AS null_time_keys
FROM
    gold.fact_sales;


SELECT *
FROM gold.fact_shipping


SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN store_locations_key IS NULL THEN 1 ELSE 0 END) AS null_location_keys,
    SUM(CASE WHEN order_geography_key IS NULL THEN 1 ELSE 0 END) AS null_geography_keys,
    SUM(CASE WHEN transactions_info_key IS NULL THEN 1 ELSE 0 END) AS null_transaction_keys,
    SUM(CASE WHEN customers_key IS NULL THEN 1 ELSE 0 END) AS null_customer_keys,
    SUM(CASE WHEN order_date_key IS NULL THEN 1 ELSE 0 END) AS null_date_keys,
    SUM(CASE WHEN order_time_key IS NULL THEN 1 ELSE 0 END) AS null_time_keys,
    SUM(CASE WHEN shipping_date_key IS NULL THEN 1 ELSE 0 END) AS null_shipping_date_keys
FROM
    gold.fact_shipping;


