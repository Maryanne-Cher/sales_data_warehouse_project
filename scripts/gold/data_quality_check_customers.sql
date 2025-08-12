/*
================================================================================
Data Quality Checks - gold.dim_customers
================================================================================

Purpose:
    Perform data quality validations before and after creating the gold-layer 
    customer dimension table.

Checks:
    1. Identify duplicate customer IDs.
    2. Compare gender values between crm_cust_info and erp_cust_az12.
    3. Inspect discrepancies and final gender assignment logic.
    4. Validate gender values in the final gold-layer table.

Notes:
    - These checks help ensure data integrity before loading to the gold layer.
    - Gender is resolved by preferring crm_cust_info unless NULL, 
      then falling back to erp_cust_az12.
================================================================================
*/

-- =============================================================================
-- 1. Check for duplicate customer IDs before gold-layer creation
-- =============================================================================
SELECT 
    cst_id, 
    COUNT(*) AS duplicate_count
FROM (
    SELECT
        ci.cst_id,
        ci.cst_key,
        ci.cst_firstname,
        ci.cst_lastname,
        ci.cst_marital_status,
        ci.cst_gndr,
        ci.cst_create_date,
        ca.bdate,
        ca.gen,
        la.cntry
    FROM silver.crm_cust_info AS ci
    LEFT JOIN silver.erp_cust_az12 AS ca
        ON ci.cst_key = ca.cid
    LEFT JOIN silver.erp_loc_a101 AS la
        ON ci.cst_key = la.cid
) t
GROUP BY cst_id
HAVING COUNT(*) > 1;


-- =============================================================================
-- 2. Check if gender columns match between sources
-- =============================================================================
-- This query identifies rows where gender values differ.
SELECT * 
FROM (
    SELECT
        ci.cst_id,
        ci.cst_key,
        ci.cst_firstname,
        ci.cst_lastname,
        ci.cst_marital_status,
        ci.cst_gndr,
        ci.cst_create_date,
        ca.bdate,
        ca.gen,
        la.cntry
    FROM silver.crm_cust_info AS ci
    LEFT JOIN silver.erp_cust_az12 AS ca
        ON ci.cst_key = ca.cid
    LEFT JOIN silver.erp_loc_a101 AS la
        ON ci.cst_key = la.cid
) t
WHERE cst_gndr != gen;


-- =============================================================================
-- 3. Further inspection of gender mismatch cases
-- =============================================================================
SELECT DISTINCT
    ci.cst_firstname,
    ci.cst_gndr,
    ca.gen,
    CASE 
        WHEN ci.cst_gndr IS NULL THEN ca.gen
        ELSE ci.cst_gndr
    END AS resolved_gender
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;


-- =============================================================================
-- 4. Post-creation validation - check distinct gender values in gold layer
-- =============================================================================
SELECT DISTINCT gender 
FROM gold.dim_customers;
