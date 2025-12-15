-- Created by Redgate Data Modeler (https://datamodeler.redgate-platform.com)
-- Last modification date: 2025-12-15 20:13:11.133

-- Set the database context (Optional, but good practice)
-- USE YourDatabaseName;
-- GO

-- Drop tables if they exist to allow re-creation in a clean environment (Optional)
-- Note: You would need to drop FKs first, but for conversion, we focus on creation.

-- tables
---
-- Table: company_customers
CREATE TABLE company_customers (
    company_id INT NOT NULL,
    name NVARCHAR(255) NOT NULL, -- Changed type from INT to NVARCHAR(255) to hold a company name
    nip INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    postal_code VARCHAR(255) NOT NULL,
    CONSTRAINT company_customers_pk PRIMARY KEY CLUSTERED (company_id)
);
GO

---
-- Table: components
CREATE TABLE components (
    component_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(5,2) NOT NULL,
    CONSTRAINT components_pk PRIMARY KEY CLUSTERED (component_id)
);
GO

---
-- Table: individual_customers
CREATE TABLE individual_customers (
    customer_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    postal_code VARCHAR(255) NOT NULL,
    CONSTRAINT individual_customers_pk PRIMARY KEY CLUSTERED (customer_id)
);
GO

---
-- Table: orders
-- DATETIME2 is generally preferred over DATETIME for precision and range.
CREATE TABLE orders (
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    order_date DATETIME2 NOT NULL,
    planed_ready_date DATETIME2 NOT NULL,
    collect_date DATETIME2 NULL,
    discount DECIMAL(3,2) NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT orders_pk PRIMARY KEY CLUSTERED (order_id)
);
GO

CREATE NONCLUSTERED INDEX order_customer_idx ON orders (customer_id ASC);
GO

---
-- Table: products
CREATE TABLE products (
    product_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    production_cost DECIMAL(10,2) NOT NULL,
    units_per_day INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    units_in_stock INT NOT NULL,
    CONSTRAINT products_pk PRIMARY KEY CLUSTERED (product_id)
);
GO

---
-- Table: order_details
CREATE TABLE order_details (
    order_detail_id INT NOT NULL,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT order_details_pk PRIMARY KEY CLUSTERED (order_detail_id)
);
GO

CREATE NONCLUSTERED INDEX order_details_order_idx ON order_details (order_id ASC);
GO

CREATE NONCLUSTERED INDEX order_details_product_idx ON order_details (product_id ASC);
GO

---
-- Table: payments
CREATE TABLE payments (
    payment_id INT NOT NULL,
    order_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    payment_date DATETIME2 NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT payments_pk PRIMARY KEY CLUSTERED (payment_id)
);
GO

CREATE NONCLUSTERED INDEX payment_idx_1 ON payments (order_id ASC);
GO

---
-- Table: prodcution (Typo: 'prodcution' should probably be 'production')
CREATE TABLE prodcution (
    production_id INT NOT NULL,
    product_id INT NOT NULL,
    production_start DATE NOT NULL,
    porductiion_finish DATE NOT NULL, -- Typo: 'porductiion_finish'
    quantity INT NOT NULL,
    status INT NOT NULL,
    CONSTRAINT prodcution_pk PRIMARY KEY CLUSTERED (production_id)
);
GO

---
-- Table: production_orders
CREATE TABLE production_orders (
    production_order_id INT NOT NULL,
    order_detail_id INT NULL,
    order_date DATETIME2 NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT production_orders_pk PRIMARY KEY CLUSTERED (production_order_id)
);
GO

CREATE NONCLUSTERED INDEX production_order_product_idx ON production_orders (product_id ASC);
GO

---
-- Table: production_details
CREATE TABLE production_details (
    production_id INT NOT NULL,
    production_order_id INT NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT production_details_pk PRIMARY KEY CLUSTERED (production_id,production_order_id)
);
GO

---
-- Table: products_details
CREATE TABLE products_details (
    product_id INT NOT NULL,
    component_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(5,2) NOT NULL,
    CONSTRAINT products_details_pk PRIMARY KEY CLUSTERED (product_id,component_id)
);
GO

CREATE NONCLUSTERED INDEX products_details_component_idx ON products_details (component_id ASC);
GO

CREATE NONCLUSTERED INDEX products_details_product_idx ON products_details (product_id ASC);
GO

---
-- foreign keys

-- Reference: order_customer (table: orders) - Link to individual_customers
ALTER TABLE orders ADD CONSTRAINT order_customer
    FOREIGN KEY (customer_id)
    REFERENCES individual_customers (customer_id)
    ON DELETE CASCADE
;
GO

-- Reference: orders_company_customers (table: orders) - Link to company_customers
-- This FK is problematic as orders.customer_id is already linked to individual_customers (FK order_customer).
-- This implies a single table is being used for both individual and company customers, which is poor design.
-- Assuming this is an **inheritance** structure (One customer_id can only be in ONE of the customer tables), or this is an **error** in the original schema.
-- For T-SQL, it will be created, but note the data integrity issue.
ALTER TABLE orders ADD CONSTRAINT orders_company_customers
    FOREIGN KEY (customer_id)
    REFERENCES company_customers (company_id)
;
GO

-- Reference: order_details_order (table: order_details)
ALTER TABLE order_details ADD CONSTRAINT order_details_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id)
    ON DELETE CASCADE
;
GO

-- Reference: order_details_products (table: order_details)
ALTER TABLE order_details ADD CONSTRAINT order_details_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
    ON DELETE CASCADE
;
GO

-- Reference: payment_order (table: payments)
ALTER TABLE payments ADD CONSTRAINT payment_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id)
;
GO

-- Reference: prodcution_products (table: prodcution)
ALTER TABLE prodcution ADD CONSTRAINT prodcution_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
;
GO

-- Reference: production_details_prodcution (table: production_details)
ALTER TABLE production_details ADD CONSTRAINT production_details_prodcution
    FOREIGN KEY (production_id)
    REFERENCES prodcution (production_id)
;
GO

-- Reference: production_details_production_orders (table: production_details)
ALTER TABLE production_details ADD CONSTRAINT production_details_production_orders
    FOREIGN KEY (production_order_id)
    REFERENCES production_orders (production_order_id)
;
GO

-- Reference: production_order_products (table: production_orders)
ALTER TABLE production_orders ADD CONSTRAINT production_order_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
;
GO

-- Reference: production_orders_order_details (table: production_orders)
ALTER TABLE production_orders ADD CONSTRAINT production_orders_order_details
    FOREIGN KEY (order_detail_id)
    REFERENCES order_details (order_detail_id)
;
GO

-- Reference: products_details_components (table: products_details)
ALTER TABLE products_details ADD CONSTRAINT products_details_components
    FOREIGN KEY (component_id)
    REFERENCES components (component_id)
    ON DELETE CASCADE
;
GO

-- Reference: products_details_products (table: products_details)
ALTER TABLE products_details ADD CONSTRAINT products_details_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
    ON DELETE CASCADE
;
GO

-- End of file.