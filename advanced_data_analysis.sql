/*
================================================================================
Advanced Data Analytics: Change Over Time Analysis
================================================================================
Purpose:
    Analyze sales performance over time, perform cumulative and proportional analysis,
    compare performance against targets, and segment customers and products.
================================================================================
*/

-- ===========================
-- SALES PERFORMANCE OVER TIME
-- ===========================

-- Total sales, customers, quantity by year and month
SELECT 
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month, 
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);


-- Total sales, customers, quantity by month (using date truncation)
SELECT 
    DATE_TRUNC('month', order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date);


-- ===========================
-- CUMULATIVE ANALYSIS
-- ===========================

-- Monthly total sales, running total sales, and moving average price
SELECT 
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,
    AVG(avg_price) OVER (ORDER BY order_month) AS moving_average_price
FROM (
    SELECT 
        DATE_TRUNC('month', order_date) AS order_month, 
        SUM(sales_amount) AS total_sales, 
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', order_date)
) t;


-- Yearly total sales, running total sales, and moving average price
SELECT 
    order_year,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_year) AS running_total_sales,
    AVG(avg_price) OVER (ORDER BY order_year) AS moving_average_price
FROM (
    SELECT 
        DATE_TRUNC('year', order_date) AS order_year, 
        SUM(sales_amount) AS total_sales, 
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE_TRUNC('year', order_date)
) t;


-- ===========================
-- PERFORMANCE ANALYSIS
-- ===========================

-- Compare yearly product sales to average sales and previous year sales
WITH yearly_performance AS (
    SELECT 
        YEAR(order_date) AS year_perf, 
        product_name, 
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date), product_name
)
SELECT
    year_perf,
    product_name,
    total_sales,
    AVG(total_sales) OVER (PARTITION BY product_name ORDER BY year_perf) AS avg_sales,
    total_sales - AVG(total_sales) OVER (PARTITION BY product_name ORDER BY year_perf) AS diff_avg,
    CASE 
        WHEN total_sales - AVG(total_sales) OVER (PARTITION BY product_name ORDER BY year_perf) > 0 THEN 'Above Avg'
        WHEN total_sales - AVG(total_sales) OVER (PARTITION BY product_name ORDER BY year_perf) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,
    LAG(total_sales) OVER (PARTITION BY product_name ORDER BY year_perf) AS py_sales,
    total_sales - LAG(total_sales) OVER (PARTITION BY product_name ORDER BY year_perf) AS diff_py,
    CASE 
        WHEN total_sales - LAG(total_sales) OVER (PARTITION BY product_name ORDER BY year_perf) > 0 THEN 'Increase'
        WHEN total_sales - LAG(total_sales) OVER (PARTITION BY product_name ORDER BY year_perf) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS py_change
FROM yearly_performance;


-- ===========================
-- PROPORTIONAL ANALYSIS: PART TO WHOLE
-- ===========================

-- Category contribution to total sales
SELECT 
    category, 
    SUM(sales_amount) AS total_sales, 
    100.0 * SUM(sales_amount) / SUM(SUM(sales_amount)) OVER () AS pct_of_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
GROUP BY category;


WITH category_sales AS (
    SELECT category, SUM(sales_amount) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    GROUP BY category
)
SELECT 
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND(CAST(total_sales AS FLOAT) * 100 / SUM(total_sales) OVER (), 2), '%') AS pct_total
FROM category_sales
ORDER BY total_sales DESC;


-- Subcategory contribution to total sales
WITH subcategory_sales AS (
    SELECT p.subcategory, SUM(s.sales_amount) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    GROUP BY p.subcategory
)
SELECT 
    subcategory, 
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND(CAST(total_sales * 100 AS FLOAT) / SUM(total_sales) OVER (), 2), '%') AS pct_total
FROM subcategory_sales
ORDER BY total_sales DESC;


-- ===========================
-- DATA SEGMENTATION
-- ===========================

-- Segment products into cost ranges
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range;


-- Segment customers by spending behavior
WITH Temp1 AS (
    SELECT 
        customer_key, 
        MIN(order_date) AS min_order_date,  -- earliest order
        MAX(order_date) AS max_order_date,  -- latest order
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_history,  -- months of order history
        SUM(sales_amount) AS total_sales    -- total sales
    FROM gold.fact_sales
    GROUP BY customer_key
), Temp2 AS (
    SELECT 
        customer_key,
        order_history,
        total_sales,
        CASE 
            WHEN total_sales > 5000 AND order_history >= 12 THEN 'VIP'        -- VIP: >12 months & >$5000 spent
            WHEN total_sales <= 5000 AND order_history >= 12 THEN 'Regular'    -- Regular: >12 months & ≤$5000 spent
            ELSE 'New'                                                         -- New: <12 months
        END AS customer_behavior
    FROM Temp1
)
SELECT 
    customer_behavior,
    COUNT(customer_key) AS total_customers
FROM Temp2
GROUP BY customer_behavior;
