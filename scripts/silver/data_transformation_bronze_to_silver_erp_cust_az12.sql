/*
--------------------------------------------------------------------------------
Purpose     : Cleans and inserts customer data from the bronze layer into silver.
              - Replaces 'NAS' prefixes in CID to standardize format.
              - Sets future birthdates to NULL.
              - Normalizes gender values to 'Male', 'Female', or 'n/a'.
--------------------------------------------------------------------------------
Source      : bronze.erp_cust_az12
Target      : silver.erp_cust_az12
--------------------------------------------------------------------------------
*/

-- Insert cleaned customer data into the silver layer
INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen
)
SELECT 
    -- Remove 'NAS' prefix from cid values
    CASE 
        WHEN cid LIKE '%NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,

    -- Set birthdate to NULL if it’s in the future
    CASE 
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,

    -- Normalize gender values
    CASE
        WHEN gen IN ('F', 'Female') THEN 'Female'
        WHEN gen IN ('M', 'Male') THEN 'Male'
        ELSE 'n/a'
    END AS gen

FROM bronze.erp_cust_az12;
