/*
================================================================================
Data Quality Checks - gold.dim_products
================================================================================

Purpose:
    Perform data quality validations before creating the gold-layer 
    product dimension table.

Checks:
    1. Verify that category IDs match between crm_prd_info and erp_px_cat_g1v2.
    2. Confirm that prd_key contains no duplicates (since it will be used 
       for joining to sales facts).
    3. Exclude historical products (where prd_end_dt IS NOT NULL).

Notes:
    - All column names are snake_case.
    - Category, subcategory, and maintenance flags are sourced from erp_px_cat_g1v2.
    - The gold layer will include only active products.
================================================================================
*/

-- =============================================================================
-- 1. Check for mismatched category IDs between product and category tables
-- =============================================================================
SELECT * 
FROM (
    SELECT
        i.prd_id,
        i.prd_key,
        i.cat_id,
        i.sales_prd_key,
        i.prd_nm,
        i.prd_cost,
        i.prd_line,
        i.prd_start_dt,
        i.prd_end_dt,
        g.id,
        g.cat,
        g.subcat,
        g.maintenance
    FROM silver.crm_prd_info AS i
    LEFT JOIN silver.erp_px_cat_g1v2 AS g
        ON i.cat_id = g.id
) t
WHERE cat_id != id;


-- =============================================================================
-- 2. Check for duplicate prd_key values (used in fact_sales joins)
-- =============================================================================
-- Expectation: No duplicates should exist.
SELECT 
    prd_key, 
    COUNT(*) AS duplicate_count
FROM (
    SELECT
        i.prd_id,
        i.prd_key,
        i.cat_id,
        i.sales_prd_key,
        i.prd_nm,
        i.prd_cost,
        i.prd_line,
        i.prd_start_dt,
        g.cat,
        g.subcat,
        g.maintenance
    FROM silver.crm_prd_info AS i
    LEFT JOIN silver.erp_px_cat_g1v2 AS g
        ON i.cat_id = g.id
    WHERE prd_end_dt IS NULL   -- Filter out historical data
) t
GROUP BY prd_key
HAVING COUNT(*) > 1;
