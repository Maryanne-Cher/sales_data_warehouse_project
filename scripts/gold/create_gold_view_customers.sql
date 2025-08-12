/*
================================================================================
DDL Script: Create Gold View - dim_customers
================================================================================

Description:
    This script creates the gold-layer dimension table for customers 
    as part of the star schema model.

Transformations:
    1. Joins crm_cust_info, erp_cust_az12, and erp_loc_a101 
       to create a unified customer view.
    2. Applies data quality checks (e.g., fallback gender source).
    3. Renames columns to friendly, snake_case names.
    4. Rearranges columns for logical data flow.
    5. Generates a surrogate key for internal usage.

Notes:
    - All column names use lowercase snake_case.
    - Gender is taken from crm_cust_info if available, otherwise from erp_cust_az12.

================================================================================
*/
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
  
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,       -- Surrogate key
    ci.cst_id                          AS customer_id,
    ci.cst_key                         AS customer_number,
    ci.cst_firstname                   AS first_name,
    ci.cst_lastname                    AS last_name,
    la.cntry                           AS country,
    ci.cst_marital_status              AS marital_status,
    CASE 
        WHEN ci.cst_gndr IS NULL THEN ca.gen
        ELSE ci.cst_gndr
    END                                AS gender,
    ca.bdate                           AS birthdate,
    ci.cst_create_date                 AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;
