 /*
===============================================================================
DDL Script: Create silver tables
===============================================================================
*/

-- customers info table
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO
  
CREATE TABLE [silver].[crm_cust_info](
	[cst_id] [smallint] NULL,
	[cst_key] [nvarchar](50) NULL,
	[cst_firstname] [nvarchar](50) NULL,
	[cst_lastname] [nvarchar](50) NULL,
	[cst_marital_status] [nvarchar](50) NULL,
	[cst_gndr] [nvarchar](50) NULL,
	[cst_create_date] [date] NULL
) ON [PRIMARY]
GO

-- products info table
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO
   
CREATE TABLE [silver].[crm_prd_info](
	[prd_id] [smallint] NULL,
	[prd_key] [nvarchar](50) NULL,
	[prd_nm] [nvarchar](50) NULL,
	[prd_cost] [smallint] NULL,
	[prd_line] [nvarchar](50) NULL,
	[prd_start_dt] [date] NULL,
	[prd_end_dt] [date] NULL
) ON [PRIMARY]
GO

-- sales details table
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE [silver].[crm_sales_details](
	[sls_ord_num] [nvarchar](50) NULL,
	[sls_prd_key] [nvarchar](50) NULL,
	[sls_cust_id] [smallint] NULL,
	[sls_order_dt] [date] NULL,
	[sls_ship_dt] [date] NULL,
	[sls_due_dt] [date] NULL,
	[sls_sales] [smallint] NULL,
	[sls_quantity] [tinyint] NULL,
	[sls_price] [smallint] NULL
) ON [PRIMARY]
GO

-- customers info table
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE [silver].[erp_cust_az12](
	[CID] [nvarchar](50) NULL,
	[BDATE] [datetime2](7) NULL,
	[GEN] [nvarchar](50) NULL
) ON [PRIMARY]
GO

-- location info table
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE [silver].[erp_loc_a101](
	[CID] [nvarchar](50) NULL,
	[CNTRY] [nvarchar](50) NULL
) ON [PRIMARY]
GO

--products info table
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO
  
CREATE TABLE [silver].[erp_px_cat_g1v2](
	[ID] [nvarchar](50) NULL,
	[CAT] [nvarchar](50) NULL,
	[SUBCAT] [nvarchar](50) NULL,
	[MAINTENANCE] [nvarchar](50) NULL
) ON [PRIMARY]
GO
