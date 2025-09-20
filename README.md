🛍️ Retail Sales Analysis Dashboard (SQL Project)
📌 Project Overview

This project analyzes a dataset of 185,000+ retail transactions to uncover business insights using SQL.
The goal was to answer key sales and customer questions for decision-making and create a SQL-based dashboard for quick reporting.


📊 Dataset

Source: Kaggle-style retail sales dataset (Sales Data.csv)

Size: 185,950 rows × 11 columns

Fields:

Order ID → unique identifier

Product → product name

Quantity Ordered → number of units

Price Each → unit price

Order Date → purchase timestamp

Purchase Address → customer address

Month → numeric month

Sales → total revenue (Quantity × Price)

City → extracted city

Hour → order hour (0–23)


⚙️ SQL Features Used

Aggregate Functions: SUM(), COUNT(), AVG()

Grouping & Filtering: GROUP BY, ORDER BY, HAVING

Window Functions: LAG() for growth tracking

String Functions: SUBSTRING_INDEX() to extract state info

Joins: Self-joins for product bundling

Views: Created reusable views for sales dashboard


📊 Dashboard View

A one-row dashboard view that summarizes KPIs:

CREATE OR REPLACE VIEW sales_dashboard AS
SELECT
    (SELECT SUM(Sales) FROM sales_data) AS total_sales,
    (SELECT COUNT(DISTINCT `Order ID`) FROM sales_data) AS total_orders,
    (SELECT SUM(Sales) / COUNT(DISTINCT `Order ID`) FROM sales_data) AS avg_order_value,
    (SELECT Product FROM sales_data GROUP BY Product ORDER BY SUM(Sales) DESC LIMIT 1) AS top_product,
    (SELECT City FROM sales_data GROUP BY City ORDER BY SUM(Sales) DESC LIMIT 1) AS top_city,
    (SELECT Month FROM sales_data GROUP BY Month ORDER BY SUM(Sales) DESC LIMIT 1) AS best_month;
