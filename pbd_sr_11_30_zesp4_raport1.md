# Podstawy baz danych

dzień i godz zajęć: śr 11:30

nr zespołu: 4

**Autorzy:** Filip Rutkowski, Dominik Wójcik, Weronika Latos

# 1. Wymagania i funkcje systemu

System służy do obsługi działalności firmy produkcyjno-usługowej zajmującej się wytwarzaniem oraz sprzedażą mebli, które są wyposażeniem pomieszczeń z urządzeniami komputerowymi (m. in. krzesła, biurka, biurka gamingowe, stoły, fotele biurowe, fotele gamingowe, ruchome stojaki na projektory oraz tablice interaktywne). System umożliwia monitorowanie procesu sprzedaży, stanów magazynowych, planowanie produkcji oraz obsługę zamówień klientów.

## Funkcje

Do podstawowych funkcji systemu należą:

- dodawanie oraz zarządzanie danymi klientów,
- tworzenie i obsługa zamówień klientów,
- obsługa i rejestracja płatności,
- monitorowanie stanu magazynu,
- naliczanie rabatów procentowych dla zamówień,
- wyliczanie kosztów zamówienia,
- przechowywanie statusu zamówienia,
- planowanie produkcji nowych mebli,
- tworzenie zleceń produkcyjnych na podstawie zamówień,

# 2. Baza danych

## Schemat bazy danych

![schema](images/project_1.png)

## Opis poszczególnych tabel

Z racji na to, że docelowa baza będzie w SQL Server, stosujemy `DATETIME2` zamiast `TIMESTAMP`. Poniżej odzwierciedlenie bieżącego stanu z pliku projekt.sql.

### tabela `company_customers`

```sql
CREATE TABLE company_customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    nip INT NOT NULL,
    email VARCHAR(255) NOT NULL
);
```

| Nazwa atrybutu | Typ          | Opis/Uwagi        |
| -------------- | ------------ | ----------------- |
| customer_id    | Integer      | Klucz główny (PK) |
| name           | Varchar(255) | Nazwa firmy       |
| nip            | Integer      | Numer NIP         |
| email          | Varchar(255) | E-mail firmowy    |

<br/>

### tabela `components`

```sql
CREATE TABLE components (
    component_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(5, 2) NOT NULL
);
```

| Nazwa atrybutu | Typ          | Opis/Uwagi                                    |
| -------------- | ------------ | --------------------------------------------- |
| component_id   | Integer      | Klucz główny (PK)                             |
| name           | Varchar(255) | Nazwa części (np. metal, tworzywo, robocizna) |
| price          | Decimal(5,2) | Cena jednostkowa części                       |

<br/>

### tabela `customers`

```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    type INT NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    postal_code VARCHAR(255) NOT NULL
);
```

| Nazwa atrybutu | Typ          | Opis/Uwagi                                                         |
| -------------- | ------------ | ------------------------------------------------------------------ |
| customer_id    | Integer      | Klucz główny (PK)                                                  |
| type           | Integer      | Typ klienta (FK do `company_customers` lub `individual_customers`) |
| address        | Varchar(255) | Ulica i numer                                                      |
| city           | Varchar(255) | Miejscowość                                                        |
| postal_code    | Varchar(255) | Kod pocztowy                                                       |

<br/>

### tabela `individual_customers`

```sql
CREATE TABLE individual_customers (
    customer_id INT PRIMARY KEY,
    firstname VARCHAR(255) NOT NULL,
    lastname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL
);
```

| Nazwa atrybutu | Typ          | Opis/Uwagi        |
| -------------- | ------------ | ----------------- |
| customer_id    | Integer      | Klucz główny (PK) |
| firstname      | Varchar(255) | Imię klienta      |
| lastname       | Varchar(255) | Nazwisko klienta  |
| email          | Varchar(255) | Adres e-mail      |

<br/>

### tabela `products`

```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    production_cost DECIMAL(10, 2) NOT NULL,
    units_per_day INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    units_in_stock INT NOT NULL
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
    unit_price DECIMAL(5, 2) NOT NULL,
    CONSTRAINT products_details_pk PRIMARY KEY (product_id, component_id)
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

### tabela `orders`

```sql
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME2 NOT NULL,
    planed_ready_date DATETIME2 NOT NULL,
    collect_date DATETIME2 NULL,
    discount DECIMAL(3, 2) NOT NULL,
    price DECIMAL(12, 2) NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE NONCLUSTERED INDEX customer_id_idx ON orders (customer_id ASC);
```

| Nazwa atrybutu    | Typ           | Opis/Uwagi                            |
| ----------------- | ------------- | ------------------------------------- |
| order_id          | Integer       | Klucz główny (PK)                     |
| customer_id       | Integer       | FK do `customers`                     |
| order_date        | DATETIME2     | Data złożenia zamówienia              |
| planed_ready_date | DATETIME2     | Oczekiwana data realizacji zamówienia |
| collect_date      | DATETIME2     | Data odbioru (opcjonalna)             |
| discount          | Decimal(3,2)  | Rabat procentowy (0.00–0.99)          |
| price             | Decimal(12,2) | Łączna cena po rabacie                |
| status            | Varchar(30)   | Status zamówienia                     |

<br/>

### tabela `order_details`

```sql
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
    payment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    payment_date DATETIME2 NOT NULL,
    status VARCHAR(30) NOT NULL
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
    production_order_id INT PRIMARY KEY,
    order_detail_id INT NULL,
    order_date DATETIME2 NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(30) NOT NULL
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
    CONSTRAINT production_details_pk PRIMARY KEY (production_id, production_order_id)
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
    production_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    production_start DATE NOT NULL,
    porductiion_finish DATE NOT NULL,
    quantity INT NOT NULL,
    status INT NOT NULL
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
-- orders -> customers
ALTER TABLE orders ADD CONSTRAINT orders_customers
    FOREIGN KEY (customer_id)
    REFERENCES customers (customer_id);

-- customers -> company_customers (inheritance)
ALTER TABLE customers ADD CONSTRAINT customers_company_customers
    FOREIGN KEY (customer_id)
    REFERENCES company_customers (customer_id);

-- customers -> individual_customers (inheritance)
ALTER TABLE customers ADD CONSTRAINT customers_individual_customers
    FOREIGN KEY (customer_id)
    REFERENCES individual_customers (customer_id);

-- order_details -> orders / products
ALTER TABLE order_details ADD CONSTRAINT order_details_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id)
    ON DELETE CASCADE;
ALTER TABLE order_details ADD CONSTRAINT order_details_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
    ON DELETE CASCADE;

-- payments -> orders
ALTER TABLE payments ADD CONSTRAINT payment_order
    FOREIGN KEY (order_id)
    REFERENCES orders (order_id);

-- prodcution -> products
ALTER TABLE prodcution ADD CONSTRAINT prodcution_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id);

-- production_details -> prodcution / production_orders
ALTER TABLE production_details ADD CONSTRAINT production_details_prodcution
    FOREIGN KEY (production_id)
    REFERENCES prodcution (production_id);
ALTER TABLE production_details ADD CONSTRAINT production_details_production_orders
    FOREIGN KEY (production_order_id)
    REFERENCES production_orders (production_order_id);

-- production_orders -> products / order_details
ALTER TABLE production_orders ADD CONSTRAINT production_order_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id);
ALTER TABLE production_orders ADD CONSTRAINT production_orders_order_details
    FOREIGN KEY (order_detail_id)
    REFERENCES order_details (order_detail_id);

-- products_details -> components / products
ALTER TABLE products_details ADD CONSTRAINT products_details_components
    FOREIGN KEY (component_id)
    REFERENCES components (component_id)
    ON DELETE CASCADE;
ALTER TABLE products_details ADD CONSTRAINT products_details_products
    FOREIGN KEY (product_id)
    REFERENCES products (product_id)
    ON DELETE CASCADE;
```
