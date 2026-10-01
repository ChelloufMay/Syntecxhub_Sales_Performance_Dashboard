/*
==========================================================
Create a calendar dimension covering all dates needed
    by the sales fact table.

Source date range:
    Minimum = minimum Order Date
    Maximum = maximum Ship Date
==========================================================
*/

USE Syntecxhub_Sales_Performance;
GO


----------------------------------------------------------
-- 1. Create Date Dimension

CREATE TABLE dim.Date
(
    Date_Key INT NOT NULL,
    Full_Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month_Number INT NOT NULL,
    Month_Name VARCHAR(20) NOT NULL,
    Year_Month VARCHAR(7) NOT NULL,
    Day_Number INT NOT NULL,
    Day_Name VARCHAR(20) NOT NULL,
    Week_Number INT NOT NULL,
    Is_Weekend BIT NOT NULL,

    CONSTRAINT PK_dim_Date
        PRIMARY KEY (Date_Key),

    CONSTRAINT UQ_dim_Date_Full_Date
        UNIQUE (Full_Date)
);
GO

----------------------------------------------------------
-- 2. Generate calendar dates

DECLARE @Min_Date DATE;
DECLARE @Max_Date DATE;

SELECT
    @Min_Date = MIN([Order_Date]),
    @Max_Date = MAX([Ship_Date])
FROM stg.Superstore_Raw;


;WITH Date_Series AS
(
    SELECT
        @Min_Date AS Full_Date

    UNION ALL

    SELECT
        DATEADD(DAY, 1, Full_Date)

    FROM Date_Series

    WHERE Full_Date < @Max_Date
)

INSERT INTO dim.Date
(
    Date_Key,
    Full_Date,
    Year,
    Quarter,
    Month_Number,
    Month_Name,
    Year_Month,
    Day_Number,
    Day_Name,
    Week_Number,
    Is_Weekend
)

SELECT

    CONVERT(
        INT,
        CONVERT(CHAR(8), Full_Date, 112)
    ) AS Date_Key,

    Full_Date,

    YEAR(Full_Date),

    DATEPART(QUARTER, Full_Date),

    MONTH(Full_Date),

    DATENAME(MONTH, Full_Date),

    CONVERT(CHAR(7), Full_Date, 120),

    DAY(Full_Date),

    DATENAME(WEEKDAY, Full_Date),

    DATEPART(WEEK, Full_Date),

    CASE
        WHEN DATEPART(WEEKDAY, Full_Date) IN (1, 7)
            THEN 1
        ELSE 0
    END

FROM Date_Series

OPTION (MAXRECURSION 0);
GO


-- Validate the date dimension

SELECT
    COUNT(*) AS Date_Count,
    MIN(Full_Date) AS Minimum_Date,
    MAX(Full_Date) AS Maximum_Date
FROM dim.Date;


SELECT TOP 20 *
FROM dim.Date
ORDER BY Full_Date;


SELECT TOP 20 *
FROM dim.Date
ORDER BY Full_Date DESC;