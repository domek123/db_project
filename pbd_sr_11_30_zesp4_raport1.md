# Podstawy baz danych

dzień i godz zajęć: śr 11:30

nr zespołu: 4

**Autorzy:** Filip Rutkowski, Dominik Wójcik, Weronika Latos

# 1. Wymagania i funkcje systemu

System służy do obsługi działalności firmy produkcyjno-usługowej zajmującej się wytwarzaniem oraz sprzedażą mebli, które są wyposażeniem pomieszczeń z urządzeniami komputerowymi (m. in. krzesła, biurka, biurka gamingowe, stoły, fotele biurowe, fotele gamingowe, ruchome stojaki na projektory oraz tablice interaktywne). System umożliwia monitorowanie procesu sprzedaży, stanów magazynowych, planowanie produkcji oraz obsługę zamówień klientów.

## funkcje

- dodawanie i obsługa zamówień
- obsługa płatności
- produkcja nowych mebli
- aktualizowanie stanu magazynu

# 2. Baza danych

## Schemat bazy danych

![schema](images/project_1.png)

## Opis poszczególnych tabel

Z racji na to, że docelowa baza będzie w SQL Server, stosujemy `DATETIME2` zamiast `TIMESTAMP`. Poniżej odzwierciedlenie bieżącego stanu z pliku projekt.sql (Redgate Data Modeler, 2025-12-15).

### tabela `components`

```sql
CREATE TABLE components (
    component_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(5,2) NOT NULL,
    CONSTRAINT components_pk PRIMARY KEY CLUSTERED (component_id)
);
```

| Nazwa atrybutu | Typ          | Opis/Uwagi                                    |
| -------------- | ------------ | --------------------------------------------- |
| component_id   | Integer      | Klucz główny (PK)                             |
| name           | Varchar(255) | Nazwa części (np. metal, tworzywo, robocizna) |
| price          | Decimal(5,2) | Cena jednostkowa części                       |

<br/>

### tabela `products`

```sql
CREATE TABLE products (
    product_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    production_cost DECIMAL(10,2) NOT NULL,
    units_per_day INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    units_in_stock INT NOT NULL,
    CONSTRAINT products_pk PRIMARY KEY CLUSTERED (product_id)
);
```

| Nazwa atrybutu  | Typ           | Opis/Uwagi                               |
| --------------- | ------------- | ---------------------------------------- |
| product_id      | Integer       | Klucz główny (PK)                        |
| name            | Varchar(255)  | Nazwa produktu                           |
| production_cost | Decimal(10,2) | Koszt wytworzenia jednostkowego produktu |
| units_per_day   | Integer       | Wydajność produkcji (sztuki dziennie)    |
| unit_price      | Decimal(10,2) | Cena sprzedaży jednostkowego produktu    |
| units_in_stock  | Integer       | Aktualny stan magazynowy produktu        |

<br/>

### tabela `products_details`

```sql
CREATE TABLE products_details (
    product_id INT NOT NULL,
    component_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(5,2) NOT NULL,
    CONSTRAINT products_details_pk PRIMARY KEY CLUSTERED (product_id,component_id)
);

CREATE NONCLUSTERED INDEX products_details_component_idx ON products_details (component_id ASC);
CREATE NONCLUSTERED INDEX products_details_product_idx ON products_details (product_id ASC);
```

| Nazwa atrybutu | Typ          | Opis/Uwagi                                                         |
| -------------- | ------------ | ------------------------------------------------------------------ |
| product_id     | Integer      | PK, FK do `products`                                               |
| component_id   | Integer      | PK, FK do `components`                                             |
| quantity       | Integer      | Ilość danej części potrzebna do wytworzenia jednej sztuki produktu |
| unit_price     | Decimal(5,2) | Koszt jednostkowy danej części użytej w produkcie                  |

<br/>

### tabela `company_customers`

```sql
CREATE TABLE company_customers (
    company_id INT NOT NULL,
    name NVARCHAR(255) NOT NULL,
    nip INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    postal_code VARCHAR(255) NOT NULL,
    CONSTRAINT company_customers_pk PRIMARY KEY CLUSTERED (company_id)
);
```

| Nazwa atrybutu | Typ           | Opis/Uwagi        |
| -------------- | ------------- | ----------------- |
| company_id     | Integer       | Klucz główny (PK) |
| name           | NVarchar(255) | Nazwa firmy       |
| nip            | Integer       | Numer NIP         |
| email          | Varchar(255)  | E-mail firmowy    |
| address        | Varchar(255)  | Ulica i numer     |
| city           | Varchar(255)  | Miejscowość       |
| postal_code    | Varchar(255)  | Kod pocztowy      |

<br/>

### tabela `individual_customers`

```sql
CREATE TABLE individual_customers (
    customer_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    postal_code VARCHAR(255) NOT NULL,
    CONSTRAINT individual_customers_pk PRIMARY KEY CLUSTERED (customer_id)
);
```

| Nazwa atrybutu | Typ          | Opis/Uwagi              |
| -------------- | ------------ | ----------------------- |
| customer_id    | Integer      | Klucz główny (PK)       |
| name           | Varchar(255) | Imię i nazwisko klienta |
| email          | Varchar(255) | Adres e-mail            |
| address        | Varchar(255) | Ulica i numer           |
| city           | Varchar(255) | Miejscowość             |
| postal_code    | Varchar(255) | Kod pocztowy            |

<br/>

### tabela `orders`

```sql
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

CREATE NONCLUSTERED INDEX order_customer_idx ON orders (customer_id ASC);
```

| Nazwa atrybutu    | Typ              | Opis/Uwagi                                                                     |
| ----------------- | ---------------- | ------------------------------------------------------------------------------ |
| order_id          | Integer          | Klucz główny (PK)                                                              |
| customer_id       | Integer          | FK do `individual_customers` lub `company_customers` (dwie relacje równoległe) |
| order_date        | DATETIME2        | Data złożenia zamówienia                                                       |
| planed_ready_date | DATETIME2        | Oczekiwana data realizacji zamówienia                                          |
| collect_date      | DATETIME2 / NULL | Data odbioru (opcjonalna)                                                      |
| discount          | Decimal(3,2)     | Rabat procentowy przydzielony do zamówienia (0.00–0.99)                        |
| price             | Decimal(12,2)    | Łączna cena zamówienia po rabacie                                              |
| status            | Varchar(30)      | Status zamówienia (np. 'Nowe', 'Realizowane', 'Zakończone')                    |

<br/>

### tabela `order_details`

```sql
CREATE TABLE order_details (
    order_detail_id INT NOT NULL,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT order_details_pk PRIMARY KEY CLUSTERED (order_detail_id)
);

CREATE NONCLUSTERED INDEX order_details_order_idx ON order_details (order_id ASC);
CREATE NONCLUSTERED INDEX order_details_product_idx ON order_details (product_id ASC);
```

| Nazwa atrybutu  | Typ           | Opis/Uwagi                                                |
| --------------- | ------------- | --------------------------------------------------------- |
| order_detail_id | Integer       | Klucz główny (PK)                                         |
| order_id        | Integer       | FK do `orders`                                            |
| product_id      | Integer       | FK do `products`                                          |
| quantity        | Integer       | Ilość zamówionego produktu                                |
| unit_price      | Decimal(10,2) | Cena jednostkowa produktu w momencie złożenia zamówienia  |
| status          | Varchar(30)   | Status pozycji (np. 'Oczekuje', 'W realizacji', 'Gotowe') |

<br/>

### tabela `payments`

```sql
CREATE TABLE payments (
    payment_id INT NOT NULL,
    order_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    payment_date DATETIME2 NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT payments_pk PRIMARY KEY CLUSTERED (payment_id)
);

CREATE NONCLUSTERED INDEX payment_idx_1 ON payments (order_id ASC);
```

| Nazwa atrybutu | Typ           | Opis/Uwagi                                          |
| -------------- | ------------- | --------------------------------------------------- |
| payment_id     | Integer       | Klucz główny (PK)                                   |
| order_id       | Integer       | FK do `orders`                                      |
| price          | Decimal(10,2) | Kwota płatności                                     |
| payment_date   | DATETIME2     | Data i czas realizacji płatności                    |
| status         | Varchar(30)   | Status płatności ('Zrealizowana', 'Anulowana' itp.) |

<br/>

### tabela `production_orders`

```sql
CREATE TABLE production_orders (
    production_order_id INT NOT NULL,
    order_detail_id INT NULL,
    order_date DATETIME2 NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT production_orders_pk PRIMARY KEY CLUSTERED (production_order_id)
);

CREATE NONCLUSTERED INDEX production_order_product_idx ON production_orders (product_id ASC);
```

| Nazwa atrybutu      | Typ          | Opis/Uwagi                                                        |
| ------------------- | ------------ | ----------------------------------------------------------------- |
| production_order_id | Integer      | Klucz główny (PK)                                                 |
| order_detail_id     | Integer/NULL | FK do `order_details` (powiązanie z konkretną pozycją zamówienia) |
| order_date          | DATETIME2    | Data utworzenia zlecenia produkcyjnego                            |
| product_id          | Integer      | FK do `products`                                                  |
| quantity            | Integer      | Ilość produktu do wytworzenia                                     |
| status              | Varchar(30)  | Status zlecenia (np. 'Planowane', 'W produkcji', 'Zakończone')    |

<br/>

### tabela `production_details`

```sql
CREATE TABLE production_details (
    production_id INT NOT NULL,
    production_order_id INT NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT production_details_pk PRIMARY KEY CLUSTERED (production_id,production_order_id)
);
```

| Nazwa atrybutu      | Typ         | Opis/Uwagi                        |
| ------------------- | ----------- | --------------------------------- |
| production_id       | Integer     | PK, FK do `prodcution`            |
| production_order_id | Integer     | PK, FK do `production_orders`     |
| quantity            | Integer     | Ilość zrealizowana w danej partii |
| status              | Varchar(30) | Status etapu produkcji            |

<br/>

### tabela `prodcution` (pisownia jak w pliku)

```sql
CREATE TABLE prodcution (
    production_id INT NOT NULL,
    product_id INT NOT NULL,
    production_start DATE NOT NULL,
    porductiion_finish DATE NOT NULL,
    quantity INT NOT NULL,
    status INT NOT NULL,
    CONSTRAINT prodcution_pk PRIMARY KEY CLUSTERED (production_id)
);
```

| Nazwa atrybutu     | Typ     | Opis/Uwagi                                                     |
| ------------------ | ------- | -------------------------------------------------------------- |
| production_id      | Integer | Klucz główny (PK)                                              |
| product_id         | Integer | FK do `products`                                               |
| production_start   | Date    | Data startu produkcji                                          |
| porductiion_finish | Date    | Data zakończenia (kolumna z literówką w nazwie, zgodnie z SQL) |
| quantity           | Integer | Łączna ilość w danej produkcji                                 |
| status             | Integer | Kod statusu                                                    |

<br/>

## Klucze obce

```sql
-- orders -> individual_customers
ALTER TABLE orders ADD CONSTRAINT order_customer
    FOREIGN KEY (customer_id)
    REFERENCES individual_customers (customer_id)
    ON DELETE CASCADE;

-- orders -> company_customers (równoległa relacja)
ALTER TABLE orders ADD CONSTRAINT orders_company_customers
    FOREIGN KEY (customer_id)
    REFERENCES company_customers (company_id);

-- order_details -> orders / products
ALTER TABLE order_details ADD CONSTRAINT order_details_order
    FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE;
ALTER TABLE order_details ADD CONSTRAINT order_details_products
    FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE;

-- payments -> orders
ALTER TABLE payments ADD CONSTRAINT payment_order
    FOREIGN KEY (order_id) REFERENCES orders (order_id);

-- prodcution -> products
ALTER TABLE prodcution ADD CONSTRAINT prodcution_products
    FOREIGN KEY (product_id) REFERENCES products (product_id);

-- production_details -> prodcution / production_orders
ALTER TABLE production_details ADD CONSTRAINT production_details_prodcution
    FOREIGN KEY (production_id) REFERENCES prodcution (production_id);
ALTER TABLE production_details ADD CONSTRAINT production_details_production_orders
    FOREIGN KEY (production_order_id) REFERENCES production_orders (production_order_id);

-- production_orders -> products / order_details
ALTER TABLE production_orders ADD CONSTRAINT production_order_products
    FOREIGN KEY (product_id) REFERENCES products (product_id);
ALTER TABLE production_orders ADD CONSTRAINT production_orders_order_details
    FOREIGN KEY (order_detail_id) REFERENCES order_details (order_detail_id);

-- products_details -> components / products
ALTER TABLE products_details ADD CONSTRAINT products_details_components
    FOREIGN KEY (component_id) REFERENCES components (component_id) ON DELETE CASCADE;
ALTER TABLE products_details ADD CONSTRAINT products_details_products
    FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE;
```
