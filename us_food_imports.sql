-- SQL Script for US Food Imports Data Cleaning and Setup
-- Author: Von Ellesse M. Lanot
-- Date: 2025-06-03 
-- Purpose: This script sets up the MySQL database, performs initial data inspection,
--          classifies data types, and creates cleaned, specialized tables for analysis.

/*
--------------------------------------------------------------------------------
SECTION 1: INSPECTION OF DATA
--------------------------------------------------------------------------------
*/

SELECT * FROM us_food_imports_db.us_food_imports;

-- 1. Check Table Structure (Column Names and Data Types)
DESCRIBE us_food_imports_db.us_food_imports;

-- 2. View a Sample of the Data
SELECT *
FROM us_food_imports_db.us_food_imports
LIMIT 10;

-- 3. Confirm All Unique Units of Measure (UOM)
SELECT DISTINCT UOM
FROM us_food_imports_db.us_food_imports;

-- 4. Confirm All Unique Countries/Aggregates (Country)
SELECT DISTINCT Country
FROM us_food_imports_db.us_food_imports
ORDER BY Country;

-- 5. Confirm Unique Years (YearNum)
SELECT DISTINCT YearNum
FROM us_food_imports_db.us_food_imports
ORDER BY YearNum;

/*
--------------------------------------------------------------------------------
SECTION 2: DATA CLASSIFICATION & SUB-TABLE CREATION
--------------------------------------------------------------------------------
This query creates a temporary table to classify the 'FoodValue' based on its 'UOM',
which is crucial for separating the data.
*/
 
-- Unit Type Classification
-- Create a temporary table with the unit_type classification
CREATE TABLE us_food_imports_db.temp_classified_imports AS
SELECT
    Commodity,
    Country,
    UOM,
    Category,
    SubCategory,
    RowNumber,
    YearNum,
    FoodValue,
    CASE
        WHEN UOM IN ('Million $', 'Dollars') THEN 'Monetary Value'
        WHEN UOM IN ('1,000', '1,000 mt', '1,000 litpf') THEN 'Quantity'
        WHEN UOM IN ('Dollars per mt', 'Dollars per KL') THEN 'Price Rate'
        WHEN UOM = 'percent' THEN 'Percentage'
        ELSE 'Unknown' -- Fallback for any unexpected UOMs
    END AS unit_type
FROM
    us_food_imports_db.us_food_imports;

-- Verify the new table and unit_type distribution
SELECT DISTINCT unit_type FROM us_food_imports_db.temp_classified_imports;
SELECT unit_type, COUNT(*) FROM us_food_imports_db.temp_classified_imports GROUP BY unit_type;
SELECT * FROM us_food_imports_db.temp_classified_imports LIMIT 10;

/*
--------------------------------------------------------------------------------
SECTION 3: CREATING SPECIALIZED TABLES
--------------------------------------------------------------------------------
These queries create dedicated tables for each 'unit_type' to ensure
data consistency and prevent double-counting in analytical scenarios.
*/

-- Create the dedicated table for Monetary Value data
CREATE TABLE us_food_imports_db.food_imports_monetary_value AS
SELECT
    Commodity,
    Country,
    UOM,
    Category,
    SubCategory,
    YearNum,
    FoodValue
FROM
    us_food_imports_db.temp_classified_imports
WHERE
    unit_type = 'Monetary Value'
    AND Country NOT IN ('WORLD'); -- Only exclude 'WORLD', REST OF WORLD is included
    
-- Verify the new table structure
DESCRIBE us_food_imports_db.food_imports_monetary_value;

-- View a sample of the data to confirm filters
SELECT *
FROM us_food_imports_db.food_imports_monetary_value
LIMIT 10;

-- Confirm remaining unique UOMs (should only be 'Million $' and 'Dollars')
SELECT DISTINCT UOM
FROM us_food_imports_db.food_imports_monetary_value;

-- Confirm remaining unique Countries (should NOT include 'WORLD', 'REST OF WORLD', or 'WORLD (Quantity)')
SELECT DISTINCT Country
FROM us_food_imports_db.food_imports_monetary_value
ORDER BY Country;

-- Create the dedicated table for Quantity data
CREATE TABLE us_food_imports_db.food_imports_quantity AS
SELECT
    Commodity,
    Country,
    UOM, -- Keep UOM to distinguish 1,000, 1,000 mt, 1,000 litpf
    Category,
    SubCategory,
    YearNum,
    FoodValue
FROM
    us_food_imports_db.temp_classified_imports
WHERE
    unit_type = 'Quantity'; -- Filter only for Quantity unit_type
    
-- Verify the new table structure
DESCRIBE us_food_imports_db.food_imports_quantity;

-- View a sample of the data to confirm filters
SELECT *
FROM us_food_imports_db.food_imports_quantity
LIMIT 10;

-- Confirm remaining unique UOMs (should only be '1,000', '1,000 mt', '1,000 litpf')
SELECT DISTINCT UOM
FROM us_food_imports_db.food_imports_quantity;

-- Confirm remaining unique Countries (should only be 'WORLD (Quantity)' based on our prior observations)
SELECT DISTINCT Country
FROM us_food_imports_db.food_imports_quantity
ORDER BY Country;

-- Create the dedicated table for Price Rate data
CREATE TABLE us_food_imports_db.food_imports_price_rate AS
SELECT
    Commodity,
    Country,
    UOM, -- Keep UOM to distinguish Dollars per mt, Dollars per KL
    Category,
    SubCategory,
    YearNum,
    FoodValue
FROM
    us_food_imports_db.temp_classified_imports
WHERE
    unit_type = 'Price Rate'; -- Filter only for Price Rate unit_type

-- Verify the new table structure
DESCRIBE us_food_imports_db.food_imports_price_rate;

-- View a sample of the data to confirm filters
SELECT *
FROM us_food_imports_db.food_imports_price_rate
LIMIT 10;

-- Confirm remaining unique UOMs (should only be 'Dollars per mt', 'Dollars per KL')
SELECT DISTINCT UOM
FROM us_food_imports_db.food_imports_price_rate;

-- Confirm remaining unique Countries (check if any specific countries appear or if it's mostly 'WORLD'/'REST OF WORLD' for rates)
SELECT DISTINCT Country
FROM us_food_imports_db.food_imports_price_rate
ORDER BY Country;

-- Create the dedicated table for Percentage data
CREATE TABLE us_food_imports_db.food_imports_percentage AS
SELECT
    Commodity,
    Country,
    UOM, -- Keep UOM here (should be 'percent')
    Category,
    SubCategory,
    YearNum,
    FoodValue
FROM
    us_food_imports_db.temp_classified_imports
WHERE
    unit_type = 'Percentage'; -- Filter only for Percentage unit_type

-- Verify the new table structure
DESCRIBE us_food_imports_db.food_imports_percentage;

-- View a sample of the data to confirm filters
SELECT *
FROM us_food_imports_db.food_imports_percentage
LIMIT 1000;

-- Confirm remaining unique UOMs (should only be 'percent')
SELECT DISTINCT UOM
FROM us_food_imports_db.food_imports_percentage;

-- Confirm remaining unique Countries (check what countries appear for percentages)
SELECT DISTINCT Country
FROM us_food_imports_db.food_imports_percentage
ORDER BY Country;

-- Confirm all unique Categories in the percentage table
SELECT DISTINCT Category
FROM us_food_imports_db.food_imports_percentage
ORDER BY Category;

-- Confirm all unique SubCategories in the percentage table
SELECT DISTINCT SubCategory
FROM us_food_imports_db.food_imports_percentage
ORDER BY SubCategory;
