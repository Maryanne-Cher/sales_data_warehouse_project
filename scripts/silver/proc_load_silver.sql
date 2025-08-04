-- Stored procedure to load and clean data from Bronze to Silver layer
CREATE PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------
    -- Step 1: Load and clean crm_cust_info
    ---------------------------------------------
    TRUNCATE TABLE silver.crm_cust_info;

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
        CASE 
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE cst_marital_status
        END AS cst_marital_status,
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE cst_gndr
        END AS cst_gndr,
        cst_create_date
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rank_num
        FROM bronze.crm_cust_info
    ) t1
    WHERE rank_num = 1 AND cst_id IS NOT NULL; -- exclude null cst_id rows

    ---------------------------------------------
    -- Step 2: Load and clean crm_prd_info
    ---------------------------------------------
    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id,
        prd_key,
        cat_id,
        sales_prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        prd_key,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
        SUBSTRING(prd_key, 7, LEN(prd_key)) AS sales_prd_key,
        prd_nm,
        ISNULL(prd_cost, 0) AS prd_cost,
        CASE UPPER(prd_line)
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE prd_line
        END AS prd_line,
        prd_start_dt,
        DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
    FROM bronze.crm_prd_info;

    ---------------------------------------------
    -- Step 3: Load and clean crm_sales_details
    ---------------------------------------------
    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        CASE 
            WHEN sls_sales IS NULL OR sls_sales < 0 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        CASE 
            WHEN sls_price IS NULL OR sls_price <= 0 
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_details;

    ---------------------------------------------
    -- Step 4: Load and clean erp_cust_az12
    ---------------------------------------------
    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT 
        CASE 
            WHEN cid LIKE '%NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
            ELSE cid
        END AS cid,
        CASE 
            WHEN bdate > GETDATE() THEN NULL
            ELSE bdate
        END AS bdate,
        CASE
            WHEN gen IN ('F', 'Female') THEN 'Female'
            WHEN gen IN ('M', 'Male') THEN 'Male'
            ELSE 'n/a'
        END AS gen
    FROM bronze.erp_cust_az12;

    ---------------------------------------------
    -- Step 5: Load and clean erp_loc_a101
    ---------------------------------------------
    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', '') AS cid,
        CASE
            WHEN cntry IN ('DE', 'Germany') THEN 'Germany'
            WHEN cntry IN ('USA', 'United States', 'US') THEN 'United States'
            WHEN cntry IN ('Australia') THEN 'Australia'
            WHEN cntry IN ('United Kingdom') THEN 'United Kingdom'
            WHEN cntry IN ('Canada') THEN 'Canada'
            WHEN cntry IN ('France') THEN 'France'
            WHEN cntry IS NULL THEN 'n/a'
            ELSE cntry
        END AS cntry
    FROM bronze.erp_loc_a101;

    ---------------------------------------------
    -- Step 6: Load erp_px_cat_g1v2 (no transformation)
    ---------------------------------------------
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT 
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;
END;
