/*
================================================================================
DDL Script: Create Gold View - dim_date
================================================================================

Description:
    Creates a date dimension table for use in the gold-layer star schema.
    Includes a surrogate key (date_key) in YYYYMMDD format and attributes 
    for common date-based analysis.

Features:
    - Covers date range from 2010-01-01 to 2014-12-31.
    - Includes day, month, month name, quarter, year, weekday, weekday name.
    - Flags weekends for easier filtering.

Notes:
    - Naming convention: snake_case, lowercase.
    - Primary key: date_key (int, format YYYYMMDD).
    - Useful for joining to fact tables on surrogate keys.
================================================================================
*/

-- =============================================================================
-- 1. Create table
-- =============================================================================
CREATE TABLE gold.dim_date (
    date_key INT PRIMARY KEY,         -- Format: YYYYMMDD
    full_date DATE,
    day_num INT,                      -- Day of month
    month_num INT,                    -- Month number
    month_name VARCHAR(20),
    quarter_num INT,
    year_num INT,
    weekday_num INT,                   -- Sunday = 1 (SQL Server default)
    weekday_name VARCHAR(20),
    is_weekend BIT
);

-- =============================================================================
-- 2. Populate table
-- =============================================================================
DECLARE @start_date DATE = '2010-01-01';
DECLARE @end_date   DATE = '2014-12-31';

WHILE @start_date <= @end_date
BEGIN
    INSERT INTO gold.dim_date (
        date_key,
        full_date,
        day_num,
        month_num,
        month_name,
        quarter_num,
        year_num,
        weekday_num,
        weekday_name,
        is_weekend
    )
    VALUES (
        CONVERT(INT, FORMAT(@start_date, 'yyyyMMdd')),
        @start_date,
        DAY(@start_date),
        MONTH(@start_date),
        DATENAME(MONTH, @start_date),
        DATEPART(QUARTER, @start_date),
        YEAR(@start_date),
        DATEPART(WEEKDAY, @start_date),
        DATENAME(WEEKDAY, @start_date),
        CASE 
            WHEN DATENAME(WEEKDAY, @start_date) IN ('Saturday', 'Sunday') THEN 1
            ELSE 0
        END
    );

    SET @start_date = DATEADD(DAY, 1, @start_date);
END;
