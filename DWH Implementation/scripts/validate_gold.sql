
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


-- Customer Segmentation (RFM) Thresholds

DECLARE @AnalysisDate DATE;
SELECT @AnalysisDate = MAX([Order Date]) FROM silver.erp_order_headers;

WITH RFM_Base AS (
            SELECT 
                [Order Customer Id] AS customer_id,
                MIN([Order Date]) AS first_purchase_date,
                MAX([Order Date]) AS last_purchase_date,
                COUNT(DISTINCT oh.[Order Id]) AS frequency,
                SUM(Sales) AS monetary,
                DATEDIFF(DAY, MAX([Order Date]), @AnalysisDate) AS recency
            FROM 
                silver.erp_order_items oi
            JOIN 
                silver.erp_order_headers oh ON oi.[Order Id] = oh.[Order Id]
            GROUP BY 
                [Order Customer Id]
        ),
        RFM_Score AS (
            SELECT 
                *,
                -- Recency: High Days = Bad (1), Low Days = Good (5)
                NTILE(5) OVER(ORDER BY recency DESC) AS r_score,
                -- Frequency: Low Count = Bad (1), High Count = Good (5)
                NTILE(5) OVER(ORDER BY frequency ASC) AS f_score,
                -- Monetary: Low Spend = Bad (1), High Spend = Good (5)
                NTILE(5) OVER(ORDER BY monetary ASC) AS m_score
            FROM RFM_Base
        )

SELECT *
FROM RFM_Score
WHERE r_score >= 3 AND m_score > 4 AND frequency >= 4

/*
SELECT 
    'Frequency' AS Metric, f_score AS Score, MIN(frequency) as Min_Val, MAX(frequency) as Max_Val, COUNT(*) as Cnt FROM RFM_Score GROUP BY f_score
UNION ALL
SELECT 
    'Monetary', m_score, MIN(monetary), MAX(monetary), COUNT(*) FROM RFM_Score GROUP BY m_score
UNION ALL
SELECT 
    'Recency', r_score, MIN(recency), MAX(recency), COUNT(*) FROM RFM_Score GROUP BY r_score
ORDER BY Metric, Score
*/






SELECT customer_segment_rfm, COUNT(*)
FROM gold.dim_customers
GROUP BY customer_segment_rfm


SELECT customer_status, COUNT(*)
FROM gold.dim_customers
GROUP BY customer_status


SELECT customers_key, count(*)
FROM gold.fact_shipping
group by customers_key
having count(*) = 1

