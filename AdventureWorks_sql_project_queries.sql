-- PART 1: DEFINING THE TABLES WE WILL USE

-- calendar table:
CREATE TABLE calendar (
    date DATE PRIMARY KEY
);

-- customers table:
CREATE TABLE customers (
    customer_key INT PRIMARY KEY,
    prefix VARCHAR(4),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birth_date DATE,
    marital_status CHAR(1),
    gender CHAR(2),
    email_address VARCHAR(255),
    annual_income INT,
    total_children SMALLINT,
    education_level VARCHAR(100),
    occupation VARCHAR(100),
    homeowner CHAR(1)
);

-- Products Table
CREATE TABLE products(
	product_key SMALLINT PRIMARY KEY,
	product_subcategory_key SMALLINT,
	product_sku VARCHAR(25),
	product_name VARCHAR(50),
	model_name VARCHAR(50),
	product_description VARCHAR,
	product_color VARCHAR(25),
	product_size VARCHAR(10),
	product_style CHAR(1),
	product_cost NUMERIC(10,4),
	product_price NUMERIC(10,4)
);

-- Product Categories Table:
CREATE TABLE product_categories (
	product_category_key SERIAL PRIMARY KEY,
	category_name VARCHAR(15)
);


-- Product Subcategories Table:
CREATE TABLE product_subcategories (
	product_subcategory_key SERIAL PRIMARY KEY,
	subcategory_name VARCHAR(50),
	product_category_key INT
);

-- Territories Table:
CREATE TABLE territories (
	sales_territory_key SERIAL PRIMARY KEY,
	region VARCHAR(50),
	country VARCHAR(50),
	continent VARCHAR(50)
);


-- Returns Data Table
CREATE TABLE returns_data (
	return_date DATE,
	territory_key SMALLINT,
	product_key SMALLINT,
	return_quantity SMALLINT
);

-- Sales from 2020, 2021, 2022:
CREATE TABLE sales_2020 (
	order_date DATE,
	stock_date DATE,
	order_number VARCHAR(25),
	product_key SMALLINT,
	customer_key INT,
	territory_key SMALLINT,
	order_line_item SMALLINT,
	order_quantity SMALLINT
);


CREATE TABLE sales_2021 (
	order_date DATE,
	stock_date DATE,
	order_number VARCHAR(25),
	product_key SMALLINT,
	customer_key INT,
	territory_key SMALLINT,
	order_line_item SMALLINT,
	order_quantity SMALLINT
);

CREATE TABLE sales_2022 (
	order_date DATE,
	stock_date DATE,
	order_number VARCHAR(25),
	product_key SMALLINT,
	customer_key INT,
	territory_key SMALLINT,
	order_line_item SMALLINT,
	order_quantity SMALLINT
);


-- Sales Data Table (will combine 2020, 2021, 2022)
CREATE TABLE sales (
	order_date DATE,
	stock_date DATE,
	order_number VARCHAR(25),
	product_key SMALLINT,
	customer_key INT,
	territory_key SMALLINT,
	order_line_item SMALLINT,
	order_quantity SMALLINT
);


ALTER TABLE products
ADD CONSTRAINT fk_product_subcategory_key
FOREIGN KEY (product_subcategory_key)
REFERENCES product_subcategories(product_subcategory_key);

ALTER TABLE products
DROP CONSTRAINT fk_product_subcategory_key;


ALTER TABLE product_subcategories
ADD CONSTRAINT fk_category_key
FOREIGN KEY (product_category_key)
REFERENCES product_categories(product_category_key);

ALTER TABLE product_subcategories
DROP CONSTRAINT fk_category_key;

 

ALTER TABLE sales
ADD CONSTRAINT fk_s_customer_key FOREIGN KEY (customer_key) REFERENCES customers(customer_key),
ADD CONSTRAINT fk_s_territory_key FOREIGN KEY (territory_key) REFERENCES territories(sales_territory_key),
ADD CONSTRAINT fk_s_product_key FOREIGN KEY (product_key) REFERENCES products(product_key);


-- COMBINING ALL SALES DATA TO ONE TABLE:
INSERT INTO sales
SELECT * FROM sales_2020
UNION ALL
SELECT * FROM sales_2021
UNION ALL
SELECT * FROM sales_2022;

SELECT * FROM territories;
