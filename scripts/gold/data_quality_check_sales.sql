/*
================================================================================
Data Quality Checks - gold.fact_sales
================================================================================

Purpose:
    Perform data quality validations on the gold-layer fact_sales table.

Checks:
    1. Validate overall record content.
    2. Ensure foreign key integrity for dimension joins 
       (fact_sales → dim_customers, dim_products).

Notes:
    - Missing dimension keys indicate data quality issues 
      or incomplete dimension loads.
    - Foreign key validation is done using LEFT JOIN and checking for NULL matches.
================================================================================
*/

-- =============================================================================
-- 1. Basic record inspection for fact_sales
-- =============================================================================
SELECT * 
FROM gold.fact_sales;


-- =============================================================================
-- 2. Foreign key integrity check - customer and product dimensions
-- =============================================================================
-- This check flags fact_sales records that do not have matching dimension entries.
SELECT *
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL;
