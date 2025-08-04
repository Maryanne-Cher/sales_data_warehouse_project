/*
--------------------------------------------------------------------------------
Purpose     : Cleans and inserts location data from the bronze layer to silver.
              - Removes dashes from customer IDs.
              - Standardizes country names for consistency.
              - Replaces NULL country values with 'n/a'.
--------------------------------------------------------------------------------
Source      : bronze.erp_loc_a101
Target      : silver.erp_loc_a101
--------------------------------------------------------------------------------
*/

-- Insert cleaned location data into the silver layer
INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)
SELECT
    -- Remove dashes from cid
    REPLACE(cid, '-', '') AS cid,

    -- Standardize country names
    CASE
        WHEN cntry IN ('DE', 'Germany') THEN 'Germany'
        WHEN cntry IN ('USA', 'United States', 'US') THEN 'United States'
        WHEN cntry = 'Australia' THEN 'Australia'
        WHEN cntry = 'United Kingdom' THEN 'United Kingdom'
        WHEN cntry = 'Canada' THEN 'Canada'
        WHEN cntry = 'France' THEN 'France'
        WHEN cntry IS NULL THEN 'n/a'
        ELSE cntry
    END AS cntry

FROM bronze.erp_loc_a101;
