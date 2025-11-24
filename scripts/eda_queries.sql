/********************************************************************************************
    PROJECT: Sales Data – Exploratory Data Analysis (EDA)
    LAYER  : Gold Layer (Cleaned Data)
    TOOLS  : SQL Server 

    DESCRIPTION:
    This script performs a complete exploratory data analysis on three Gold-Layer views:
        • gold.fact_sales
        • gold.dim_customers
        • gold.dim_products

    The analysis covers:
        ✔ Data understanding
        ✔ Customer insights
        ✔ Product insights
        ✔ Sales & revenue metrics
        ✔ Top and bottom performers
        ✔ Business KPI summary


USE DataWarehouse;
GO


/*------------------------------------------------------------
  1️⃣ EXPLORE TABLE STRUCTURE & METADATA
------------------------------------------------------------*/

-- Explore all tables
SELECT *
FROM INFORMATION_SCHEMA.TABLES;

-- Explore columns in Customers dimension
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


/*------------------------------------------------------------
  2️⃣ BASIC DATA EXPLORATION
------------------------------------------------------------*/

-- Countries customers came from
SELECT DISTINCT country
FROM gold.dim_customers;

-- Product categories and hierarchy
SELECT DISTINCT 
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;


/*------------------------------------------------------------
  3️⃣ DATE RANGE ANALYSIS
------------------------------------------------------------*/

-- First and last order dates
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(YEAR,  MIN(order_date), MAX(order_date))  AS order_range_years,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;


/*------------------------------------------------------------
  4️⃣ CUSTOMER ANALYSIS
------------------------------------------------------------*/

-- Youngest and oldest customers
SELECT
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;

-- Customer count
SELECT COUNT(customer_key) AS total_customers
FROM gold.dim_customers;

-- Customers who placed an order
SELECT COUNT(customer_key) AS customers_placed_order
FROM gold.fact_sales;

SELECT COUNT(DISTINCT customer_key) AS distinct_customers_placed_order
FROM gold.fact_sales;


/*------------------------------------------------------------
  5️⃣ SALES & ORDER METRICS
------------------------------------------------------------*/

-- Total sales
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

-- Total quantity sold
SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales;

-- Average selling price
SELECT AVG(price) AS avg_price
FROM gold.fact_sales;

-- Total orders
SELECT COUNT(order_number) AS total_orders
FROM gold.fact_sales;

SELECT COUNT(DISTINCT order_number) AS distinct_orders
FROM gold.fact_sales;


/*------------------------------------------------------------
  6️⃣ PRODUCT ANALYSIS
------------------------------------------------------------*/

-- Product count
SELECT COUNT(product_key) AS total_products
FROM gold.dim_products;

SELECT COUNT(DISTINCT product_key) AS distinct_products
FROM gold.dim_products;


/*------------------------------------------------------------
  7️⃣ BUSINESS METRICS SUMMARY
------------------------------------------------------------*/

SELECT 'Total Sales' AS metric, SUM(sales_amount) AS value
FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity)
FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price)
FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number)
FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(product_key)
FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key)
FROM gold.dim_customers
UNION ALL
SELECT 'Customers Placed Order', COUNT(DISTINCT customer_key)
FROM gold.fact_sales;


/*------------------------------------------------------------
  8️⃣ DISTRIBUTION ANALYSIS
------------------------------------------------------------*/

-- Customers by country
SELECT 
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Customers by gender
SELECT 
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Products by category
SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- Average cost by category
SELECT
    category,
    AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;


/*------------------------------------------------------------
  9️⃣ REVENUE ANALYSIS
------------------------------------------------------------*/

-- Revenue by category
SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;

-- Revenue by customer
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY 
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;

-- Sold items by country
SELECT
    c.country,
    SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;


/*------------------------------------------------------------
  🔟 TOP & BOTTOM PERFORMERS
------------------------------------------------------------*/

-- Top 5 products by revenue
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Bottom 5 products by revenue
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

-- Top 5 subcategories by revenue
SELECT TOP 5
    p.subcategory,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC;

-- Top 5 products using window function
SELECT *
FROM (
    SELECT 
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_product
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.product_name
) t
WHERE rank_product <= 5;

