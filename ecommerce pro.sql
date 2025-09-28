-- ==============================
-- 1️⃣ Drop existing tables (if any)
-- ==============================
DROP TABLE IF EXISTS Returns;
DROP TABLE IF EXISTS Shipping;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Order_Items;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;

-- ==============================
-- 2️⃣ Create tables
-- ==============================

-- Customers Table
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(50),
    email VARCHAR(100),
    city VARCHAR(50),
    join_date DATE
);

-- Products Table
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock INT DEFAULT 100
);

-- Orders Table
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Order_Items Table
CREATE TABLE Order_Items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Payments Table
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    payment_date DATETIME,
    payment_method VARCHAR(20),
    amount DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- Shipping Table
CREATE TABLE Shipping (
    shipping_id INT PRIMARY KEY,
    order_id INT,
    shipped_date DATE,
    delivery_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- Returns Table
CREATE TABLE Returns (
    return_id INT PRIMARY KEY,
    order_item_id INT,
    return_date DATE,
    reason VARCHAR(100),
    FOREIGN KEY (order_item_id) REFERENCES Order_Items(order_item_id)
);

-- ==============================
-- 3️⃣ Insert Sample Data
-- ==============================
INSERT INTO Customers VALUES
(1, 'Alice', 'alice@example.com', 'Delhi', '2023-01-10'),
(2, 'Bob', 'bob@example.com', 'Mumbai', '2023-02-15'),
(3, 'Charlie', 'charlie@example.com', 'Bangalore', '2023-03-20'),
(4, 'David', 'david@example.com', 'Chennai', '2023-05-05');

INSERT INTO Products VALUES
(101, 'Laptop', 'Electronics', 55000, 50),
(102, 'Mobile Phone', 'Electronics', 20000, 100),
(103, 'Headphones', 'Accessories', 2500, 200),
(104, 'Shoes', 'Fashion', 3000, 150),
(105, 'T-Shirt', 'Fashion', 800, 300);

INSERT INTO Orders VALUES
(1001, 1, '2023-06-01'),
(1002, 2, '2023-06-05'),
(1003, 1, '2023-07-10'),
(1004, 3, '2023-08-12'),
(1005, 4, '2023-08-15');

INSERT INTO Order_Items VALUES
(1, 1001, 101, 1),
(2, 1001, 103, 2),
(3, 1002, 102, 1),
(4, 1003, 104, 1),
(5, 1003, 105, 3),
(6, 1004, 101, 1),
(7, 1005, 103, 1),
(8, 1005, 105, 2);

-- ==============================
-- 4️⃣ Triggers
-- ==============================

DELIMITER $$

-- Trigger 1: Auto insert payment after new order
CREATE TRIGGER trg_after_order_insert
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    DECLARE total_amount DECIMAL(10,2);
    
    SELECT SUM(p.price * oi.quantity) INTO total_amount
    FROM Order_Items oi
    JOIN Products p ON oi.product_id = p.product_id
    WHERE oi.order_id = NEW.order_id;
    
    INSERT INTO Payments(order_id, payment_date, payment_method, amount)
    VALUES (NEW.order_id, NOW(), 'Pending', total_amount);
END$$

-- Trigger 2: Reduce product stock after order item inserted
DELIMITER $$
CREATE TRIGGER trg_after_order_item_insert
AFTER INSERT ON Order_Items
FOR EACH ROW
BEGIN
    UPDATE Products
    SET stock = stock - NEW.quantity
    WHERE product_id = NEW.product_id;
END$$
DELIMITER ;

-- Trigger 3: Auto update shipping status if delivery date <= today
DELIMITER $$
CREATE TRIGGER trg_update_shipping_status
BEFORE UPDATE ON Shipping
FOR EACH ROW
BEGIN
    IF NEW.delivery_date IS NOT NULL AND NEW.delivery_date <= CURDATE() THEN
        SET NEW.status = 'Delivered';
    END IF;
END$$

DELIMITER ;

-- ==============================
-- Test Insert Queries
-- ==============================
-- Insert a new order

INSERT INTO Orders (order_id, customer_id, order_date) VALUES (1006, 2, '2023-09-28');

-- Insert order items
INSERT INTO Order_Items (order_item_id, order_id, product_id, quantity) VALUES
(9, 1006, 102, 1),
(10, 1006, 103, 2);

INSERT INTO Customers (customer_id, name, email, city, join_date)
VALUES (5, 'Eve', 'eve@example.com', 'Hyderabad', '2023-09-27');
INSERT INTO Orders (order_id, customer_id, order_date)
VALUES (1009, 5, '2023-09-27');

-- Check Payments
SELECT * FROM Payments WHERE order_id = 1006;

-- Check Products stock after trigger
SELECT * FROM Products WHERE product_id IN (102, 103);

START TRANSACTION;

-- Insert new order
INSERT INTO Orders (order_id, customer_id, order_date)
VALUES (1012, 1, '2023-09-28');

-- Insert order items
INSERT INTO Order_Items (order_item_id, order_id, product_id, quantity)
VALUES (14, 1012, 102, 1),   -- Mobile Phone
       (15, 1012, 103, 2);   -- Headphones

-- Insert payment
INSERT INTO Payments (order_id, payment_date, payment_method, amount)
VALUES (1012, NOW(), 'Credit Card', 25000);

-- Check inserted data before commit
SELECT * FROM Orders WHERE order_id = 1012;
SELECT * FROM Order_Items WHERE order_id = 1012;
SELECT * FROM Payments WHERE order_id = 1012;

-- Commit all changes
COMMIT;

-- 2️⃣ Consistency Example
-- ==============================
-- Scenario: Reduce stock safely

START TRANSACTION;

-- Check current stock
SELECT product_id, product_name, stock FROM Products WHERE product_id = 102;

-- Update stock only if sufficient
UPDATE Products
SET stock = stock - 1
WHERE product_id = 102 AND stock >= 1;

-- Check stock after update
SELECT product_id, product_name, stock FROM Products WHERE product_id = 102;

COMMIT;


-- 3️⃣ Isolation Example
-- ==============================
-- Scenario: Two sessions attempt to update the same stock

START TRANSACTION;
SELECT stock FROM Products WHERE product_id = 103 FOR UPDATE;
UPDATE Products SET stock = stock - 2 WHERE product_id = 103;

-- Session 2 (run simultaneously in another session):
START TRANSACTION;
SELECT stock FROM Products WHERE product_id = 103 FOR UPDATE;
UPDATE Products SET stock = stock - 1 WHERE product_id = 103;

-- Both sessions COMMIT separately to demonstrate isolation
COMMIT;

-- 4️⃣ Durability Example
-- ==============================
-- Scenario: Data persists after commit

START TRANSACTION;

INSERT INTO Orders (order_id, customer_id, order_date)
VALUES (1013, 2, '2023-09-28');

INSERT INTO Payments (order_id, payment_date, payment_method, amount)
VALUES (1013, NOW(), 'UPI', 20000);

-- Commit so changes are durable
COMMIT;

-- Verify durable data
SELECT * FROM Orders WHERE order_id = 1013;
SELECT * FROM Payments WHERE order_id = 1013;


select * from Customers;
select * from Products;
select * from Orders;
select * from Order_items;
select * from payments;
select * from returns;
select * from shipping;

