/*
--------------------------------------------------------------------------------
Purpose    : Cleans and inserts sales data from bronze layer to silver layer.
             - Fixes null or incorrect sales and price values.
             - Ensures all prices are positive.
             - Prevents divide-by-zero errors.
--------------------------------------------------------------------------------
Source     : bronze.crm_sales_details
Target     : silver.crm_sales_details
--------------------------------------------------------------------------------
*/

-- Insert cleaned sales data into the silver layer
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

    -- Clean sls_sales: recalculate if NULL, negative, or mismatched with quantity * price
    CASE 
        WHEN sls_sales IS NULL 
          OR sls_sales < 0 
          OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    -- Keep quantity as is
    sls_quantity AS sls_quantity,

    -- Clean sls_price: recalculate if NULL or zero/negative
    CASE 
        WHEN sls_price IS NULL 
          OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details;
