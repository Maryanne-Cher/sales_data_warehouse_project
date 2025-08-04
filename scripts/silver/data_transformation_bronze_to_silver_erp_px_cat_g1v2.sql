/*
--------------------------------------------------------------------------------
Purpose     : Refreshes the silver.erp_px_cat_g1v2 table with the latest clean data 
              from the bronze layer.
              - Clears existing records from silver table.
              - Inserts fresh data from bronze layer.
--------------------------------------------------------------------------------
Source      : bronze.erp_px_cat_g1v2
Target      : silver.erp_px_cat_g1v2
--------------------------------------------------------------------------------
*/

-- Truncate the target table to remove old data
TRUNCATE TABLE silver.erp_px_cat_g1v2;

-- Insert updated category data from the bronze layer
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
