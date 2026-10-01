/*
==========================================================
Create the clean dimensional model from the staging table.

Important:
    The staging table is never modified by this script.
==========================================================
*/

USE Syntecxhub_Sales_Performance;
GO


----------------------------------------------------------
-- 1. Create the dimension schema

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dim'
)
BEGIN
    EXEC('CREATE SCHEMA dim');
END;
GO


----------------------------------------------------------
-- 2. Create the fact schema

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'fact'
)
BEGIN
    EXEC('CREATE SCHEMA fact');
END;
GO

----------------------------------------------------------
-- 3. Create Customer Dimension


CREATE TABLE dim.Customer
(
    Customer_Key INT IDENTITY(1,1) NOT NULL,
    Customer_ID VARCHAR(20) NOT NULL,
    Customer_Name NVARCHAR(100) NOT NULL,
    Segment VARCHAR(30) NOT NULL,

    CONSTRAINT PK_dim_Customer
        PRIMARY KEY (Customer_Key),

    CONSTRAINT UQ_dim_Customer_Customer_ID
        UNIQUE (Customer_ID)
);
GO

----------------------------------------------------------
-- 4. Populate Customer Dimension

INSERT INTO dim.Customer
(
    Customer_ID,
    Customer_Name,
    Segment
)
SELECT DISTINCT
    LTRIM(RTRIM([Customer_ID])),
    LTRIM(RTRIM([Customer_Name])),
    LTRIM(RTRIM([Segment]))
FROM stg.Superstore_Raw;
GO


SELECT COUNT(*) AS Customer_Count
FROM dim.Customer;


SELECT TOP 20 *
FROM dim.Customer
ORDER BY Customer_Key;

----------------------------------------------------------
-- 5. Create Product Dimension

CREATE TABLE dim.Product
(
    Product_Key INT IDENTITY(1,1) NOT NULL,
    Product_ID VARCHAR(30) NOT NULL,
    Product_Name NVARCHAR(255) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Sub_Category VARCHAR(50) NOT NULL,
    Product_Name_Variants INT NOT NULL,
    Product_Data_Quality_Status VARCHAR(50) NOT NULL,

    CONSTRAINT PK_dim_Product
        PRIMARY KEY (Product_Key),

    CONSTRAINT UQ_dim_Product_Product_ID
        UNIQUE (Product_ID)
);
GO

----------------------------------------------------------
-- 6. Populate Product Dimension
-- Rule: Most frequent Product Name = canonical name
-- Tie: Alphabetically first trimmed Product Name


WITH Product_Name_Frequency AS
(
    SELECT
        [Product_ID],
        LTRIM(RTRIM([Product_Name])) AS Product_Name,
        COUNT(*) AS Name_Frequency

    FROM stg.Superstore_Raw

    GROUP BY
        [Product_ID],
        LTRIM(RTRIM([Product_Name]))
),

Ranked_Product_Names AS
(
    SELECT
        [Product_ID],
        Product_Name,
        Name_Frequency,

        COUNT(*) OVER
        (
            PARTITION BY [Product_ID]
        ) AS Product_Name_Variants,

        ROW_NUMBER() OVER
        (
            PARTITION BY [Product_ID]

            ORDER BY
                Name_Frequency DESC,
                Product_Name ASC

        ) AS Name_Rank

    FROM Product_Name_Frequency
),

Product_Classification AS
(
    SELECT
        [Product_ID],

        MIN(LTRIM(RTRIM([Category])))
            AS Category,

        MIN(LTRIM(RTRIM([Sub_Category])))
            AS Sub_Category

    FROM stg.Superstore_Raw

    GROUP BY
        [Product_ID]
)

INSERT INTO dim.Product
(
    Product_ID,
    Product_Name,
    Category,
    Sub_Category,
    Product_Name_Variants,
    Product_Data_Quality_Status
)

SELECT
    r.[Product_ID],
    r.Product_Name,
    c.Category,
    c.Sub_Category,
    r.Product_Name_Variants,

    CASE
        WHEN r.Product_Name_Variants > 1
            THEN 'Standardized_Multiple_Names'
        ELSE 'Consistent'
    END

FROM Ranked_Product_Names r

INNER JOIN Product_Classification c
    ON r.[Product_ID] = c.[Product_ID]

WHERE r.Name_Rank = 1;
GO

-- Validate the Product dimension
SELECT COUNT(*) AS Product_Count
FROM dim.Product;


SELECT
    Product_Data_Quality_Status,
    COUNT(*) AS Product_Count
FROM dim.Product
GROUP BY Product_Data_Quality_Status;


SELECT *
FROM dim.Product
WHERE Product_Data_Quality_Status =
      'Standardized_Multiple_Names'
ORDER BY Product_ID;

----------------------------------------------------------
-- 7. Create Geography Dimension

CREATE TABLE dim.Geography
(
    Geography_Key INT IDENTITY(1,1) NOT NULL,
    Country_Region VARCHAR(50) NOT NULL,
    Region VARCHAR(20) NOT NULL,
    State_Province NVARCHAR(100) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    Postal_Code NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_dim_Geography
        PRIMARY KEY (Geography_Key),

    CONSTRAINT UQ_dim_Geography
        UNIQUE
        (
            Country_Region,
            Region,
            State_Province,
            City,
            Postal_Code
        )
);
GO

----------------------------------------------------------
-- 8. Populate Geography Dimension

INSERT INTO dim.Geography
(
    Country_Region,
    Region,
    State_Province,
    City,
    Postal_Code
)

SELECT DISTINCT

    LTRIM(RTRIM([Country_Region])),
    LTRIM(RTRIM([Region])),
    LTRIM(RTRIM([State_Province])),
    LTRIM(RTRIM([City])),
    LTRIM(RTRIM([Postal_Code]))

FROM stg.Superstore_Raw;
GO


SELECT COUNT(*) AS Geography_Count
FROM dim.Geography;

----------------------------------------------------------
-- 9. Create Ship Mode Dimension

CREATE TABLE dim.Ship_Mode
(
    Ship_Mode_Key INT IDENTITY(1,1) NOT NULL,
    Ship_Mode VARCHAR(30) NOT NULL,

    CONSTRAINT PK_dim_Ship_Mode
        PRIMARY KEY (Ship_Mode_Key),

    CONSTRAINT UQ_dim_Ship_Mode
        UNIQUE (Ship_Mode)
);
GO

----------------------------------------------------------
-- 10. Populate Ship Mode Dimension


INSERT INTO dim.Ship_Mode
(
    Ship_Mode
)

SELECT DISTINCT
    LTRIM(RTRIM([Ship_Mode]))

FROM stg.Superstore_Raw;
GO


SELECT *
FROM dim.Ship_Mode
ORDER BY Ship_Mode_Key;