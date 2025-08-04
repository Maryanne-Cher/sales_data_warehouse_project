-- ============================================================
-- Inspect CRM Product Info Table [bronze.crm_prd_info]
-- ============================================================

-- Preview top 1000 rows
SELECT TOP (1000)
    [prd_id],
    [prd_key],
    [prd_nm],
    [prd_cost],
    [prd_line],
    [prd_start_dt],
    [prd_end_dt]
FROM [sales_datawarehouse].[bronze].[crm_prd_info];

-- ============================================================
-- NULL Checks
-- ============================================================

-- Check for NULLs in product columns
SELECT * FROM bronze.crm_prd_info WHERE prd_id IS NULL;           -- No nulls
SELECT * FROM bronze.crm_prd_info WHERE prd_key IS NULL;          -- No nulls
SELECT * FROM bronze.crm_prd_info WHERE prd_nm IS NULL;           -- No nulls
SELECT * FROM bronze.crm_prd_info WHERE prd_cost IS NULL;         -- Nulls found; may infer from prd_nm
SELECT * FROM bronze.crm_prd_info WHERE prd_line IS NULL;         -- Nulls found
SELECT * FROM bronze.crm_prd_info WHERE prd_start_dt IS NULL;     -- No nulls
SELECT * FROM bronze.crm_prd_info WHERE prd_end_dt IS NULL;       -- Nulls found

-- ============================================================
-- Duplicate Checks
-- ============================================================

-- Check for duplicate product IDs (none expected)
SELECT prd_id, COUNT(*) AS prd_count
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- ============================================================
-- Date Quality Checks
-- ============================================================

-- Identify records where start date is after end date
SELECT *
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- Suggest replacement for incorrect prd_end_dt using next prd_start_dt - 1 day
SELECT *
FROM (
    SELECT 
        prd_id,
        prd_start_dt,
        DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt_test
    FROM bronze.crm_prd_info
) AS t
WHERE prd_start_dt > prd_end_dt_test;

-- ============================================================
-- Data Quality Checks
-- ============================================================

-- Check for invalid or inconsistent values in low cardinality columns
SELECT DISTINCT prd_line FROM bronze.crm_prd_info;

-- Check for unwanted whitespace in prd_line
SELECT prd_line
FROM bronze.crm_prd_info
WHERE prd_line != TRIM(prd_line);

-- Check for NULLs or negative values in prd_cost
SELECT DISTINCT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;

-- ============================================================
-- Relationship Validation
-- ============================================================

-- Validate relationship between crm_prd_info.prd_key and erp_px_cat_g1v2.id
-- (Transforming prd_key prefix to match id format)
SELECT
    prd_id,
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN (
    SELECT id FROM bronze.erp_px_cat_g1v2
);

-- Validate relationship between crm_prd_info.prd_key and crm_sales_details.sls_prd_key
-- (Extract sls_prd_key from prd_key starting at position 7)
SELECT
    prd_id,
    prd_key,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS sls_prd_key
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN (
    SELECT sls_prd_key FROM bronze.crm_sales_details
);
