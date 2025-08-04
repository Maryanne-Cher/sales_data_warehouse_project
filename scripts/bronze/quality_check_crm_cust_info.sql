-- ============================================================
-- Inspect CRM Customer Info Table [bronze.crm_cust_info]
-- ============================================================

-- Preview top 1000 rows
SELECT TOP (1000)
    [cst_id],
    [cst_key],
    [cst_firstname],
    [cst_lastname],
    [cst_marital_status],
    [cst_gndr],
    [cst_create_date]
FROM [sales_datawarehouse].[bronze].[crm_cust_info];

-- ============================================================
-- NULL Checks
-- ============================================================

-- Check for NULLs in cst_id (1 row found; likely needs to be dropped)
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_id IS NULL;

-- Check for NULLs in cst_key (no nulls found)
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_key IS NULL;

-- Check for NULLs in cst_firstname
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_firstname IS NULL;

-- Check for NULLs in cst_lastname
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_lastname IS NULL;

-- Check for NULLs in cst_marital_status
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_marital_status IS NULL;

-- Check for NULLs in cst_gndr (5000+ rows; requires additional cleanup)
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_gndr IS NULL;

-- Check for NULLs in cst_create_date
SELECT * 
FROM bronze.crm_cust_info
WHERE cst_create_date IS NULL;

-- ============================================================
-- Duplicate Checks
-- ============================================================

-- Duplicates in cst_id
SELECT cst_id, COUNT(*) AS cust_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- Examine one duplicate cst_id (values mostly identical, different create dates)
SELECT *
FROM bronze.crm_cust_info
WHERE cst_id = 29466;

-- Duplicates in cst_key
SELECT cst_key, COUNT(*) AS cust_count
FROM bronze.crm_cust_info
GROUP BY cst_key
HAVING COUNT(*) > 1;

-- Examine one duplicate cst_key (values identical, different create dates)
SELECT *
FROM bronze.crm_cust_info
WHERE cst_key = 'AW00029483';

-- ============================================================
-- Data Quality Checks
-- ============================================================

-- Check for unwanted spaces in cst_lastname
SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Check unique values in gender (cst_gndr)
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

-- Check unique values in marital status (cst_marital_status)
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;
