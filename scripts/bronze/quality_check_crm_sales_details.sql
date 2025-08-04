-- ============================================================
-- Inspect CRM Sales Details Table [bronze.crm_sales_details]
-- ============================================================

-- Preview top 1000 rows
SELECT TOP (1000)
    [sls_ord_num],
    [sls_prd_key],
    [sls_cust_id],
    [sls_order_dt],
    [sls_ship_dt],
    [sls_due_dt],
    [sls_sales],
    [sls_quantity],
    [sls_price]
FROM [sales_datawarehouse].[bronze].[crm_sales_details];

-- ============================================================
-- NULL & Duplicate Checks
-- ============================================================

-- Check for NULLs in sls_ord_num (none found)
SELECT * FROM bronze.crm_sales_details WHERE sls_ord_num IS NULL;

-- Check for duplicates in sls_ord_num
SELECT sls_ord_num, COUNT(*) AS order_count
FROM bronze.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1;

-- Explore a duplicate order (e.g., bulk order with multiple products)
SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_ord_num = N'SO54377';

-- ============================================================
-- Date Integrity Checks
-- ============================================================

-- Check for invalid date sequences
SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_order_dt > sls_ship_dt 
   OR sls_ship_dt > sls_due_dt 
   OR sls_order_dt > sls_due_dt;

-- Identify NULLs in date columns
SELECT * FROM bronze.crm_sales_details WHERE sls_order_dt IS NULL;  -- NULLs present
SELECT * FROM bronze.crm_sales_details WHERE sls_ship_dt IS NULL;   -- No NULLs
SELECT * FROM bronze.crm_sales_details WHERE sls_due_dt IS NULL;    -- No NULLs

-- Distinct values of order dates (quick scan)
SELECT DISTINCT sls_order_dt FROM bronze.crm_sales_details;

-- ============================================================
-- Quantity, Sales, Price Consistency Checks
-- ============================================================

-- Check for NULLs or invalid values
SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_quantity IS NULL OR sls_quantity <= 0;

SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_price IS NULL OR sls_price <= 0;

SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_sales IS NULL OR sls_sales < 0;

-- Recalculate sales and price for validation
SELECT *
FROM (
    SELECT DISTINCT
        sls_ord_num,
        sls_quantity,
        sls_price AS old_sls_price,
        sls_sales AS old_sls_sales,
        CASE 
            WHEN sls_sales IS NULL OR sls_sales < 0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS recalculated_sales,
        CASE 
            WHEN sls_price IS NULL OR sls_price <= 0 
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS recalculated_price
    FROM bronze.crm_sales_details
) t
WHERE recalculated_sales != sls_quantity * recalculated_price;

-- Alternative sales-price-quantity validation
SELECT *
FROM (
    SELECT
        sls_ord_num,
        sls_sales,
        sls_quantity,
        sls_price,
        CASE 
            WHEN sls_price IS NULL THEN sls_sales * sls_quantity
            ELSE sls_price
        END AS new_sls_price
    FROM bronze.crm_sales_details
) t
WHERE new_sls_price != sls_sales * sls_quantity;

-- ============================================================
-- Relationship Validations
-- ============================================================

-- Check if sls_prd_key exists in crm_prd_info (e.g., orphaned product keys)
SELECT * 
FROM silver.crm_prd_info 
WHERE sales_prd_key = 'CA-1098';  -- Confirm match

-- Check for unmatched customer IDs
SELECT *
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (
    SELECT cst_id FROM bronze.crm_cust_info
);

-- Check if sls_prd_key exists in crm_sales_details
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_sales * sls_quantity AS expected_price
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (
    SELECT sls_cust_id FROM silver.crm_prd_info
);

-- ============================================================
-- Final Consistency Summary
-- ============================================================

-- Final check on combinations of sales, quantity, and price
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales < 0
   OR sls_quantity <= 0
   OR sls_price <= 0;
