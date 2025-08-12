/*
================================================================================
Exploratory Data Analysis (EDA) Script
================================================================================
Purpose:
    Perform initial exploration of database objects, dimensions, dates, measures,
    and perform magnitude and ranking analysis on key business metrics.
================================================================================
*/

-- ===========================
-- DATABASE EXPLORATION
-- ===========================

-- Explore all tables in the database
SELECT * 
FROM information_schema.tables;

-- Explore all columns in the 'dim_customers' table
SELECT * 
FROM information_schema.columns
WHERE table_name = 'dim_customers';


-- ===========================
-- DIMENSIONS EXPLORATION
-- ===========================

-- List all distinct countries customers come from
SELECT DISTINCT country
FROM gold.dim_customers;

-- List all distinct categories, subcategories, and product names
SELECT DISTINCT category, subcategory, product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;


-- ===========================
-- DATE EXPLORATION
-- ===========================

-- Identify earliest and latest create_date in customers
SELECT 
    MIN(create_date) AS earliest_create_date, 
    MAX(create_date) AS latest_create_date 
FROM gold.dim_customers;

-- Identify youngest and oldest birthdate, and approximate ages
SELECT 
    MIN(birthdate) AS youngest_birthdate, 
    MAX(birthdate) AS oldest_birthdate,
    FORMAT(DATEDIFF(year, MIN(birthdate), GETDATE()), 'N0') + ' years' AS oldest_age,
    FORMAT(DATEDIFF(year, MAX(birthdate), GETDATE()), 'N0') + ' years' AS youngest_age
FROM gold.dim_customers;

-- Identify earliest and latest product start dates
SELECT 
    MIN(start_date) AS earliest_start_date, 
    MAX(start_date) AS latest_start_date 
FROM gold.dim_products;

-- Identify earliest and latest order dates and calculate range in months and years
SELECT 
    MIN(order_date) AS earliest_order_date, 
    MAX(order_date) AS latest_order_date,
    FORMAT(DATEDIFF(month, MIN(order_date), MAX(order_date)), 'N0') + ' months' AS order_range_months,
    FORMAT(DATEDIFF(year, MIN(order_date), MAX(order_date)), 'N0') + ' years' AS order_range_years
FROM gold.fact_sales;

-- Earliest and latest shipping dates
SELECT 
    MIN(shipping_date) AS earliest_shipping_date, 
    MAX(shipping_date) AS latest_shipping_date 
FROM gold.fact_sales;

-- Earliest and latest due dates
SELECT 
    MIN(due_date) AS earliest_due_date, 
    MAX(due_date) AS latest_due_date 
FROM gold.fact_sales;


-- ===========================
-- MEASURES EXPLORATION
-- ===========================

-- Total sales
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

-- Total quantity sold
SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales;

-- Average selling price
SELECT AVG(price) AS avg_price
FROM gold.fact_sales;

-- Total number of orders
SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

-- Total number of products
SELECT COUNT(DISTINCT product_name) AS total_products
FROM gold.dim_products;

-- Total number of customers
SELECT COUNT(customer_key) AS total_customers
FROM gold.dim_customers;

-- Total number of customers who have placed orders
SELECT COUNT(DISTINCT customer_key) AS orders_placed
FROM gold.fact_sales;

-- Total sales and total cost
SELECT 
    SUM(s.sales_amount) AS total_sales, 
    SUM(p.cost) AS total_cost
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
    ON p.product_key = s.product_key;


-- Key metrics report
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price' AS measure_name, AVG(price) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Orders' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products' AS measure_name, COUNT(DISTINCT product_name) AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers' AS measure_name, COUNT(customer_key) AS measure_value FROM gold.dim_customers;


-- ===========================
-- MAGNITUDE ANALYSIS
-- ===========================

-- Total customers by country
SELECT country, COUNT(DISTINCT customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Total customers by gender
SELECT gender, COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Total products by category
SELECT category, COUNT(DISTINCT product_name) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- Average cost per category
SELECT category, AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- Total revenue per category
SELECT category, SUM(sales_amount) AS total_revenue
FROM gold.fact_sales s
JOIN gold.dim_products p
    ON s.product_key = p.product_key
GROUP BY category
ORDER BY total_revenue DESC;

-- Top 10 customers by total revenue
SELECT TOP 10 
    c.customer_key, 
    c.first_name, 
    SUM(sales_amount) AS total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
    ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name
ORDER BY total_revenue DESC;

-- Revenue distribution across countries
SELECT country, SUM(sales_amount) AS total_revenue
FROM gold.fact_sales s
JOIN gold.dim_customers c
    ON s.customer_key = c.customer_key
GROUP BY country
ORDER BY total_revenue DESC;


-- ===========================
-- RANKING ANALYSIS
-- ===========================

-- Top 5 products by revenue
WITH product_ranking AS (
    SELECT 
        product_name, 
        SUM(sales_amount) AS total_revenue, 
        ROW_NUMBER() OVER (ORDER BY SUM(sales_amount) DESC) AS rank_num
    FROM gold.fact_sales s
    JOIN gold.dim_products p
        ON s.product_key = p.product_key
    GROUP BY product_name
)
SELECT product_name, total_revenue
FROM product_ranking
WHERE rank_num <= 5;


-- Bottom 5 products by revenue
WITH product_ranking AS (
    SELECT 
        product_name, 
        SUM(sales_amount) AS total_revenue, 
        ROW_NUMBER() OVER (ORDER BY SUM(sales_amount) ASC) AS rank_num
    FROM gold.fact_sales s
    JOIN gold.dim_products p
        ON s.product_key = p.product_key
    GROUP BY product_name
)
SELECT product_name, total_revenue
FROM product_ranking
WHERE rank_num <= 5;


-- Top 10 customers by revenue
SELECT * 
FROM (
    SELECT 
        c.customer_key, 
        c.first_name, 
        SUM(sales_amount) AS total_revenue, 
        ROW_NUMBER() OVER (ORDER BY SUM(sales_amount) DESC) AS rank_num
    FROM gold.fact_sales s
    JOIN gold.dim_customers c
        ON s.customer_key = c.customer_key
    GROUP BY c.customer_key, c.first_name
) t
WHERE rank_num <= 10;
