/*
==========================================================
Perform detailed data-quality and relationship checks
on the SQL Server staging table.

Important:
    This script is diagnostic only.
    It does NOT modify or delete staging records.

Expected findings from Initial Data Profiling:

    Orders with multiple customers = 2
    Product IDs with multiple names = 32
    Product names with multiple IDs = 17

Expected clean checks:

    Exact duplicate rows = 0
    Missing values = 0
    Invalid sales = 0
    Invalid quantity = 0
    Invalid discounts = 0
    Ship date before order date = 0
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
-- 1.1. Validate Row_ID

SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT [Row_ID]) AS Unique_Row_IDs
FROM stg.Superstore_Raw;
GO

----------------------------------------------------------
-- 1.2. Look for duplicate Row IDs
SELECT
    [Row_ID],
    COUNT(*) AS Occurrences
FROM stg.Superstore_Raw
GROUP BY [Row_ID]
HAVING COUNT(*) > 1;
GO

----------------------------------------------------------
-- 2. Check empty strings and whitespace

SELECT
    SUM(CASE WHEN LTRIM(RTRIM([Order_ID])) = '' THEN 1 ELSE 0 END)
        AS Empty_Order_ID,

    SUM(CASE WHEN LTRIM(RTRIM([Customer_ID])) = '' THEN 1 ELSE 0 END)
        AS Empty_Customer_ID,

    SUM(CASE WHEN LTRIM(RTRIM([Customer_Name])) = '' THEN 1 ELSE 0 END)
        AS Empty_Customer_Name,

    SUM(CASE WHEN LTRIM(RTRIM([Product_ID])) = '' THEN 1 ELSE 0 END)
        AS Empty_Product_ID,

    SUM(CASE WHEN LTRIM(RTRIM([Product_Name])) = '' THEN 1 ELSE 0 END)
        AS Empty_Product_Name,

    SUM(CASE WHEN LTRIM(RTRIM([Category])) = '' THEN 1 ELSE 0 END)
        AS Empty_Category,

    SUM(CASE WHEN LTRIM(RTRIM([Sub_Category])) = '' THEN 1 ELSE 0 END)
        AS Empty_Sub_Category

FROM stg.Superstore_Raw;
GO

----------------------------------------------------------
-- 3. Check for unwanted leading/trailing spaces

SELECT
    SUM(
        CASE
            WHEN [Customer_Name] <> LTRIM(RTRIM([Customer_Name]))
            THEN 1
            ELSE 0
        END
    ) AS Customer_Name_With_Whitespace,

    SUM(
        CASE
            WHEN [Product_Name] <> LTRIM(RTRIM([Product_Name]))
            THEN 1
            ELSE 0
        END
    ) AS Product_Name_With_Whitespace,

    SUM(
        CASE
            WHEN [Category] <> LTRIM(RTRIM([Category]))
            THEN 1
            ELSE 0
        END
    ) AS Category_With_Whitespace,

    SUM(
        CASE
            WHEN [Sub_Category] <> LTRIM(RTRIM([Sub_Category]))
            THEN 1
            ELSE 0
        END
    ) AS Sub_Category_With_Whitespace

FROM stg.Superstore_Raw;
GO

----------------------------------------------------------
-- 4. Investigate Customer ID consistency

SELECT
    [Customer_ID],
    COUNT(DISTINCT [Customer_Name]) AS Customer_Name_Count,
    COUNT(DISTINCT [Segment]) AS Segment_Count
FROM stg.Superstore_Raw
GROUP BY [Customer_ID]
HAVING
    COUNT(DISTINCT [Customer_Name]) > 1
    OR
    COUNT(DISTINCT [Segment]) > 1;
GO

----------------------------------------------------------
-- 5. Confirm the Harry Olson situation

SELECT
    [Customer_Name],
    COUNT(DISTINCT [Customer_ID]) AS Customer_ID_Count
FROM stg.Superstore_Raw
GROUP BY [Customer_Name]
HAVING COUNT(DISTINCT [Customer_ID]) > 1
ORDER BY Customer_ID_Count DESC;
GO

----------------------------------------------------------
-- 6. Investigate Product ID consistency

SELECT
    [Product_ID],
    COUNT(DISTINCT [Product_Name]) AS Product_Name_Count,
    COUNT(DISTINCT [Category]) AS Category_Count,
    COUNT(DISTINCT [Sub_Category]) AS Sub_Category_Count
FROM stg.Superstore_Raw
GROUP BY [Product_ID]
HAVING
    COUNT(DISTINCT [Product_Name]) > 1
    OR
    COUNT(DISTINCT [Category]) > 1
    OR
    COUNT(DISTINCT [Sub_Category]) > 1
ORDER BY [Product_ID];
GO

----------------------------------------------------------
-- 7. Display the 32 product inconsistencies

SELECT
    [Product_ID],
    [Product_Name],
    [Category],
    [Sub_Category],
    COUNT(*) AS Transaction_Line_Count
FROM stg.Superstore_Raw
WHERE [Product_ID] IN
(
    SELECT [Product_ID]
    FROM stg.Superstore_Raw
    GROUP BY [Product_ID]
    HAVING COUNT(DISTINCT [Product_Name]) > 1
)
GROUP BY
    [Product_ID],
    [Product_Name],
    [Category],
    [Sub_Category]
ORDER BY
    [Product_ID],
    Transaction_Line_Count DESC,
    [Product_Name];
GO

----------------------------------------------------------
-- 8. Check Product ID --> Category

SELECT
    [Product_ID],
    COUNT(DISTINCT [Category]) AS Category_Count
FROM stg.Superstore_Raw
GROUP BY [Product_ID]
HAVING COUNT(DISTINCT [Category]) > 1;
GO

----------------------------------------------------------
-- 9. Check Product ID --> Sub-Category

SELECT
    [Product_ID],
    COUNT(DISTINCT [Sub_Category]) AS Sub_Category_Count
FROM stg.Superstore_Raw
GROUP BY [Product_ID]
HAVING COUNT(DISTINCT [Sub_Category]) > 1;
GO

----------------------------------------------------------
-- 10. Check Product Name --> Product ID

SELECT
    [Product_Name],
    COUNT(DISTINCT [Product_ID]) AS Product_ID_Count
FROM stg.Superstore_Raw
GROUP BY [Product_Name]
HAVING COUNT(DISTINCT [Product_ID]) > 1
ORDER BY Product_ID_Count DESC;
GO

----------------------------------------------------------
-- 11. Investigate the 2 problematic orders

SELECT
    [Order_ID],
    COUNT(DISTINCT [Customer_ID]) AS Customer_Count
FROM stg.Superstore_Raw
GROUP BY [Order_ID]
HAVING COUNT(DISTINCT [Customer_ID]) > 1;
GO

SELECT *
FROM stg.Superstore_Raw
WHERE [Order_ID] IN
(
    SELECT [Order_ID]
    FROM stg.Superstore_Raw
    GROUP BY [Order_ID]
    HAVING COUNT(DISTINCT [Customer_ID]) > 1
)
ORDER BY
    [Order_ID],
    [Row_ID];
GO

----------------------------------------------------------
-- 12. Check Order ID --> Order Date

SELECT
    [Order_ID],
    COUNT(DISTINCT [Order_Date]) AS Order_Date_Count
FROM stg.Superstore_Raw
GROUP BY [Order_ID]
HAVING COUNT(DISTINCT [Order_Date]) > 1;
GO

----------------------------------------------------------
-- 13. Check Order ID --> Ship Date

SELECT
    [Order_ID],
    COUNT(DISTINCT [Ship_Date]) AS Ship_Date_Count
FROM stg.Superstore_Raw
GROUP BY [Order_ID]
HAVING COUNT(DISTINCT [Ship_Date]) > 1;
GO

----------------------------------------------------------
-- 14. Recheck numerical validity 

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
            WHEN [Discount] < 0
              OR [Discount] > 1
            THEN 1
            ELSE 0
        END
    ) AS Invalid_Discount,

    SUM(
        CASE
            WHEN [Profit] < 0 THEN 1
            ELSE 0
        END
    ) AS Negative_Profit

FROM stg.Superstore_Raw;
GO

----------------------------------------------------------
-- 15. Check shipping logic

SELECT
    COUNT(*) AS Invalid_Shipment_Dates
FROM stg.Superstore_Raw
WHERE [Ship_Date] < [Order_Date];
GO

SELECT
    MIN(DATEDIFF(DAY, [Order_Date], [Ship_Date]))
        AS Minimum_Shipping_Days,

    AVG(
        CAST(
            DATEDIFF(DAY, [Order_Date], [Ship_Date])
            AS DECIMAL(10,2)
        )
    ) AS Average_Shipping_Days,

    MAX(DATEDIFF(DAY, [Order_Date], [Ship_Date]))
        AS Maximum_Shipping_Days

FROM stg.Superstore_Raw;
GO

----------------------------------------------------------
-- 16. Check the future dates

SELECT
    MIN([Order_Date]) AS First_Future_Order_Date,
    MAX([Order_Date]) AS Last_Future_Order_Date,
    COUNT(*) AS Future_Dated_Rows
FROM stg.Superstore_Raw
WHERE [Order_Date] > CAST(GETDATE() AS DATE);
GO

----------------------------------------------------------
-- 17. Check geographic values

SELECT
    COUNT(DISTINCT [Country_Region]) AS Countries,
    COUNT(DISTINCT [Region]) AS Regions,
    COUNT(DISTINCT [State_Province]) AS States_Provinces,
    COUNT(DISTINCT [City]) AS Cities,
    COUNT(DISTINCT [Postal_Code]) AS Postal_Codes
FROM stg.Superstore_Raw;
GO

----------------------------------------------------------
-- 18. Verify the categorical values

SELECT DISTINCT [Ship_Mode]
FROM stg.Superstore_Raw
ORDER BY [Ship_Mode];
GO

SELECT DISTINCT [Segment]
FROM stg.Superstore_Raw
ORDER BY [Segment];
GO

SELECT DISTINCT [Category]
FROM stg.Superstore_Raw
ORDER BY [Category];
GO

