-- ============================================================
-- Inspect ERP Customer Table [bronze.erp_cust_az12]
-- ============================================================

-- Preview top 1000 rows
SELECT TOP (1000)
    [CID],
    [BDATE],
    [GEN]
FROM [sales_datawarehouse].[bronze].[erp_cust_az12];

-- ============================================================
-- NULL & Duplicate Checks
-- ============================================================

-- Check for NULLs in CID (none found)
SELECT * 
FROM bronze.erp_cust_az12 
WHERE cid IS NULL;

-- Check for duplicate CID values (none found)
SELECT cid, COUNT(*) AS cid_count
FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;

-- Check for NULLs in BDATE (none found)
SELECT *
FROM bronze.erp_cust_az12
WHERE bdate IS NULL;

-- Check for NULLs in GEN (nulls found)
SELECT *
FROM bronze.erp_cust_az12
WHERE gen IS NULL;

-- ============================================================
-- ID Format & Relationship Validation
-- ============================================================

-- Check if all CIDs exist in crm_cust_info.cst_key (some do not match)
SELECT cid, bdate, gen
FROM bronze.erp_cust_az12
WHERE cid NOT IN (
    SELECT cst_key FROM silver.crm_cust_info
);

-- Normalize CID format (strip 'NAS' prefix to match cst_key)
-- Identify non-matching CIDs after transformation
SELECT
    cid,
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS normalized_cid
FROM bronze.erp_cust_az12
WHERE 
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END NOT IN (
        SELECT cst_key FROM silver.crm_cust_info
    );

-- ============================================================
-- Birthdate Validation
-- ============================================================

-- Identify out-of-range birthdates (older than 1925 or in the future)
SELECT bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1925-01-01' OR bdate > GETDATE();

-- Suggest fix: replace future dates with NULL
SELECT *
FROM (
    SELECT *,
        CASE 
            WHEN bdate > GETDATE() THEN NULL
            ELSE bdate
        END AS new_bdate
    FROM bronze.erp_cust_az12
) t
WHERE new_bdate > GETDATE();

-- ============================================================
-- Gender Normalization
-- ============================================================

-- Normalize values in GEN column to 'Male', 'Female', or 'n/a'
SELECT DISTINCT new_gen
FROM (
    SELECT *,
        CASE
            WHEN gen IN ('F', 'Female') THEN 'Female'
            WHEN gen IN ('M', 'Male') THEN 'Male'
            ELSE 'n/a'
        END AS new_gen
    FROM bronze.erp_cust_az12
) t;
