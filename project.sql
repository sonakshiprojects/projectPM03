CREATE DATABASE project_supply_chain;
USE project_supply_chain;

DESCRIBE orders;
DESCRIBE customers;
DESCRIBE products;
DESCRIBE suppliers;
DESCRIBE inventory;
DESCRIBE shipping;
DESCRIBE warehouses;

-- Inspecting Date formats
SELECT order_date
FROM orders
LIMIT 20;

SELECT delivery_date
FROM orders
LIMIT 20;

SELECT join_date
FROM customers
LIMIT 20;

SELECT launch_date
FROM products
LIMIT 20;

SELECT contract_start_date
FROM suppliers
LIMIT 20;

SELECT snapshot_date
FROM inventory
LIMIT 20;

SELECT dispatch_date, delivery_date
FROM shipping
LIMIT 20;

-- Standardizing Date Formats
ALTER TABLE orders
ADD COLUMN order_date_clean DATE,
ADD COLUMN delivery_date_clean DATE;

UPDATE orders
SET order_date_clean =
CASE
    WHEN order_date LIKE '%/%'
        THEN STR_TO_DATE(order_date,'%d/%m/%Y')

    WHEN order_date LIKE '%-%' AND LENGTH(order_date)=10
         AND SUBSTRING(order_date,5,1)='-'
        THEN STR_TO_DATE(order_date,'%Y-%m-%d')

    WHEN order_date LIKE '%-%'
        THEN STR_TO_DATE(order_date,'%d-%m-%Y')

    ELSE NULL
END;
UPDATE orders
SET delivery_date_clean =
CASE
    WHEN delivery_date LIKE '%/%'
        THEN STR_TO_DATE(delivery_date,'%d/%m/%Y')

    WHEN delivery_date LIKE '%-%' AND LENGTH(delivery_date)=10
         AND SUBSTRING(delivery_date,5,1)='-'
        THEN STR_TO_DATE(delivery_date,'%Y-%m-%d')

    WHEN delivery_date LIKE '%-%'
        THEN STR_TO_DATE(delivery_date,'%d-%m-%Y')

    ELSE NULL
END;

ALTER TABLE customers
ADD COLUMN join_date_clean DATE;
UPDATE customers
SET join_date_clean =
STR_TO_DATE(join_date,'%Y-%m-%d');

ALTER TABLE products
ADD COLUMN launch_date_clean DATE;
UPDATE products
SET launch_date_clean =
STR_TO_DATE(launch_date,'%Y-%m-%d');

ALTER TABLE suppliers
ADD COLUMN contract_start_date_clean DATE;
UPDATE suppliers
SET contract_start_date_clean =
STR_TO_DATE(contract_start_date,'%Y-%m-%d');

ALTER TABLE inventory
ADD COLUMN snapshot_date_clean DATE;
UPDATE inventory
SET snapshot_date_clean =
STR_TO_DATE(snapshot_date,'%Y-%m-%d');

UPDATE shipping
SET delivery_date_clean =
CASE
    WHEN delivery_date IS NULL OR TRIM(delivery_date) = ''
        THEN NULL
    ELSE STR_TO_DATE(delivery_date,'%Y-%m-%d')
END;

-- Validation checks
SELECT
MIN(order_date_clean) AS min_order_date,
MAX(order_date_clean) AS max_order_date
FROM orders;
SELECT
MIN(delivery_date_clean) AS min_delivery_date,
MAX(delivery_date_clean) AS max_delivery_date
FROM orders;

SELECT
MIN(join_date_clean),
MAX(join_date_clean)
FROM customers;

SELECT
MIN(launch_date_clean),
MAX(launch_date_clean)
FROM products;

SELECT
MIN(contract_start_date_clean),
MAX(contract_start_date_clean)
FROM suppliers;

SELECT
MIN(snapshot_date_clean),
MAX(snapshot_date_clean)
FROM inventory;

SELECT
MIN(dispatch_date_clean),
MAX(dispatch_date_clean)
FROM shipping;
SELECT
MIN(delivery_date_clean),
MAX(delivery_date_clean)
FROM shipping;

-- Remove Duplicate Rows
CREATE TABLE orders_clean AS
WITH ranked_orders AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY order_id
               ORDER BY order_date_clean
           ) AS rn
    FROM orders
)
SELECT *
FROM ranked_orders
WHERE rn = 1;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM orders_clean;
SELECT COUNT(*) - COUNT(DISTINCT order_id)
FROM orders_clean;

CREATE TABLE customers_clean AS
WITH ranked_customers AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY customer_id
               ORDER BY join_date_clean
           ) AS rn
    FROM customers
)
SELECT *
FROM ranked_customers
WHERE rn = 1;
SELECT COUNT(*) - COUNT(DISTINCT customer_id)
FROM customers_clean;

CREATE TABLE shipping_clean AS
WITH ranked_shipping AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY shipment_id
               ORDER BY dispatch_date_clean
           ) AS rn
    FROM shipping
)
SELECT *
FROM ranked_shipping
WHERE rn = 1;
SELECT COUNT(*) - COUNT(DISTINCT shipment_id)
FROM shipping_clean;

SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM orders_clean;

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM customers_clean;

SELECT COUNT(*) FROM shipping;
SELECT COUNT(*) FROM shipping_clean;

-- Handling null values
SELECT
SUM(CASE WHEN order_date_clean IS NULL THEN 1 ELSE 0 END) AS order_date_missing,
SUM(CASE WHEN delivery_date_clean IS NULL THEN 1 ELSE 0 END) AS delivery_date_missing,
SUM(CASE WHEN profit IS NULL OR TRIM(profit)='' THEN 1 ELSE 0 END) AS profit_missing
FROM orders_clean;

SELECT
SUM(CASE WHEN city IS NULL OR TRIM(city)='' THEN 1 ELSE 0 END) AS city_missing,
SUM(CASE WHEN state IS NULL OR TRIM(state)='' THEN 1 ELSE 0 END) AS state_missing
FROM customers_clean;

SELECT
SUM(CASE WHEN supplier_rating IS NULL THEN 1 ELSE 0 END) AS supplier_rating_missing
FROM suppliers;

-- Missing value flags
ALTER TABLE orders_clean
ADD COLUMN missing_delivery_date_flag VARCHAR(3);
UPDATE orders_clean
SET missing_delivery_date_flag =
CASE
    WHEN delivery_date_clean IS NULL THEN 'Yes'
    ELSE 'No'
END;

ALTER TABLE customers_clean
ADD COLUMN missing_city_flag VARCHAR(3);
UPDATE customers_clean
SET missing_city_flag =
CASE
    WHEN city IS NULL OR TRIM(city)='' THEN 'Yes'
    ELSE 'No'
END;

-- Filling easy missing values
UPDATE suppliers
SET supplier_rating =
(
    SELECT avg_rating
    FROM
    (
        SELECT ROUND(AVG(supplier_rating),2) AS avg_rating
        FROM suppliers
        WHERE supplier_rating IS NOT NULL
    ) x
)
WHERE supplier_rating IS NULL;

UPDATE customers_clean
SET city = 'Unknown'
WHERE city IS NULL
OR TRIM(city)='';

UPDATE customers_clean
SET state = 'Unknown'
WHERE state IS NULL
OR TRIM(state)='';

SELECT COUNT(*)
FROM customers_clean
WHERE city='Unknown';

SELECT COUNT(*)
FROM customers_clean
WHERE state='Unknown';

-- Fixing Inconsistent Casing
SELECT DISTINCT city
FROM customers_clean
ORDER BY city;

SELECT DISTINCT supplier_city
FROM suppliers
ORDER BY supplier_city;

SELECT DISTINCT supplier_name
FROM suppliers
ORDER BY supplier_name;

ALTER TABLE customers_clean
ADD COLUMN city_clean VARCHAR(100);
UPDATE customers_clean
SET city_clean =
CONCAT(
    UPPER(LEFT(TRIM(city),1)),
    LOWER(SUBSTRING(TRIM(city),2))
);

ALTER TABLE suppliers
ADD COLUMN supplier_city_clean VARCHAR(100);
UPDATE suppliers
SET supplier_city_clean =
CONCAT(
    UPPER(LEFT(TRIM(supplier_city),1)),
    LOWER(SUBSTRING(TRIM(supplier_city),2))
);

ALTER TABLE suppliers
ADD COLUMN supplier_name_clean VARCHAR(200);
UPDATE suppliers
SET supplier_name_clean =
CONCAT(
    UPPER(LEFT(TRIM(supplier_name),1)),
    LOWER(SUBSTRING(TRIM(supplier_name),2))
);

SELECT DISTINCT city_clean
FROM customers_clean
ORDER BY city_clean;
SELECT DISTINCT supplier_city_clean
FROM suppliers
ORDER BY supplier_city_clean;


-- Validate & Remove Negative Values
SELECT *
FROM orders_clean
WHERE profit < 0;

SELECT COUNT(*) AS negative_profit_count
FROM orders_clean
WHERE profit < 0;

SELECT *
FROM inventory
WHERE inventory_value < 0;

SELECT COUNT(*) AS negative_inventory_count
FROM inventory
WHERE inventory_value < 0;

CREATE TABLE inventory_clean AS
SELECT *
FROM inventory
WHERE inventory_value >= 0
OR inventory_value IS NULL;

CREATE TABLE orders_final AS
SELECT *
FROM orders_clean
WHERE profit >= 0
OR profit IS NULL;

SELECT COUNT(*) FROM orders_clean;
SELECT COUNT(*) FROM orders_final;
SELECT COUNT(*) FROM inventory;
SELECT COUNT(*) FROM inventory_clean;

-- Remove Future Dates
SELECT COUNT(*)
FROM orders_final
WHERE order_date_clean > CURDATE();

-- Check and Document Orphan Foreign Keys
-- orders->customers
SELECT COUNT(*) AS orphan_customers
FROM orders_final o
LEFT JOIN customers_clean c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- orders->products
SELECT COUNT(*) AS orphan_products
FROM orders_final o
LEFT JOIN products p
ON o.product_id = p.product_id
WHERE p.product_id IS NULL;

-- orders->suppliers
SELECT COUNT(*) AS orphan_suppliers
FROM orders_final o
LEFT JOIN suppliers s
ON o.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL;

-- orders -> warehouses
SELECT COUNT(*) AS orphan_warehouses
FROM orders_final o
LEFT JOIN warehouses w
ON o.warehouse_id = w.warehouse_id
WHERE w.warehouse_id IS NULL;

-- inventory->products
SELECT COUNT(*) AS orphan_inventory_products
FROM inventory_clean i
LEFT JOIN products p
ON i.product_id = p.product_id
WHERE p.product_id IS NULL;

-- inventory->warehouses
SELECT COUNT(*) AS orphan_inventory_warehouses
FROM inventory_clean i
LEFT JOIN warehouses w
ON i.warehouse_id = w.warehouse_id
WHERE w.warehouse_id IS NULL;

-- shipping->orders
SELECT COUNT(*) AS orphan_shipments
FROM shipping_clean s
LEFT JOIN orders_final o
ON s.order_id = o.order_id
WHERE o.order_id IS NULL;


-- CREATE CLEANED VALUES
CREATE VIEW vw_customers AS
SELECT *
FROM customers_clean;

CREATE VIEW vw_orders AS
SELECT *
FROM orders_final;

CREATE VIEW vw_inventory AS
SELECT *
FROM inventory_clean;

CREATE VIEW vw_shipping AS
SELECT *
FROM shipping_clean;

CREATE VIEW vw_suppliers AS
SELECT *
FROM suppliers;

CREATE VIEW vw_products AS
SELECT *
FROM products;

CREATE VIEW vw_warehouses AS
SELECT *
FROM warehouses;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';

-- Business Analytics Queries
-- Revenue Trend
SELECT
YEAR(order_date_clean) AS year,
MONTH(order_date_clean) AS month,
SUM(sales_amount) AS total_revenue
FROM vw_orders
GROUP BY
YEAR(order_date_clean),
MONTH(order_date_clean)
ORDER BY year, month;

-- Top Products
SELECT
p.product_name,
SUM(o.sales_amount) AS total_revenue
FROM vw_orders o
JOIN vw_products p
ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Stockout Count
SELECT COUNT(*) AS stockout_count
FROM vw_inventory
WHERE stock_on_hand <= reorder_point;

-- Which suppliers are causing delayed deliveries?
SELECT
    s.supplier_name_clean,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.shipping_days > 7 THEN 1 ELSE 0 END) AS delayed_orders,
    ROUND(
        SUM(CASE WHEN o.shipping_days > 7 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS delay_rate_percent
FROM vw_orders o
JOIN vw_suppliers s
ON o.supplier_id = s.supplier_id
GROUP BY s.supplier_name_clean
ORDER BY delay_rate_percent DESC;

-- Warehouse Utilization
-- Which warehouses are heavily utilized?
SELECT
    w.warehouse_name,
    SUM(i.stock_on_hand) AS total_stock,
    MAX(w.capacity_units) AS capacity,
    ROUND(
        SUM(i.stock_on_hand) * 100.0 /
        MAX(w.capacity_units),
        2
    ) AS utilization_percent
FROM vw_inventory i
JOIN vw_warehouses w
ON i.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_name
ORDER BY utilization_percent DESC;

-- ABC Classification
WITH product_sales AS
(
    SELECT
        p.product_name,
        SUM(o.sales_amount) AS revenue
    FROM vw_orders o
    JOIN vw_products p
    ON o.product_id = p.product_id
    GROUP BY p.product_name
),

ranked_sales AS
(
    SELECT *,
           SUM(revenue) OVER(ORDER BY revenue DESC) AS cumulative_revenue,
           SUM(revenue) OVER() AS total_revenue
    FROM product_sales
)

SELECT *,
CASE
    WHEN cumulative_revenue/total_revenue <= 0.80 THEN 'A'
    WHEN cumulative_revenue/total_revenue <= 0.95 THEN 'B'
    ELSE 'C'
END AS abc_class
FROM ranked_sales;

-- What proportion of orders are completed, cancelled, pending, etc.?
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM vw_orders),
        2
    ) AS percentage
FROM vw_orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Which customer segment generates the most revenue?
SELECT
    c.customer_segment,
    SUM(o.sales_amount) AS total_revenue
FROM vw_orders o
JOIN vw_customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;

-- Monthly Sales
SELECT
    DATE_FORMAT(order_date_clean,'%Y-%m') AS month,
    SUM(sales_amount) AS monthly_sales
FROM vw_orders
GROUP BY month
ORDER BY month;

-- Lead Time Analysis
-- Average shipping lead time by supplier.
SELECT
    s.supplier_name_clean,
    ROUND(AVG(o.shipping_days),2) AS avg_lead_time
FROM vw_orders o
JOIN vw_suppliers s
ON o.supplier_id = s.supplier_id
GROUP BY s.supplier_name_clean
ORDER BY avg_lead_time DESC;

-- Top 10 Customers by Revenue
SELECT
    c.customer_name,
    SUM(o.sales_amount) AS revenue
FROM vw_orders o
JOIN vw_customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY revenue DESC
LIMIT 10;

-- Revenue by Product Category
SELECT
    p.category,
    SUM(o.sales_amount) AS revenue
FROM vw_orders o
JOIN vw_products p
ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Revenue by Warehouse
SELECT
    w.warehouse_name,
    SUM(o.sales_amount) AS revenue
FROM vw_orders o
JOIN vw_warehouses w
ON o.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_name
ORDER BY revenue DESC;