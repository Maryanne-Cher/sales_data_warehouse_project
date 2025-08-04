-- Preview top records
SELECT TOP (1000) [CID], [CNTRY]
FROM [sales_datawarehouse].[bronze].[erp_loc_a101];

-- Check for NULLs in CID (result: no nulls)
SELECT *
FROM bronze.erp_loc_a101
WHERE cid IS NULL;

-- View distinct CID values
SELECT DISTINCT cid
FROM bronze.erp_loc_a101;

-- Check for duplicate CID values (result: no duplicates)
SELECT cid, COUNT(*) AS cid_count
FROM bronze.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1;

-- Check for NULLs in CNTRY (result: there are nulls)
SELECT *
FROM bronze.erp_loc_a101
WHERE cntry IS NULL;

-- Solution: Replace NULL CNTRY values with 'n/a'
SELECT *,
       CASE 
           WHEN cntry IS NULL THEN 'n/a'
           ELSE cntry
       END AS new_cntry
FROM bronze.erp_loc_a101;

-- Normalize CNTRY values into readable format
SELECT DISTINCT new_cntry
FROM (
    SELECT *,
           CASE
               WHEN cntry IN ('DE', 'Germany') THEN 'Germany'
               WHEN cntry IN ('USA', 'United States', 'US') THEN 'United States'
               WHEN cntry = 'Australia' THEN 'Australia'
               WHEN cntry = 'United Kingdom' THEN 'United Kingdom'
               WHEN cntry = 'Canada' THEN 'Canada'
               WHEN cntry = 'France' THEN 'France'
               WHEN cntry IS NULL THEN 'n/a'
               ELSE cntry
           END AS new_cntry
    FROM bronze.erp_loc_a101
) t1;

-- Check if CID (after removing dash) matches cst_key in crm_cust_info
SELECT *,
       REPLACE(cid, '-', '') AS new_cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (
    SELECT cst_key
    FROM silver.crm_cust_info
);
