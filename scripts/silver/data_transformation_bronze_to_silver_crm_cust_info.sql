/*
--------------------------------------------------------------------------------
Purpose     : Cleans and loads customer info from bronze to silver layer.
              - Removes duplicate `cst_id` entries by keeping the most recent.
              - Normalizes gender and marital status values.
              - Deletes records with null `cst_id`.
              - Flags remaining rows with null gender for further cleanup in Python.
--------------------------------------------------------------------------------
Source      : bronze.crm_cust_info
Target      : silver.crm_cust_info
--------------------------------------------------------------------------------
*/

-- Step 1: Insert cleaned data, keeping latest entry per customer (based on cst_create_date)
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    -- Normalize marital status
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE cst_marital_status
    END AS cst_marital_status,
    -- Normalize gender
    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE cst_gndr
    END AS cst_gndr,
    cst_create_date
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id 
            ORDER BY cst_create_date DESC
        ) AS rank_num
    FROM bronze.crm_cust_info
) t1
WHERE rank_num = 1;

-- Step 2: Manually delete any record where cst_id is NULL (should not exist)
DELETE FROM silver.crm_cust_info
WHERE cst_id IS NULL;
