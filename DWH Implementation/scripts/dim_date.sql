
-- =================================================================
-- Step 1: Declare variables to hold the dynamic date range
-- =================================================================
DECLARE @MinDate DATE;
DECLARE @MaxDate DATE;

-- =================================================================
-- Step 2: Find the MIN and MAX dates from your source tables
-- This query checks both tables to find the earliest and latest possible dates.
-- =================================================================
SELECT
    @MinDate = MIN(DateValue),
    @MaxDate = MAX(DateValue)
FROM (
    -- Get all purchase timestamps from the orders table
    SELECT [Order Date] AS DateValue FROM [DWH_Supply_Chain].silver.erp_order_headers
    UNION ALL
    -- Get all won dates from the deals table
    SELECT [shipping date] AS DateValue FROM [DWH_Supply_Chain].silver.erp_shipping
) AS AllDates;

-- =================================================================
-- Step 3: Create the dim_date table structure
-- =================================================================
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
    DELETE FROM gold.dim_date;

-- =================================================================
-- Step 4: Use a loop to populate the dim_date table using the variables
-- =================================================================
DECLARE @CurrentDate DATE = @MinDate;

WHILE @CurrentDate <= @MaxDate
BEGIN
    INSERT INTO gold.[dim_date] (
        date_key,
        full_date,
        date_number_of_week,
        day_name_of_week,
        day_number_of_month,
        month_name,
        month_number_of_year,
        [quarter],
        [year]
    )
    VALUES (
        CONVERT(INT, CONVERT(VARCHAR(8), @CurrentDate, 112)), -- Creates YYYYMMDD key
        @CurrentDate,
        DATEPART(weekday, @CurrentDate),
        DATENAME(weekday, @CurrentDate),
        DATEPART(day, @CurrentDate),
        DATENAME(month, @CurrentDate),
        DATEPART(month, @CurrentDate),
        DATEPART(quarter, @CurrentDate),
        DATEPART(year, @CurrentDate)
    );

    SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
END;
GO