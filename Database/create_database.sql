-- Drop the database if it exists
DROP DATABASE IF EXISTS sales_db;

-- Create the database
CREATE DATABASE sales_db;

-- Use the database
USE sales_db;

-- Drop and create dim_customer
DROP TABLE IF EXISTS dim_customer;
CREATE TABLE dim_customer (
    customer_code INT PRIMARY KEY,
    customer VARCHAR(150),
    platform VARCHAR(45),
    channel VARCHAR(45),
    market VARCHAR(45),
    sub_zone VARCHAR(45),
    region VARCHAR(45)
);

-- Drop and create dim_product
DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    product_code VARCHAR(45) PRIMARY KEY,
    division VARCHAR(45),
    segment VARCHAR(45),
    category VARCHAR(45),
    product VARCHAR(200),
    variant VARCHAR(45)
);

-- Drop and create fact_sales_monthly
DROP TABLE IF EXISTS fact_sales_monthly;
CREATE TABLE fact_sales_monthly (
    date DATE,
    customer_code INT,
    product_code VARCHAR(45),
    sold_quantity INT,
    PRIMARY KEY (date, customer_code, product_code),
    FOREIGN KEY (customer_code) REFERENCES dim_customer(customer_code),
    FOREIGN KEY (product_code) REFERENCES dim_product(product_code)
);

-- Drop and create fact_forecast_monthly
DROP TABLE IF EXISTS fact_forecast_monthly;
CREATE TABLE fact_forecast_monthly (
    customer_code INT,
    product_code VARCHAR(45),
    date DATE,
    fiscal_year YEAR,
    forecast_quantity INT,
    PRIMARY KEY (customer_code, product_code, date),
    FOREIGN KEY (customer_code) REFERENCES dim_customer(customer_code),
    FOREIGN KEY (product_code) REFERENCES dim_product(product_code)
);

-- Drop and create fact_post_invoice_deductions
DROP TABLE IF EXISTS fact_post_invoice_deductions;
CREATE TABLE fact_post_invoice_deductions (
    customer_code INT,
    product_code VARCHAR(45),
    date DATE,
    discounts_pct DECIMAL(5,4),
    other_deductions_pct DECIMAL(5,4),
    PRIMARY KEY (customer_code, product_code, date),
    FOREIGN KEY (customer_code) REFERENCES dim_customer(customer_code),
    FOREIGN KEY (product_code) REFERENCES dim_product(product_code)
);

-- Drop and create fact_freight_cost
DROP TABLE IF EXISTS fact_freight_cost;
CREATE TABLE fact_freight_cost (
    market VARCHAR(45),
    fiscal_year YEAR,
    freight_pct DECIMAL(5,4),
    other_cost_pct DECIMAL(5,4),
    PRIMARY KEY (market, fiscal_year)
);

-- Drop and create fact_pre_invoice_deductions
DROP TABLE IF EXISTS fact_pre_invoice_deductions;
CREATE TABLE fact_pre_invoice_deductions (
    customer_code INT,
    fiscal_year YEAR,
    pre_invoice_discount_pct DECIMAL(5,4),
    PRIMARY KEY (customer_code, fiscal_year),
    FOREIGN KEY (customer_code) REFERENCES dim_customer(customer_code)
);

-- Drop and create fact_gross_price
DROP TABLE IF EXISTS fact_gross_price;
CREATE TABLE fact_gross_price (
    product_code VARCHAR(45),
    fiscal_year YEAR,
    gross_price DECIMAL(15,4),
    PRIMARY KEY (product_code, fiscal_year),
    FOREIGN KEY (product_code) REFERENCES dim_product(product_code)
);

-- Drop and create fact_manufacturing_cost
DROP TABLE IF EXISTS fact_manufacturing_cost;
CREATE TABLE fact_manufacturing_cost (
    product_code VARCHAR(45),
    cost_year YEAR,
    manufacturing_cost DECIMAL(15,4),
    PRIMARY KEY (product_code, cost_year),
    FOREIGN KEY (product_code) REFERENCES dim_product(product_code)
);