/*
================================================================================
DDL Script: Fact Table - fact_sales
================================================================================

Description:
    This script creates the fact_sales table, linking sales transactions to 
    dimension tables using surrogate keys for consistent joins in the star schema.

Transformations:
    1. Joins crm_sales_details (silver layer) with gold.dim_products 
       and gold.dim_customers to replace natural keys with surrogate keys.
    2. Removes reliance on raw IDs (e.g., sls_prd_key, sls_cust_id) 
       for cleaner, faster joins.
    3. Selects relevant sales metrics and transaction dates.

Notes:
    - Surrogate keys are sourced from gold-layer dimensions for 
      easier fact-to-dimension connections.
    - All column names follow lowercase snake_case.
    - Pricing and quantity are taken directly from the source without 
      aggregation for this base fact table.
================================================================================
*/
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    d.sls_ord_num               AS order_number,
    p.product_key,              -- Surrogate key from gold.dim_products
    c.customer_key,             -- Surrogate key from gold.dim_customers
    d.sls_order_dt              AS order_date,
    d.sls_ship_dt               AS shipping_date,
    d.sls_due_dt                AS due_date,
    d.sls_sales                 AS sales_amount,
    d.sls_quantity              AS quantity,
    d.sls_price                 AS price
FROM silver.crm_sales_details AS d
LEFT JOIN gold.dim_products AS p
    ON d.sls_prd_key = p.product_number
LEFT JOIN gold.dim_customers AS c
    ON d.sls_cust_id = c.customer_id
GO;
