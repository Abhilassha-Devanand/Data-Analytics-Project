-- ==========================================================
-- Retail Sales Analysis - SQL Queries & Views
-- Dataset: Sales Data (185,950 rows)
-- ==========================================================

-- 🔹 1. Product Analysis
-- ----------------------------------------------------------

-- a) Best-Selling Products by Quantity
SELECT 
    Product,
    SUM(`Quantity Ordered`) AS total_quantity
FROM sales_data
GROUP BY Product
ORDER BY total_quantity DESC
LIMIT 10;

-- b) Best-Selling Products by Revenue
SELECT 
    Product,
    SUM(Sales) AS total_sales
FROM sales_data
GROUP BY Product
ORDER BY total_sales DESC
LIMIT 10;

-- c) High-Margin Products (by Average Unit Price)
SELECT 
    Product,
    AVG(`Price Each`) AS avg_unit_price
FROM sales_data
GROUP BY Product
ORDER BY avg_unit_price DESC
LIMIT 10;

-- d) Products Frequently Bought Together (Bundling)
SELECT 
    a.Product AS product_1,
    b.Product AS product_2,
    COUNT(*) AS times_bought_together
FROM sales_data a
JOIN sales_data b 
    ON a.`Order ID` = b.`Order ID`
   AND a.Product < b.Product
GROUP BY a.Product, b.Product
ORDER BY times_bought_together DESC
LIMIT 10;


-- 🔹 2. Customer / Location Analysis
-- ----------------------------------------------------------

-- a) City-Wise Sales
SELECT 
    City,
    SUM(Sales) AS total_sales
FROM sales_data
GROUP BY City
ORDER BY total_sales DESC;

-- b) Average Order Value by City
SELECT 
    City,
    SUM(Sales) / COUNT(DISTINCT `Order ID`) AS avg_order_value
FROM sales_data
GROUP BY City
ORDER BY avg_order_value DESC;

-- c) State-Wise Sales (Extract State from Address)
SELECT 
    SUBSTRING_INDEX(SUBSTRING_INDEX(`Purchase Address`, ',', -2), ' ', 2) AS State,
    SUM(Sales) AS total_sales
FROM sales_data
GROUP BY State
ORDER BY total_sales DESC;


-- 🔹 3. Sales Performance KPIs
-- ----------------------------------------------------------

-- a) Total Sales
SELECT SUM(Sales) AS total_sales FROM sales_data;

-- b) Total Orders
SELECT COUNT(DISTINCT `Order ID`) AS total_orders FROM sales_data;

-- c) Average Order Value (AOV)
SELECT SUM(Sales) / COUNT(DISTINCT `Order ID`) AS avg_order_value 
FROM sales_data;

-- d) Orders per Month
SELECT 
    Month,
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM sales_data
GROUP BY Month
ORDER BY Month;

-- e) Orders per City
SELECT 
    City,
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM sales_data
GROUP BY City
ORDER BY total_orders DESC;

-- f) Revenue Growth (Month over Month)
SELECT 
    Month,
    SUM(Sales) AS total_sales,
    (SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY Month)) AS growth
FROM sales_data
GROUP BY Month
ORDER BY Month;


-- 🔹 4. Marketing & Operational Insights
-- ----------------------------------------------------------

-- a) Peak Order Hours
SELECT 
    Hour,
    SUM(Sales) AS total_sales,
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM sales_data
GROUP BY Hour
ORDER BY Hour;

-- b) Sales per Month (Holiday Impact Check)
SELECT 
    Month,
    SUM(Sales) AS total_sales
FROM sales_data
GROUP BY Month
ORDER BY Month;

-- c) Weekday vs Weekend Sales
SELECT 
    DAYNAME(`Order Date`) AS day_of_week,
    SUM(Sales) AS total_sales,
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM sales_data
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');


-- 🔹 5. Views for Reusability (Dashboard Components)
-- ----------------------------------------------------------

-- View: Best-Selling Products
CREATE OR REPLACE VIEW top_products AS
SELECT 
    Product,
    SUM(Sales) AS total_sales,
    SUM(`Quantity Ordered`) AS total_quantity
FROM sales_data
GROUP BY Product
ORDER BY total_sales DESC;

-- View: City-Wise Sales
CREATE OR REPLACE VIEW city_sales AS
SELECT 
    City,
    SUM(Sales) AS total_sales,
    COUNT(DISTINCT `Order ID`) AS total_orders,
    SUM(Sales) / COUNT(DISTINCT `Order ID`) AS avg_order_value
FROM sales_data
GROUP BY City
ORDER BY total_sales DESC;

-- View: Monthly Sales
CREATE OR REPLACE VIEW monthly_sales AS
SELECT 
    Month,
    SUM(Sales) AS total_sales,
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM sales_data
GROUP BY Month
ORDER BY Month;

-- View: Hourly Sales
CREATE OR REPLACE VIEW hourly_sales AS
SELECT 
    Hour,
    SUM(Sales) AS total_sales,
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM sales_data
GROUP BY Hour
ORDER BY Hour;

-- View: Revenue Growth by Month
CREATE OR REPLACE VIEW revenue_growth AS
SELECT 
    Month,
    SUM(Sales) AS total_sales,
    (SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY Month)) AS month_growth
FROM sales_data
GROUP BY Month
ORDER BY Month;

-- View: Weekday Sales
CREATE OR REPLACE VIEW weekday_sales AS
SELECT 
    DAYNAME(`Order Date`) AS day_of_week,
    SUM(Sales) AS total_sales,
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM sales_data
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');


-- 🔹 6. Master Dashboard View
-- ----------------------------------------------------------

CREATE OR REPLACE VIEW sales_dashboard AS
SELECT
    -- Overall KPIs
    (SELECT SUM(Sales) FROM sales_data) AS total_sales,
    (SELECT COUNT(DISTINCT `Order ID`) FROM sales_data) AS total_orders,
    (SELECT SUM(Sales) / COUNT(DISTINCT `Order ID`) FROM sales_data) AS avg_order_value,
    
    -- Best-Selling Product
    (SELECT Product 
     FROM sales_data 
     GROUP BY Product 
     ORDER BY SUM(Sales) DESC 
     LIMIT 1) AS top_product,
     
    (SELECT SUM(Sales) 
     FROM sales_data 
     GROUP BY Product 
     ORDER BY SUM(Sales) DESC 
     LIMIT 1) AS top_product_sales,
     
    -- Top City
    (SELECT City 
     FROM sales_data 
     GROUP BY City 
     ORDER BY SUM(Sales) DESC 
     LIMIT 1) AS top_city,
     
    (SELECT SUM(Sales) 
     FROM sales_data 
     GROUP BY City 
     ORDER BY SUM(Sales) DESC 
     LIMIT 1) AS top_city_sales,
     
    -- Best Month
    (SELECT Month 
     FROM sales_data 
     GROUP BY Month 
     ORDER BY SUM(Sales) DESC 
     LIMIT 1) AS best_month,
     
    (SELECT SUM(Sales) 
     FROM sales_data 
     GROUP BY Month 
     ORDER BY SUM(Sales) DESC 
     LIMIT 1) AS best_month_sales;
