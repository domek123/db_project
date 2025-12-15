-- SQL Server (Transact-SQL) DDL Script
-- Converted from the provided DDL.

-- tables
---
-- Table: company_customers
CREATE TABLE company_customers (
    customer_id INT PRIMARY KEY, -- Used INT for customer_id, primary key constraint added inline
    name VARCHAR(255) NOT NULL,
    nip INT NOT NULL,
    email VARCHAR(255) NOT NULL
);

-- Table: components
CREATE TABLE components (
    component_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(5, 2) NOT NULL
);

-- Table: customers
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    type INT NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    postal_code VARCHAR(255) NOT NULL
);

-- Table: individual_customers
CREATE TABLE individual_customers (
    customer_id INT PRIMARY KEY,
    firstname VARCHAR(255) NOT NULL,
    lastname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL
);

-- Table: order_details
CREATE TABLE order_details (
    order_detail_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE NONCLUSTERED INDEX order_details_order_idx ON order_details (order_id ASC);

CREATE NONCLUSTERED INDEX order_details_product_idx ON order_details (product_id ASC);

-- Table: orders
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    -- Converted original 'timestamp' to DATETIME2 for date/time storage
    order_date DATETIME2 NOT NULL,
    planed_ready_date DATETIME2 NOT NULL,
    collect_date DATETIME2 NULL,
    discount DECIMAL(3, 2) NOT NULL,
    price DECIMAL(12, 2) NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE NONCLUSTERED INDEX customer_id_idx ON orders (customer_id ASC);

-- Table: payments
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    -- Converted original 'timestamp' to DATETIME2 for date/time storage
    payment_date DATETIME2 NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE NONCLUSTERED INDEX payment_idx_1 ON payments (order_id ASC);

-- Table: prodcution (Note: Typo 'prodcution' preserved from original script)
CREATE TABLE prodcution (
    production_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    production_start DATE NOT NULL,
    porductiion_finish DATE NOT NULL, -- Note: Typo 'porductiion' preserved from original script
    quantity INT NOT NULL,
    status INT NOT NULL
);

-- Table: production_details
CREATE TABLE production_details (
    production_id INT NOT NULL,
    production_order_id INT NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT production_details_pk PRIMARY KEY (production_id, production_order_id)
);

-- Table: production_orders
CREATE TABLE production_orders (
    production_order_id INT PRIMARY KEY,
    order_detail_id INT NULL,
    -- Converted original 'timestamp' to DATETIME2 for date/time storage
    order_date DATETIME2 NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE NONCLUSTERED INDEX production_order_product_idx ON production_orders (product_id ASC);

-- Table: products
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    production_cost DECIMAL(10, 2) NOT NULL,
    units_per_day INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    units_in_stock INT NOT NULL
);

-- Table: products_details
CREATE TABLE products_details (
    product_id INT NOT NULL,
    component_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(5, 2) NOT NULL,
    CONSTRAINT products_details_pk PRIMARY KEY (product_id, component_id)
);

CREATE NONCLUSTERED INDEX products_details_component_idx ON products_details (component_id ASC);

CREATE NONCLUSTERED INDEX products_details_product_idx ON products_details (product_id ASC);

---
-- foreign keys
---
-- Reference: orders_customers (table: orders)
ALTER TABLE orders ADD CONSTRAINT orders_customers
    FOREIGN KEY (customer_id)
    REFERENCES customers (customer_id)
;

-- Reference: customers_company_customers (table: customers)
ALTER TABLE customers ADD CONSTRAINT customers_company_customers
    FOREIGN KEY (customer_id)
    REFERENCES company_customers (customer_id)
;

-- Reference: customers_individual_customers (table: customers)
ALTER TABLE customers ADD CONSTRAINT customers_individual_customers
    FOREIGN KEY (customer_id)
    REFERENCES individual_customers (customer_id)
;

-- Reference: order_details_order (table: order_details)
ALTER TABLE order_details ADD CONSTRAINT order_details_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id)
    ON DELETE CASCADE
;

-- Reference: order_details_products (table: order_details)
ALTER TABLE order_details ADD CONSTRAINT order_details_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
    ON DELETE CASCADE
;

-- Reference: payment_order (table: payments)
ALTER TABLE payments ADD CONSTRAINT payment_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id)
;

-- Reference: prodcution_products (table: prodcution)
ALTER TABLE prodcution ADD CONSTRAINT prodcution_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
;

-- Reference: production_details_prodcution (table: production_details)
ALTER TABLE production_details ADD CONSTRAINT production_details_prodcution
    FOREIGN KEY (production_id)
    REFERENCES prodcution (production_id)
;

-- Reference: production_details_production_orders (table: production_details)
ALTER TABLE production_details ADD CONSTRAINT production_details_production_orders
    FOREIGN KEY (production_order_id)
    REFERENCES production_orders (production_order_id)
;

-- Reference: production_order_products (table: production_orders)
ALTER TABLE production_orders ADD CONSTRAINT production_order_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
;

-- Reference: production_orders_order_details (table: production_orders)
ALTER TABLE production_orders ADD CONSTRAINT production_orders_order_details
    FOREIGN KEY (order_detail_id)
    REFERENCES order_details (order_detail_id)
;

-- Reference: products_details_components (table: products_details)
ALTER TABLE products_details ADD CONSTRAINT products_details_components
    FOREIGN KEY (component_id)
    REFERENCES components (component_id)
    ON DELETE CASCADE
;

-- Reference: products_details_products (table: products_details)
ALTER TABLE products_details ADD CONSTRAINT products_details_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
    ON DELETE CASCADE
;

-- End of file.