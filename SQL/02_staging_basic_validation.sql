/*
==========================================================
Validate the raw Superstore data after import
into SQL Server staging.


Expected values from Initial Data Profiling:
    Rows                     = 10,194
    Columns                  = 21
    Exact duplicate rows     = 0
    Missing cells             = 0
    Unique orders             = 5,111
    Unique customers          = 804
    Unique products           = 1,862

Important:
    The SQL staging table uses underscores in column names.
    Example:
        CSV: Order ID
        SQL: Order_ID
==========================================================
*/


----------------------------------------------------------
-- 0. Select the project database

USE Syntecxhub_Sales_Performance;
GO


----------------------------------------------------------
-- 0.1 Confirm the current database

SELECT
    DB_NAME() AS Current_Database;
GO


----------------------------------------------------------
-- 0.2 Confirm the staging table

SELECT
    OBJECT_ID(N'stg.Superstore_Raw', N'U') AS Staging_Table_Object_ID;
GO


----------------------------------------------------------
-- 1. Row count
/*
    Expected result:
        10,194
*/

SELECT
    COUNT(*) AS Row_Count
FROM stg.Superstore_Raw;
GO


----------------------------------------------------------
-- 2. Preview the imported data
/*
    Displays a sample of the imported staging records.
*/

SELECT TOP 10 *
FROM stg.Superstore_Raw;
GO


----------------------------------------------------------
-- 3. Column count
/*
    Expected result: 21
*/

SELECT
    COUNT(*) AS Column_Count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Superstore_Raw';
GO


----------------------------------------------------------
-- 4. Display the actual SQL column names
/*
    This confirms the exact column names created during
    the CSV import.
*/

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Superstore_Raw'
ORDER BY ORDINAL_POSITION;
GO


----------------------------------------------------------
-- 5. Check important identifiers
/*
    Expected:
        Total Rows        = 10,194
        Unique Row IDs    = 10,194
        Unique Orders     = 5,111
        Unique Customers  = 804
        Unique Products   = 1,862
*/

SELECT
    COUNT(*) AS Total_Rows,

    COUNT(DISTINCT [Row_ID]) AS Unique_Row_IDs,

    COUNT(DISTINCT [Order_ID]) AS Unique_Orders,

    COUNT(DISTINCT [Customer_ID]) AS Unique_Customers,

    COUNT(DISTINCT [Product_ID]) AS Unique_Products

FROM stg.Superstore_Raw;
GO


----------------------------------------------------------
-- 6. Check the date range
/*
    Expected:

    Order Date:
        Minimum = 2023-01-03
        Maximum = 2026-12-30

    Ship Date:
        Minimum = 2023-01-07
        Maximum = 2027-01-05
*/

SELECT
    MIN([Order_Date]) AS Minimum_Order_Date,

    MAX([Order_Date]) AS Maximum_Order_Date,

    MIN([Ship_Date]) AS Minimum_Ship_Date,

    MAX([Ship_Date]) AS Maximum_Ship_Date

FROM stg.Superstore_Raw;
GO


----------------------------------------------------------
-- 7. Check sales / quantity / profit
----------------------------------------------------------
/*
    These totals will be compared with the Python
    Initial Data Profiling baseline.
*/

SELECT
    SUM([Sales]) AS Total_Sales,

    SUM([Quantity]) AS Total_Quantity,

    SUM([Profit]) AS Total_Profit

FROM stg.Superstore_Raw;
GO


----------------------------------------------------------
-- 8. Check exact duplicate rows
/*
    An exact duplicate means that every field across
    the 21 columns is identical.

    Expected result:
        0
*/

SELECT
    COUNT(*) AS Exact_Duplicate_Groups

FROM
(
    SELECT

        [Row_ID],
        [Order_ID],
        [Order_Date],
        [Ship_Date],
        [Ship_Mode],
        [Customer_ID],
        [Customer_Name],
        [Segment],
        [Country_Region],
        [City],
        [State_Province],
        [Postal_Code],
        [Region],
        [Product_ID],
        [Category],
        [Sub_Category],
        [Product_Name],
        [Sales],
        [Quantity],
        [Discount],
        [Profit],

        COUNT(*) AS Duplicate_Count

    FROM stg.Superstore_Raw

    GROUP BY

        [Row_ID],
        [Order_ID],
        [Order_Date],
        [Ship_Date],
        [Ship_Mode],
        [Customer_ID],
        [Customer_Name],
        [Segment],
        [Country_Region],
        [City],
        [State_Province],
        [Postal_Code],
        [Region],
        [Product_ID],
        [Category],
        [Sub_Category],
        [Product_Name],
        [Sales],
        [Quantity],
        [Discount],
        [Profit]

    HAVING COUNT(*) > 1

) AS duplicates;
GO


----------------------------------------------------------
-- 9. Check NULL values
/*
    Python profiling found no missing values.

    Expected:
        Every result = 0
*/

SELECT

    SUM(CASE WHEN [Row_ID] IS NULL THEN 1 ELSE 0 END)
        AS Row_ID_NULLs,

    SUM(CASE WHEN [Order_ID] IS NULL THEN 1 ELSE 0 END)
        AS Order_ID_NULLs,

    SUM(CASE WHEN [Order_Date] IS NULL THEN 1 ELSE 0 END)
        AS Order_Date_NULLs,

    SUM(CASE WHEN [Ship_Date] IS NULL THEN 1 ELSE 0 END)
        AS Ship_Date_NULLs,

    SUM(CASE WHEN [Ship_Mode] IS NULL THEN 1 ELSE 0 END)
        AS Ship_Mode_NULLs,

    SUM(CASE WHEN [Customer_ID] IS NULL THEN 1 ELSE 0 END)
        AS Customer_ID_NULLs,

    SUM(CASE WHEN [Customer_Name] IS NULL THEN 1 ELSE 0 END)
        AS Customer_Name_NULLs,

    SUM(CASE WHEN [Segment] IS NULL THEN 1 ELSE 0 END)
        AS Segment_NULLs,

    SUM(CASE WHEN [Country_Region] IS NULL THEN 1 ELSE 0 END)
        AS Country_Region_NULLs,

    SUM(CASE WHEN [City] IS NULL THEN 1 ELSE 0 END)
        AS City_NULLs,

    SUM(CASE WHEN [State_Province] IS NULL THEN 1 ELSE 0 END)
        AS State_Province_NULLs,

    SUM(CASE WHEN [Postal_Code] IS NULL THEN 1 ELSE 0 END)
        AS Postal_Code_NULLs,

    SUM(CASE WHEN [Region] IS NULL THEN 1 ELSE 0 END)
        AS Region_NULLs,

    SUM(CASE WHEN [Product_ID] IS NULL THEN 1 ELSE 0 END)
        AS Product_ID_NULLs,

    SUM(CASE WHEN [Category] IS NULL THEN 1 ELSE 0 END)
        AS Category_NULLs,

    SUM(CASE WHEN [Sub_Category] IS NULL THEN 1 ELSE 0 END)
        AS Sub_Category_NULLs,

    SUM(CASE WHEN [Product_Name] IS NULL THEN 1 ELSE 0 END)
        AS Product_Name_NULLs,

    SUM(CASE WHEN [Sales] IS NULL THEN 1 ELSE 0 END)
        AS Sales_NULLs,

    SUM(CASE WHEN [Quantity] IS NULL THEN 1 ELSE 0 END)
        AS Quantity_NULLs,

    SUM(CASE WHEN [Discount] IS NULL THEN 1 ELSE 0 END)
        AS Discount_NULLs,

    SUM(CASE WHEN [Profit] IS NULL THEN 1 ELSE 0 END)
        AS Profit_NULLs

FROM stg.Superstore_Raw;
GO


----------------------------------------------------------
-- 10. Check numerical validity
/*
    Expected based on Python profiling:

        Negative Sales          = 0
        Non-positive Quantity   = 0
        Discount < 0            = 0
        Discount > 1            = 0
        Negative Profit         = 1,901

    IMPORTANT:
        Negative Profit is not treated as a data-quality
        error. It represents a loss-making transaction.
*/

SELECT

    SUM(
        CASE
            WHEN [Sales] < 0 THEN 1
            ELSE 0
        END
    ) AS Negative_Sales,

    SUM(
        CASE
            WHEN [Quantity] <= 0 THEN 1
            ELSE 0
        END
    ) AS Non_Positive_Quantity,

    SUM(
        CASE
            WHEN [Discount] < 0 THEN 1
            ELSE 0
        END
    ) AS Discount_Below_Zero,

    SUM(
        CASE
            WHEN [Discount] > 1 THEN 1
            ELSE 0
        END
    ) AS Discount_Above_One,

    SUM(
        CASE
            WHEN [Profit] < 0 THEN 1
            ELSE 0
        END
    ) AS Negative_Profit

FROM stg.Superstore_Raw;
GO


----------------------------------------------------------
-- 11. Validate Order Date vs Ship Date
/*
    A shipment should not occur before its corresponding
    order.

    Expected result: 0
*/

SELECT
    COUNT(*) AS Invalid_Shipping_Dates

FROM stg.Superstore_Raw

WHERE [Ship_Date] < [Order_Date];
GO


----------------------------------------------------------
-- 12. Shipping duration summary
/*
    Expected approximately:

        Minimum = 0 days
        Average = 3.96 days
        Maximum = 11 days
*/

SELECT

    MIN(
        DATEDIFF(
            DAY,
            [Order_Date],
            [Ship_Date]
        )
    ) AS Minimum_Shipping_Days,

    AVG(
        CAST(
            DATEDIFF(
                DAY,
                [Order_Date],
                [Ship_Date]
            )
            AS DECIMAL(10,2)
        )
    ) AS Average_Shipping_Days,

    MAX(
        DATEDIFF(
            DAY,
            [Order_Date],
            [Ship_Date]
        )
    ) AS Maximum_Shipping_Days

FROM stg.Superstore_Raw;
GO


----------------------------------------------------------
-- 13. Display actual SQL data types
/*
    This verifies that the imported columns have the
    intended SQL data types.

    Important:
        Postal_Code should be text.
        Order_Date and Ship_Date should be DATE.
*/

SELECT

    ORDINAL_POSITION,

    COLUMN_NAME,

    DATA_TYPE,

    CHARACTER_MAXIMUM_LENGTH,

    NUMERIC_PRECISION,

    NUMERIC_SCALE

FROM INFORMATION_SCHEMA.COLUMNS

WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'Superstore_Raw'

ORDER BY ORDINAL_POSITION;
GO
