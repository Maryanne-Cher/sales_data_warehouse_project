/* This SQL script performs a transformation of customer data from the bronze layer to the silver layer as part of a modern data pipeline. It includes the following steps:

Deduplication: Retains only the most recent record per cst_id using ROW_NUMBER() over cst_create_date.

Data Normalization: Standardizes cst_marital_status and cst_gndr values to readable formats (e.g., 'S' → 'Single', 'M' → 'Male').

Data Cleanup: Removes rows where cst_id is null after insertion.

Next Step (Optional): Highlights the presence of null values in the cst_gndr column (~5,000 rows) and recommends using Python for efficient enrichment or imputation if needed. */

INSERT INTO silver.crm_cust_info (
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date)

select
cst_id,
cst_key,
cst_firstname,
cst_lastname,
case 
-- normalize marital status values to readable format
when UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
when UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
ELSE cst_marital_status
END cst_marital_status,
case
-- normalize gender status values to readable format
when UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
when UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
ELSE cst_gndr
END cst_gndr,
cst_create_date
from (
select *,
--remove duplicates and only go with latest cst_create_Date
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) rank_num
from bronze.crm_cust_info)t1
where rank_num = 1

--after inserting the data into the silver layer, I noticed that cst_id had a null value. I manually deleted the row (cst_id IS NULL) in the silver table
delete from silver.crm_cust_info
where cst_id IS NULL

-- still need to assign gender values to null values in the cst_gndr column. there are 5000 rows so it'll be faster to use python (OPTIONAL. Can keep the null values if you want)
select *
from silver.crm_cust_info
where cst_gndr IS NULL
