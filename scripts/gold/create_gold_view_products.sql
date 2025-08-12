/*
================================================================================
DDL Script: Create Gold View - dim_products
================================================================================

Description:
    This script creates the gold-layer dimension table for products 
    as part of the star schema model.

Transformations:
    1. Joins crm_prd_info and erp_px_cat_g1v2 to enrich product attributes.
    2. Applies data quality filtering to exclude historical products 
       (i.e., where prd_end_dt IS NOT NULL).
    3. Renames columns to friendly, snake_case names.
    4. Rearranges columns for logical data flow.
    5. Generates a surrogate key for internal usage.

Notes:
    - All column names use lowercase snake_case.
    - Product category and subcategory are sourced from erp_px_cat_g1v2.
    - Only active products are included.
================================================================================
*/

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY i.prd_start_dt, i.sales_prd_key) AS product_key,  -- Surrogate key
    i.prd_id                           AS product_id,
    i.sales_prd_key                    AS product_number,
    i.prd_nm                           AS product_name,
    i.cat_id                           AS category_id,
    g.cat                              AS category,
    g.subcat                           AS subcategory,
    g.maintenance                      AS maintenance,
    i.prd_cost                         AS cost,
    i.prd_line                         AS product_line,
    i.prd_start_dt                     AS start_date
FROM silver.crm_prd_info AS i
LEFT JOIN silver.erp_px_cat_g1v2 AS g
    ON i.cat_id = g.id
WHERE i.prd_end_dt IS NULL;  -- Keep only active products
