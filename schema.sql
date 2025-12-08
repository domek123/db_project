-- Table: components
CREATE TABLE components (
    component_id INT NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Table: customers
CREATE TABLE customers (
    customer_id INT NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    postal_code VARCHAR(255) NOT NULL
);

-- Table: products
CREATE TABLE products (
    product_id INT NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    production_cost INT NOT NULL,
    production_time INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL
);

-- Table: products_details
CREATE TABLE products_details (
    product_id INT NOT NULL,
    component_id INT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (product_id, component_id)
);

-- Table: orders
CREATE TABLE orders (
    order_id INT NOT NULL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    required_date DATETIME NOT NULL,
    discount DECIMAL(5,2) NOT NULL,
    price DECIMAL(12,2) NOT NULL
);

-- Table: order_details
CREATE TABLE order_details (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

-- Table: payments
CREATE TABLE payments (
    payment_id INT NOT NULL PRIMARY KEY,
    order_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    payment_date DATETIME NOT NULL,
    status VARCHAR(30) NOT NULL
);

-- Table: product_stock
CREATE TABLE product_stock (
    product_id INT NOT NULL PRIMARY KEY,
    quantity_available INT NOT NULL,
    last_update DATETIME NOT NULL
);

-- Table: production_orders
CREATE TABLE production_orders (
    production_order_id INT NOT NULL PRIMARY KEY,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    planned_start DATETIME NOT NULL,
    planned_finish DATETIME NOT NULL,
    status VARCHAR(30) NOT NULL
);

-- indexes
CREATE INDEX order_details_order_idx ON order_details (order_id);
CREATE INDEX order_details_product_idx ON order_details (product_id);
CREATE INDEX order_customer_idx ON orders (customer_id);
CREATE INDEX production_order_product_idx ON production_orders (product_id);
CREATE INDEX products_details_component_idx ON products_details (component_id);
CREATE INDEX products_details_product_idx ON products_details (product_id);

-- foreign keys
ALTER TABLE orders
    ADD CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id) ON DELETE CASCADE;

ALTER TABLE order_details
    ADD CONSTRAINT FK_order_details_orders FOREIGN KEY (order_id)
    REFERENCES orders(order_id) ON DELETE CASCADE;

ALTER TABLE order_details
    ADD CONSTRAINT FK_order_details_products FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE CASCADE;

ALTER TABLE payments
    ADD CONSTRAINT FK_payments_orders FOREIGN KEY (order_id)
    REFERENCES orders(order_id);

ALTER TABLE product_stock
    ADD CONSTRAINT FK_product_stock_products FOREIGN KEY (product_id)
    REFERENCES products(product_id);

ALTER TABLE production_orders
    ADD CONSTRAINT FK_production_orders_products FOREIGN KEY (product_id)
    REFERENCES products(product_id);

ALTER TABLE products_details
    ADD CONSTRAINT FK_products_details_components FOREIGN KEY (component_id)
    REFERENCES components(component_id) ON DELETE CASCADE;

ALTER TABLE products_details
    ADD CONSTRAINT FK_products_details_products FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE CASCADE;
