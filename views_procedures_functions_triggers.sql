-- ============================================================
-- WIDOKI, PROCEDURY, FUNKCJE I TRIGGERY
-- Projekt: System obsługi firmy produkcyjno-usługowej
-- ============================================================

-- ============================================================
-- WIDOKI (VIEWS)
-- ============================================================

-- VIEW: Dostępne produkty w magazynie
CREATE OR ALTER VIEW vw_available_products AS
SELECT 
    p.product_id,
    p.name AS product_name,
    p.unit_price,
    p.units_in_stock AS available_quantity,
    p.production_cost,
    p.units_per_day
FROM products p
WHERE p.units_in_stock > 0
GO

-- VIEW: Zamówienia oczekujące na realizację
CREATE OR ALTER VIEW vw_pending_orders AS
SELECT 
    o.order_id,
    o.order_date,
    o.planed_ready_date,
    o.status,
    c.customer_id,
    CASE 
        WHEN c.customer_id IN (SELECT customer_id FROM individual_customers) 
            THEN (SELECT CONCAT(ic.firstname, ' ', ic.lastname) FROM individual_customers ic WHERE ic.customer_id = c.customer_id)
        WHEN c.customer_id IN (SELECT customer_id FROM company_customers) 
            THEN (SELECT cc.name FROM company_customers cc WHERE cc.customer_id = c.customer_id)
    END AS customer_name,
    o.price,
    o.discount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status IN ('Nowe', 'Realizowane')
ORDER BY o.planed_ready_date ASC
GO

-- VIEW: Szczegóły zamówień z produktami
CREATE OR ALTER VIEW vw_order_details_summary AS
SELECT 
    o.order_id,
    o.order_date,
    od.order_detail_id,
    p.product_id,
    p.name AS product_name,
    od.quantity,
    od.unit_price,
    (od.quantity * od.unit_price) AS line_total,
    od.status AS detail_status,
    o.status AS order_status
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
GO

-- VIEW: Stan magazynu produktów
CREATE OR ALTER VIEW vw_inventory_status AS
SELECT 
    p.product_id,
    p.name AS product_name,
    p.units_in_stock AS current_stock,
    p.units_per_day AS daily_production,
    p.unit_price,
    CASE 
        WHEN p.units_in_stock = 0 THEN 'Brak w magazynie'
        WHEN p.units_in_stock < p.units_per_day THEN 'Niski stan'
        ELSE 'Dostępny'
    END AS stock_status
FROM products p
GO

-- VIEW: Harmonogram produkcji
CREATE OR ALTER VIEW vw_production_schedule AS
SELECT 
    po.production_order_id,
    po.order_date AS production_created_date,
    po.product_id,
    p.name AS product_name,
    po.quantity AS quantity_to_produce,
    po.status AS production_status,
    pd.quantity AS quantity_completed
FROM production_orders po
JOIN products p ON po.product_id = p.product_id
LEFT JOIN production_details pd ON po.production_order_id = pd.production_order_id
WHERE po.status IN ('Planowane', 'W produkcji')
ORDER BY po.order_date ASC
GO

-- VIEW: Przychody z płatności
CREATE OR ALTER VIEW vw_payment_summary AS
SELECT 
    p.payment_id,
    p.order_id,
    o.order_date,
    p.price AS payment_amount,
    p.payment_date,
    p.status AS payment_status,
    o.status AS order_status,
    DATEDIFF(DAY, o.order_date, p.payment_date) AS days_to_payment
FROM payments p
JOIN orders o ON p.order_id = o.order_id
GO

-- VIEW: Klienci - zmieniona struktura (łączenie informacji)
CREATE OR ALTER VIEW vw_customers_unified AS
SELECT 
    c.customer_id,
    c.address,
    c.city,
    c.postal_code,
    CASE 
        WHEN EXISTS (SELECT 1 FROM individual_customers ic WHERE ic.customer_id = c.customer_id)
            THEN 'Indywidualny'
        WHEN EXISTS (SELECT 1 FROM company_customers cc WHERE cc.customer_id = c.customer_id)
            THEN 'Firma'
        ELSE 'Nieznany'
    END AS customer_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM individual_customers ic WHERE ic.customer_id = c.customer_id)
            THEN (SELECT CONCAT(ic.firstname, ' ', ic.lastname) FROM individual_customers ic WHERE ic.customer_id = c.customer_id)
        ELSE (SELECT cc.name FROM company_customers cc WHERE cc.customer_id = c.customer_id)
    END AS name_or_company,
    CASE 
        WHEN EXISTS (SELECT 1 FROM individual_customers ic WHERE ic.customer_id = c.customer_id)
            THEN (SELECT ic.email FROM individual_customers ic WHERE ic.customer_id = c.customer_id)
        ELSE (SELECT cc.email FROM company_customers cc WHERE cc.customer_id = c.customer_id)
    END AS email
FROM customers c
GO

-- ============================================================
-- FUNKCJE (FUNCTIONS)
-- ============================================================

-- FUNCTION: Oblicz rabat dla zamówienia
CREATE OR ALTER FUNCTION fn_calculate_discount(
    @discount_percentage DECIMAL(3, 2),
    @order_total DECIMAL(12, 2)
)
RETURNS DECIMAL(12, 2)
AS
BEGIN
    RETURN @order_total * (@discount_percentage / 100)
END
GO

-- FUNCTION: Oblicz cenę finalną zamówienia
CREATE OR ALTER FUNCTION fn_calculate_order_total(
    @order_id INT
)
RETURNS DECIMAL(12, 2)
AS
BEGIN
    DECLARE @subtotal DECIMAL(12, 2) = 0
    DECLARE @discount_amount DECIMAL(12, 2) = 0
    DECLARE @final_price DECIMAL(12, 2) = 0
    
    SELECT @subtotal = SUM(quantity * unit_price)
    FROM order_details
    WHERE order_id = @order_id
    
    SELECT @discount_amount = dbo.fn_calculate_discount(discount, ISNULL(@subtotal, 0))
    FROM orders
    WHERE order_id = @order_id
    
    SET @final_price = ISNULL(@subtotal, 0) - ISNULL(@discount_amount, 0)
    
    RETURN CASE WHEN @final_price < 0 THEN 0 ELSE @final_price END
END
GO

-- FUNCTION: Sprawdź dostępność produktu
CREATE OR ALTER FUNCTION fn_check_product_availability(
    @product_id INT,
    @required_quantity INT
)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @available INT
    
    SELECT @available = units_in_stock FROM products WHERE product_id = @product_id
    
    IF @available >= @required_quantity
        RETURN 'Dostępny'
    ELSE IF @available > 0 AND @available < @required_quantity
        RETURN 'Częściowo dostępny'
    ELSE
        RETURN 'Niedostępny'
END
GO

-- FUNCTION: Oblicz czas produkcji (w dniach)
CREATE OR ALTER FUNCTION fn_calculate_production_time(
    @product_id INT,
    @quantity INT
)
RETURNS INT
AS
BEGIN
    DECLARE @units_per_day INT
    DECLARE @production_days INT
    
    SELECT @units_per_day = units_per_day FROM products WHERE product_id = @product_id
    
    IF @units_per_day <= 0
        RETURN 0
    
    SET @production_days = CEILING(CAST(@quantity AS FLOAT) / CAST(@units_per_day AS FLOAT))
    
    RETURN @production_days
END
GO

-- FUNCTION: Pobierz ostatnią płatność dla zamówienia
CREATE OR ALTER FUNCTION fn_get_last_payment_date(
    @order_id INT
)
RETURNS DATETIME2
AS
BEGIN
    DECLARE @last_payment_date DATETIME2
    
    SELECT @last_payment_date = MAX(payment_date)
    FROM payments
    WHERE order_id = @order_id AND status = 'Zrealizowana'
    
    RETURN ISNULL(@last_payment_date, NULL)
END
GO

-- ============================================================
-- PROCEDURY PRZECHOWYWANE (STORED PROCEDURES)
-- ============================================================

-- PROCEDURE: Utwórz nowe zamówienie
CREATE OR ALTER PROCEDURE sp_create_order
    @customer_id INT,
    @order_date DATETIME2,
    @planed_ready_date DATETIME2,
    @discount DECIMAL(3, 2) = 0,
    @status VARCHAR(30) = 'Nowe',
    @new_order_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Wstaw nowe zamówienie
        INSERT INTO orders (customer_id, order_date, planed_ready_date, discount, price, status)
        VALUES (@customer_id, @order_date, @planed_ready_date, @discount, 0, @status)
        
        SET @new_order_id = SCOPE_IDENTITY()
        
        COMMIT TRANSACTION
        PRINT 'Zamówienie ' + CAST(@new_order_id AS NVARCHAR(10)) + ' zostało utworzone.'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Błąd: ' + ERROR_MESSAGE()
        SET @new_order_id = -1
    END CATCH
END
GO

-- PROCEDURE: Dodaj pozycję do zamówienia
CREATE OR ALTER PROCEDURE sp_add_order_detail
    @order_id INT,
    @product_id INT,
    @quantity INT,
    @status VARCHAR(30) = 'Oczekuje'
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        BEGIN TRANSACTION
        
        DECLARE @unit_price DECIMAL(10, 2)
        DECLARE @availability NVARCHAR(50)
        
        -- Pobierz cenę produktu
        SELECT @unit_price = unit_price FROM products WHERE product_id = @product_id
        
        IF @unit_price IS NULL
        BEGIN
            THROW 50001, 'Produkt nie istnieje', 1
        END
        
        -- Sprawdź dostępność
        SET @availability = dbo.fn_check_product_availability(@product_id, @quantity)
        
        -- Wstaw pozycję zamówienia
        INSERT INTO order_details (order_id, product_id, quantity, unit_price, status)
        VALUES (@order_id, @product_id, @quantity, @unit_price, @status)
        
        -- Jeśli produkt jest dostępny, zmniejsz stan magazynu
        IF @availability IN ('Dostępny', 'Częściowo dostępny')
        BEGIN
            UPDATE products
            SET units_in_stock = units_in_stock - CASE 
                WHEN units_in_stock >= @quantity THEN @quantity
                ELSE units_in_stock
            END
            WHERE product_id = @product_id
        END
        
        -- Zaktualizuj cenę zamówienia
        UPDATE orders
        SET price = dbo.fn_calculate_order_total(@order_id)
        WHERE order_id = @order_id
        
        COMMIT TRANSACTION
        PRINT 'Pozycja dodana do zamówienia ' + CAST(@order_id AS NVARCHAR(10)) + '.'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Błąd: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- PROCEDURE: Aktualizuj status zamówienia
CREATE OR ALTER PROCEDURE sp_update_order_status
    @order_id INT,
    @new_status VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        UPDATE orders
        SET status = @new_status
        WHERE order_id = @order_id
        
        IF @@ROWCOUNT > 0
            PRINT 'Status zamówienia ' + CAST(@order_id AS NVARCHAR(10)) + ' został zmieniony na: ' + @new_status
        ELSE
            PRINT 'Zamówienie nie znalezione.'
    END TRY
    BEGIN CATCH
        PRINT 'Błąd: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- PROCEDURE: Utwórz zlecenie produkcyjne
CREATE OR ALTER PROCEDURE sp_create_production_order
    @product_id INT,
    @quantity INT,
    @order_detail_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        BEGIN TRANSACTION
        
        DECLARE @production_days INT
        
        -- Oblicz czas produkcji
        SET @production_days = dbo.fn_calculate_production_time(@product_id, @quantity)
        
        -- Wstaw zlecenie produkcyjne
        INSERT INTO production_orders (order_detail_id, order_date, product_id, quantity, status)
        VALUES (@order_detail_id, GETDATE(), @product_id, @quantity, 'Planowane')
        
        COMMIT TRANSACTION
        PRINT 'Zlecenie produkcyjne zostało utworzone. Szacunkowy czas produkcji: ' + CAST(@production_days AS NVARCHAR(10)) + ' dni.'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Błąd: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- PROCEDURE: Rejestruj płatność
CREATE OR ALTER PROCEDURE sp_register_payment
    @order_id INT,
    @price DECIMAL(10, 2),
    @payment_date DATETIME2,
    @status VARCHAR(30) = 'Zrealizowana'
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        BEGIN TRANSACTION
        
        DECLARE @order_exists INT
        
        SELECT @order_exists = COUNT(*) FROM orders WHERE order_id = @order_id
        
        IF @order_exists = 0
        BEGIN
            THROW 50002, 'Zamówienie nie istnieje', 1
        END
        
        INSERT INTO payments (order_id, price, payment_date, status)
        VALUES (@order_id, @price, @payment_date, @status)
        
        -- Zaktualizuj status zamówienia na "Opłacone"
        UPDATE orders
        SET status = 'Opłacone'
        WHERE order_id = @order_id
        
        COMMIT TRANSACTION
        PRINT 'Płatność zarejestrowana dla zamówienia ' + CAST(@order_id AS NVARCHAR(10)) + '.'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Błąd: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- PROCEDURE: Zmniejsz stan magazynu
CREATE OR ALTER PROCEDURE sp_decrease_stock
    @product_id INT,
    @quantity INT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        DECLARE @current_stock INT
        
        SELECT @current_stock = units_in_stock FROM products WHERE product_id = @product_id
        
        IF @current_stock IS NULL
        BEGIN
            THROW 50003, 'Produkt nie istnieje', 1
        END
        
        IF @current_stock < @quantity
        BEGIN
            THROW 50004, 'Niewystarczająca ilość w magazynie', 1
        END
        
        UPDATE products
        SET units_in_stock = units_in_stock - @quantity
        WHERE product_id = @product_id
        
        PRINT 'Stan magazynu dla produktu ' + CAST(@product_id AS NVARCHAR(10)) + ' zmniejszony o ' + CAST(@quantity AS NVARCHAR(10)) + '.'
    END TRY
    BEGIN CATCH
        PRINT 'Błąd: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- PROCEDURE: Zwróć produkty do magazynu
CREATE OR ALTER PROCEDURE sp_increase_stock
    @product_id INT,
    @quantity INT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        DECLARE @product_exists INT
        
        SELECT @product_exists = COUNT(*) FROM products WHERE product_id = @product_id
        
        IF @product_exists = 0
        BEGIN
            THROW 50005, 'Produkt nie istnieje', 1
        END
        
        UPDATE products
        SET units_in_stock = units_in_stock + @quantity
        WHERE product_id = @product_id
        
        PRINT 'Stan magazynu dla produktu ' + CAST(@product_id AS NVARCHAR(10)) + ' zwiększony o ' + CAST(@quantity AS NVARCHAR(10)) + '.'
    END TRY
    BEGIN CATCH
        PRINT 'Błąd: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- PROCEDURE: Pobierz raportu zamówień w danym okresie
CREATE OR ALTER PROCEDURE sp_get_orders_report
    @start_date DATETIME2,
    @end_date DATETIME2
AS
BEGIN
    SET NOCOUNT ON
    
    SELECT 
        o.order_id,
        o.order_date,
        o.status,
        o.price,
        o.discount,
        COUNT(od.order_detail_id) AS total_items
    FROM orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    WHERE o.order_date BETWEEN @start_date AND @end_date
    GROUP BY o.order_id, o.order_date, o.status, o.price, o.discount
    ORDER BY o.order_date DESC
END
GO

-- ============================================================
-- TRIGGERY (TRIGGERS)
-- ============================================================

-- TRIGGER: Automatycznie utwórz zlecenie produkcyjne dla niedostępnych produktów
CREATE OR ALTER TRIGGER trg_create_production_order_on_order_detail
ON order_details
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @product_id INT
    DECLARE @quantity INT
    DECLARE @order_detail_id INT
    DECLARE @available_qty INT
    DECLARE @needed_qty INT
    
    -- Pobierz dane z wstawionego rekordu
    SELECT 
        @order_detail_id = order_detail_id,
        @product_id = product_id,
        @quantity = quantity
    FROM inserted
    
    -- Pobierz dostępną ilość
    SELECT @available_qty = units_in_stock FROM products WHERE product_id = @product_id
    
    -- Jeśli brakuje produktu, utwórz zlecenie produkcyjne
    IF @available_qty < @quantity
    BEGIN
        SET @needed_qty = @quantity - ISNULL(@available_qty, 0)
        
        INSERT INTO production_orders (order_detail_id, order_date, product_id, quantity, status)
        VALUES (@order_detail_id, GETDATE(), @product_id, @needed_qty, 'Planowane')
    END
END
GO

-- TRIGGER: Aktualizuj stan magazynu po zakończeniu produkcji
CREATE OR ALTER TRIGGER trg_update_stock_on_production_complete
ON production_details
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @production_id INT
    DECLARE @production_order_id INT
    DECLARE @quantity INT
    DECLARE @product_id INT
    
    SELECT 
        @production_id = production_id,
        @production_order_id = production_order_id,
        @quantity = quantity
    FROM inserted
    
    -- Pobierz product_id z production_orders
    SELECT @product_id = product_id FROM production_orders WHERE production_order_id = @production_order_id
    
    -- Zwiększ stan magazynu
    UPDATE products
    SET units_in_stock = units_in_stock + @quantity
    WHERE product_id = @product_id
    
    -- Jeśli cała produkcja jest gotowa, zmień status
    DECLARE @total_needed INT
    DECLARE @total_completed INT
    
    SELECT @total_needed = quantity FROM production_orders WHERE production_order_id = @production_order_id
    SELECT @total_completed = SUM(quantity) FROM production_details WHERE production_order_id = @production_order_id
    
    IF @total_completed >= @total_needed
    BEGIN
        UPDATE production_orders
        SET status = 'Zakończone'
        WHERE production_order_id = @production_order_id
    END
END
GO

-- TRIGGER: Uaktualnij cenę zamówienia gdy zmieni się rabat lub pozycje
CREATE OR ALTER TRIGGER trg_update_order_price
ON order_details
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @order_id INT
    
    -- Pobierz order_id z inserted lub deleted
    IF EXISTS(SELECT 1 FROM inserted)
        SELECT @order_id = order_id FROM inserted
    ELSE
        SELECT @order_id = order_id FROM deleted
    
    -- Zaktualizuj cenę zamówienia
    UPDATE orders
    SET price = dbo.fn_calculate_order_total(@order_id)
    WHERE order_id = @order_id
END
GO

-- TRIGGER: Zapisz historię zmian statusu zamówienia
CREATE OR ALTER TRIGGER trg_log_order_status_change
ON orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @order_id INT
    DECLARE @old_status VARCHAR(30)
    DECLARE @new_status VARCHAR(30)
    DECLARE @change_date DATETIME2 = GETDATE()
    
    SELECT 
        @order_id = order_id,
        @old_status = deleted.status,
        @new_status = inserted.status
    FROM deleted
    JOIN inserted ON deleted.order_id = inserted.order_id
    
    IF @old_status <> @new_status
    BEGIN
        -- Można tutaj dodać logowanie zmian do tabeli audit lub event log
        PRINT 'Zmiana statusu zamówienia ' + CAST(@order_id AS NVARCHAR(10)) + 
              ' z [' + @old_status + '] na [' + @new_status + '] o godz. ' + 
              FORMAT(@change_date, 'yyyy-MM-dd HH:mm:ss')
    END
END
GO

-- ============================================================
-- INDEKSY DODATKOWE
-- ============================================================

-- Index na daty dla szybszych raportów
CREATE NONCLUSTERED INDEX idx_orders_order_date ON orders (order_date DESC)
GO

CREATE NONCLUSTERED INDEX idx_orders_status ON orders (status)
GO

CREATE NONCLUSTERED INDEX idx_products_stock ON products (units_in_stock)
GO

CREATE NONCLUSTERED INDEX idx_payments_status ON payments (status)
GO

PRINT '================================'
PRINT 'Widoki, procedury i triggery utworzone pomyślnie!'
PRINT '================================'
GO
