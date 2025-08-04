/*
===========================================================
Purpose: This transformation script extracts, cleans, and loads product data 
from the bronze layer into the silver layer for analytics-ready use.

Key transformations:
- Derives category and sales keys from `prd_key`
- Replaces null `prd_cost` values with 0
- Normalizes `prd_line` codes to readable labels
- Infers `prd_end_dt` using the next available `prd_start_dt` (minus one day)
- Ensures proper formatting and enrichment of raw product records

Target Table: silver.crm_prd_info
Source Table: bronze.crm_prd_info

Note: Ensure the destination table has all required columns and uses the correct DATE data type before running.
===========================================================
*/


--pre_check: before inserting the transformed data, remember to add the new columns and change data type of the date columns (only need date)
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
select
prd_id,
prd_key,
-- extract values in the prd_key column for the cat_id column in the erp_px_cat_g1v2 table
replace(substring(prd_key, 1, 5), '-', '_') AS cat_id,
-- extract values in the prd_key column for the sls_prd_key column in the crm_sales_details table
substring(prd_key, 7, LEN(prd_key)) as sales_prd_key,
prd_nm,
--handle missing cost values by replacing nulls with 0
ISNULL(prd_cost, 0) AS prd_cost,
-- normalize prd_line values to readable format
CASE UPPER(prd_line)
	when 'M' THEN 'Mountain'
	when 'R' THEN 'Road'
	when 'S' THEN 'Other Sales'
	when 'T' THEN 'Touring'
	ELSE prd_line
END prd_line,
prd_start_dt,
--used the next prd_start_dt as a reference to infer prd_end_dt, subtracting 1 day
dateadd(day, -1, lead(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
from bronze.crm_prd_info
