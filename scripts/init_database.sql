/*
=====================================================
Create Database and Schemas
======================================================
*/

USE Master;
GO

--drop and recreate the 'sales_datawarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'sales_datawarehouse')
BEGIN
	ALTER DATABASE sales_datawarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE sales_datawarehouse
END;
GO

--create the 'sales_datawarehouse' database
CREATE DATABASE sales_datawarehouse;
GO

USE sales_datawarehouse;
GO

-- create schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE schema gold;
GO
