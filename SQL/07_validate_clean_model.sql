/*
==========================================================
Validate the completed dimensional model and compare
it against the original profiling baseline.
==========================================================
*/

USE Syntecxhub_Sales_Performance;
GO

----------------------------------------------------------
-- 1. Dimension row counts

SELECT 'dim.Customer' AS Table_Name,
       COUNT(*) AS Row_Count
FROM dim.Customer

UNION ALL

SELECT 'dim.Product',
       COUNT(*)
FROM dim.Product

UNION ALL

SELECT 'dim.Geography',
       COUNT(*)
FROM dim.Geography

UNION ALL

SELECT 'dim.Ship_Mode',
       COUNT(*)
FROM dim.Ship_Mode

UNION ALL

SELECT 'dim.Date',
       COUNT(*)
FROM dim.Date;
GO

----------------------------------------------------------
-- 2. Fact row count

SELECT
    COUNT(*) AS Fact_Row_Count,
    COUNT(DISTINCT Row_ID) AS Unique_Row_IDs,
    COUNT(DISTINCT Order_ID) AS Unique_Orders
FROM fact.Sales;
GO

----------------------------------------------------------
-- 3. Fact business totals

SELECT

    SUM(Sales) AS Total_Sales,

    SUM(Quantity) AS Total_Quantity,

    SUM(Profit) AS Total_Profit

FROM fact.Sales;
GO

----------------------------------------------------------
-- Check unique customers and products represented in the fact

SELECT
    COUNT(DISTINCT Customer_Key) AS Customers_In_Fact,
    COUNT(DISTINCT Product_Key) AS Products_In_Fact,
    COUNT(DISTINCT Geography_Key) AS Geographies_In_Fact,
    COUNT(DISTINCT Ship_Mode_Key) AS Ship_Modes_In_Fact
FROM fact.Sales;
GO

----------------------------------------------------------
-- 4. Validate multi-customer order anomalies

SELECT
    COUNT(DISTINCT Order_ID) AS Anomalous_Orders
FROM fact.Sales
WHERE Order_Customer_Anomaly_Flag = 1;
GO


SELECT DISTINCT
    Order_ID
FROM fact.Sales
WHERE Order_Customer_Anomaly_Flag = 1
ORDER BY Order_ID;
GO

----------------------------------------------------------
-- 5. Validate negative-profit records

SELECT
    COUNT(*) AS Negative_Profit_Rows,
    SUM(Profit) AS Total_Profit
FROM fact.Sales
WHERE Profit < 0;
GO

----------------------------------------------------------
-- 6. Validate standardized Product IDs

SELECT
    Product_Data_Quality_Status,
    COUNT(*) AS Product_Count
FROM dim.Product
GROUP BY Product_Data_Quality_Status;
GO


SELECT
    Product_ID,
    Product_Name,
    Category,
    Sub_Category,
    Product_Name_Variants,
    Product_Data_Quality_Status
FROM dim.Product
WHERE Product_Name_Variants > 1
ORDER BY Product_ID;
GO

----------------------------------------------------------
-- 7. Validate Order Date coverage

SELECT
    MIN(d.Full_Date) AS First_Order_Date,
    MAX(d.Full_Date) AS Last_Order_Date
FROM fact.Sales f
INNER JOIN dim.Date d
    ON f.Order_Date_Key = d.Date_Key;
GO

----------------------------------------------------------
-- 8. Validate Ship Date coverage

SELECT
    MIN(d.Full_Date) AS First_Ship_Date,
    MAX(d.Full_Date) AS Last_Ship_Date
FROM fact.Sales f
INNER JOIN dim.Date d
    ON f.Ship_Date_Key = d.Date_Key;
GO

----------------------------------------------------------
-- 9. Validate shipping duration

SELECT

    MIN(Shipping_Days) AS Minimum_Shipping_Days,

    AVG(
        CAST(Shipping_Days AS DECIMAL(10,2))
    ) AS Average_Shipping_Days,

    MAX(Shipping_Days) AS Maximum_Shipping_Days

FROM fact.Sales;
GO

----------------------------------------------------------
-- 10. Referential integrity verification
-- The foreign keys already prevent invalid references from being inserted. 
-- This is useful to demonstrate that the model contains no orphan keys.

SELECT
    COUNT(*) AS Customer_Orphans
FROM fact.Sales f
LEFT JOIN dim.Customer c
    ON f.Customer_Key = c.Customer_Key
WHERE c.Customer_Key IS NULL;
GO


SELECT
    COUNT(*) AS Product_Orphans
FROM fact.Sales f
LEFT JOIN dim.Product p
    ON f.Product_Key = p.Product_Key
WHERE p.Product_Key IS NULL;
GO


SELECT
    COUNT(*) AS Geography_Orphans
FROM fact.Sales f
LEFT JOIN dim.Geography g
    ON f.Geography_Key = g.Geography_Key
WHERE g.Geography_Key IS NULL;
GO