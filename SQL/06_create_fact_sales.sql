/*
==========================================================
Create and populate the clean Sales fact table.

Grain:
    One row per order-product transaction line.
==========================================================
*/

USE Syntecxhub_Sales_Performance;
GO

----------------------------------------------------------
-- 1. Validate all dimension lookups
-- LEFT JOIN makes missing dimension matches visible.

SELECT

    COUNT(*) AS Total_Staging_Rows,

    SUM(
        CASE
            WHEN c.Customer_Key IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Missing_Customer_Matches,

    SUM(
        CASE
            WHEN p.Product_Key IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Missing_Product_Matches,

    SUM(
        CASE
            WHEN g.Geography_Key IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Missing_Geography_Matches,

    SUM(
        CASE
            WHEN sm.Ship_Mode_Key IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Missing_Ship_Mode_Matches,

    SUM(
        CASE
            WHEN od.Date_Key IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Missing_Order_Date_Matches,

    SUM(
        CASE
            WHEN sd.Date_Key IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Missing_Ship_Date_Matches

FROM stg.Superstore_Raw s

LEFT JOIN dim.Customer c
    ON c.Customer_ID =
       LTRIM(RTRIM(s.Customer_ID))

LEFT JOIN dim.Product p
    ON p.Product_ID =
       LTRIM(RTRIM(s.Product_ID))

LEFT JOIN dim.Geography g
    ON g.Country_Region =
       LTRIM(RTRIM(s.Country_Region))
   AND g.Region =
       LTRIM(RTRIM(s.Region))
   AND g.State_Province =
       LTRIM(RTRIM(s.State_Province))
   AND g.City =
       LTRIM(RTRIM(s.City))
   AND g.Postal_Code =
       LTRIM(RTRIM(s.Postal_Code))

LEFT JOIN dim.Ship_Mode sm
    ON sm.Ship_Mode =
       LTRIM(RTRIM(s.Ship_Mode))

LEFT JOIN dim.Date od
    ON od.Full_Date = s.Order_Date

LEFT JOIN dim.Date sd
    ON sd.Full_Date = s.Ship_Date;
GO

----------------------------------------------------------
-- Check the resulting joined row count
SELECT
    COUNT(*) AS Joined_Row_Count,
    COUNT(DISTINCT s.Row_ID) AS Unique_Joined_Row_IDs

FROM stg.Superstore_Raw s

INNER JOIN dim.Customer c
    ON c.Customer_ID =
       LTRIM(RTRIM(s.Customer_ID))

INNER JOIN dim.Product p
    ON p.Product_ID =
       LTRIM(RTRIM(s.Product_ID))

INNER JOIN dim.Geography g
    ON g.Country_Region =
       LTRIM(RTRIM(s.Country_Region))
   AND g.Region =
       LTRIM(RTRIM(s.Region))
   AND g.State_Province =
       LTRIM(RTRIM(s.State_Province))
   AND g.City =
       LTRIM(RTRIM(s.City))
   AND g.Postal_Code =
       LTRIM(RTRIM(s.Postal_Code))

INNER JOIN dim.Ship_Mode sm
    ON sm.Ship_Mode =
       LTRIM(RTRIM(s.Ship_Mode))

INNER JOIN dim.Date od
    ON od.Full_Date = s.Order_Date

INNER JOIN dim.Date sd
    ON sd.Full_Date = s.Ship_Date;
GO

----------------------------------------------------------
-- 2. Create Sales Fact Table
----------------------------------------------------------

CREATE TABLE fact.Sales
(
    Row_ID INT NOT NULL,

    Order_ID VARCHAR(20) NOT NULL,

    Order_Date_Key INT NOT NULL,
    Ship_Date_Key INT NOT NULL,

    Customer_Key INT NOT NULL,
    Product_Key INT NOT NULL,
    Geography_Key INT NOT NULL,
    Ship_Mode_Key INT NOT NULL,

    Sales DECIMAL(18,3) NOT NULL,
    Quantity INT NOT NULL,
    Discount DECIMAL(5,3) NOT NULL,
    Profit DECIMAL(18,4) NOT NULL,

    Shipping_Days INT NOT NULL,

    Order_Customer_Anomaly_Flag BIT NOT NULL,

    CONSTRAINT PK_fact_Sales
        PRIMARY KEY (Row_ID),

    CONSTRAINT FK_fact_Sales_Customer
        FOREIGN KEY (Customer_Key)
        REFERENCES dim.Customer(Customer_Key),

    CONSTRAINT FK_fact_Sales_Product
        FOREIGN KEY (Product_Key)
        REFERENCES dim.Product(Product_Key),

    CONSTRAINT FK_fact_Sales_Geography
        FOREIGN KEY (Geography_Key)
        REFERENCES dim.Geography(Geography_Key),

    CONSTRAINT FK_fact_Sales_Ship_Mode
        FOREIGN KEY (Ship_Mode_Key)
        REFERENCES dim.Ship_Mode(Ship_Mode_Key),

    CONSTRAINT FK_fact_Sales_Order_Date
        FOREIGN KEY (Order_Date_Key)
        REFERENCES dim.Date(Date_Key),

    CONSTRAINT FK_fact_Sales_Ship_Date
        FOREIGN KEY (Ship_Date_Key)
        REFERENCES dim.Date(Date_Key),

    CONSTRAINT CK_fact_Sales_Sales
        CHECK (Sales >= 0),

    CONSTRAINT CK_fact_Sales_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_fact_Sales_Discount
        CHECK (Discount >= 0 AND Discount <= 1)
);
GO

----------------------------------------------------------
-- 3. Populate Sales Fact Table

INSERT INTO fact.Sales
(
    Row_ID,
    Order_ID, -- degenerate dimension
    Order_Date_Key,
    Ship_Date_Key,
    Customer_Key,
    Product_Key,
    Geography_Key,
    Ship_Mode_Key,
    Sales,
    Quantity,
    Discount,
    Profit,
    Shipping_Days,
    Order_Customer_Anomaly_Flag -- when there is an anomaly, the fact table records it
)

SELECT

    s.Row_ID,

    LTRIM(RTRIM(s.Order_ID)),

    od.Date_Key,

    sd.Date_Key,

    c.Customer_Key,

    p.Product_Key,

    g.Geography_Key,

    sm.Ship_Mode_Key,

    s.Sales,

    s.Quantity,

    s.Discount,

    s.Profit,

    DATEDIFF(
        DAY,
        s.Order_Date,
        s.Ship_Date
    ),

    CASE
        WHEN Order_Customer_Info.Customer_Count > 1
            THEN 1
        ELSE 0
    END

FROM stg.Superstore_Raw s

INNER JOIN dim.Customer c
    ON c.Customer_ID =
       LTRIM(RTRIM(s.Customer_ID))

INNER JOIN dim.Product p
    ON p.Product_ID =
       LTRIM(RTRIM(s.Product_ID))

INNER JOIN dim.Geography g
    ON g.Country_Region =
       LTRIM(RTRIM(s.Country_Region))
   AND g.Region =
       LTRIM(RTRIM(s.Region))
   AND g.State_Province =
       LTRIM(RTRIM(s.State_Province))
   AND g.City =
       LTRIM(RTRIM(s.City))
   AND g.Postal_Code =
       LTRIM(RTRIM(s.Postal_Code))

INNER JOIN dim.Ship_Mode sm
    ON sm.Ship_Mode =
       LTRIM(RTRIM(s.Ship_Mode))

INNER JOIN dim.Date od
    ON od.Full_Date = s.Order_Date

INNER JOIN dim.Date sd
    ON sd.Full_Date = s.Ship_Date

INNER JOIN
(
    SELECT
        [Order_ID],
        COUNT(DISTINCT [Customer_ID]) AS Customer_Count
    FROM stg.Superstore_Raw
    GROUP BY [Order_ID]
) AS Order_Customer_Info

    ON Order_Customer_Info.Order_ID =
       s.Order_ID;
GO