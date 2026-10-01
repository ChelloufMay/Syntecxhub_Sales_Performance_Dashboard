/*
==========================================================
Create the project database and staging schema.

==========================================================
*/

-- Create the project database
IF DB_ID('Syntecxhub_Sales_Performance') IS NULL
BEGIN
    CREATE DATABASE Syntecxhub_Sales_Performance;
END;
GO


-- Switch to the project database
USE Syntecxhub_Sales_Performance;
GO


-- Create a dedicated staging schema
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END;
GO