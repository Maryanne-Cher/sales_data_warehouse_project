-- Preview top records
SELECT TOP (1000) [ID], [CAT], [SUBCAT], [MAINTENANCE]
FROM [sales_datawarehouse].[bronze].[erp_px_cat_g1v2];

-- ===============================
-- Data Quality Checks
-- ===============================

-- Check for NULLs in ID (result: no nulls)
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE id IS NULL;

-- Check for NULLs in CAT (result: no nulls)
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat IS NULL;

-- Check for NULLs in SUBCAT (result: no nulls)
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE subcat IS NULL;

-- Check for NULLs in MAINTENANCE (result: no nulls)
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE maintenance IS NULL;

-- Check for duplicate IDs (result: no duplicates)
SELECT id, COUNT(*) AS id_count
FROM bronze.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;

-- View distinct MAINTENANCE values
SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;

-- ===============================
-- Relationship Check
-- ===============================

-- Check if IDs exist in cat_id from crm_prd_info (some IDs may be unmatched)
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE id NOT IN (
    SELECT cat_id
    FROM silver.crm_prd_info
);

-- ===============================
-- Whitespace Check
-- ===============================

-- Find rows with leading/trailing spaces in CAT, SUBCAT, or MAINTENANCE
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);
