-- Procedury przechowywane i triggery dla systemu zarządzania produkcją i sprzedażą mebli
-- SQL Server T-SQL
-- Zaktualizowano: 2025-12-15 (uwzględniono nowy schemat z tabelą customers)

-- ==============================================
-- PROCEDURY PRZECHOWYWANE
-- ==============================================

-- 4.1 Procedura sp_CreateOrder
-- Tworzy nowe zamówienie dla klienta (z walidacją customer_id w tabeli customers)
GO
CREATE PROCEDURE sp_CreateOrder
    @customer_id INT,
    @order_date DATETIME2,
    @planed_ready_date DATETIME2,
    @discount DECIMAL(3,2) = 0.00,
    @order_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Sprawdź czy klient istnieje w tabeli customers
        IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = @customer_id)
        BEGIN
            RAISERROR('Klient nie istnieje!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Wstaw nowe zamówienie z ceną tymczasową
        INSERT INTO orders (customer_id, order_date, planed_ready_date, discount, price, status, collect_date)
        VALUES (@customer_id, @order_date, @planed_ready_date, @discount, 0.00, 'Nowe', NULL);
        
        SET @order_id = SCOPE_IDENTITY();
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 4.2 Procedura sp_AddOrderDetail
-- Dodaje pozycję do zamówienia i aktualizuje cenę całkowitą
GO
CREATE PROCEDURE sp_AddOrderDetail
    @order_id INT,
    @product_id INT,
    @quantity INT,
    @unit_price DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @order_detail_id INT;
        DECLARE @order_discount DECIMAL(3,2);
        
        -- Wstaw pozycję zamówienia
        INSERT INTO order_details (order_id, product_id, quantity, unit_price, status)
        VALUES (@order_id, @product_id, @quantity, @unit_price, 'Oczekuje');
        
        SET @order_detail_id = SCOPE_IDENTITY();
        
        -- Pobierz rabat z zamówienia
        SELECT @order_discount = discount FROM orders WHERE order_id = @order_id;
        
        -- Przelicz łączną cenę zamówienia
        UPDATE orders
        SET price = (
            SELECT SUM(quantity * unit_price) * (1 - @order_discount)
            FROM order_details
            WHERE order_id = @order_id
        )
        WHERE order_id = @order_id;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 4.3 Procedura sp_RegisterPayment
-- Rejestruje płatność dla zamówienia
GO
CREATE PROCEDURE sp_RegisterPayment
    @order_id INT,
    @payment_amount DECIMAL(10,2),
    @payment_date DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @payment_id INT;
        
        IF @payment_date IS NULL SET @payment_date = GETDATE();
        
        -- Wstaw płatność
        INSERT INTO payments (order_id, price, payment_date, status)
        VALUES (@order_id, @payment_amount, @payment_date, 'Zrealizowana');
        
        SET @payment_id = SCOPE_IDENTITY();
        
        -- Sprawdź, czy zamówienie jest w pełni opłacone
        DECLARE @order_total DECIMAL(12,2);
        DECLARE @paid_amount DECIMAL(10,2);
        
        SELECT @order_total = price FROM orders WHERE order_id = @order_id;
        SELECT @paid_amount = ISNULL(SUM(price), 0) FROM payments 
            WHERE order_id = @order_id AND status = 'Zrealizowana';
        
        IF @paid_amount >= @order_total
        BEGIN
            UPDATE orders SET status = 'Opłacone' WHERE order_id = @order_id;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 4.4 Procedura sp_CreateProductionOrder
-- Tworzy zlecenie produkcyjne na podstawie pozycji zamówienia
GO
CREATE PROCEDURE sp_CreateProductionOrder
    @order_detail_id INT,
    @product_id INT,
    @quantity INT,
    @production_order_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO production_orders (order_detail_id, order_date, product_id, quantity, status)
        VALUES (@order_detail_id, GETDATE(), @product_id, @quantity, 'Planowane');
        
        SET @production_order_id = SCOPE_IDENTITY();
        
        -- Zaktualizuj status pozycji zamówienia
        UPDATE order_details SET status = 'W produkcji' WHERE order_detail_id = @order_detail_id;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 4.5 Procedura sp_UpdateStockAfterProduction
-- Aktualizuje stan magazynu po zakończeniu produkcji
GO
CREATE PROCEDURE sp_UpdateStockAfterProduction
    @production_order_id INT,
    @produced_quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @product_id INT;
        
        -- Pobierz produkt z zamówienia produkcyjnego
        SELECT @product_id = product_id FROM production_orders 
            WHERE production_order_id = @production_order_id;
        
        -- Dodaj ilość do magazynu
        UPDATE products SET units_in_stock = units_in_stock + @produced_quantity
            WHERE product_id = @product_id;
        
        -- Zaktualizuj status zlecenia produkcyjnego
        UPDATE production_orders SET status = 'Zakończone' 
            WHERE production_order_id = @production_order_id;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ==============================================
-- TRIGGERY
-- ==============================================

-- 5.1 Trigger trg_CheckStockOnOrderInsert
-- Sprawdza dostępność magazynu przed dodaniem pozycji do zamówienia
GO
CREATE TRIGGER trg_CheckStockOnOrderInsert
ON order_details
AFTER INSERT
AS
BEGIN
    DECLARE @product_id INT, @quantity INT, @units_in_stock INT;
    
    SELECT @product_id = product_id, @quantity = quantity FROM inserted;
    SELECT @units_in_stock = units_in_stock FROM products WHERE product_id = @product_id;
    
    IF @units_in_stock < @quantity
    BEGIN
        RAISERROR('Brak wystarczającej ilości produktu w magazynie!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 5.2 Trigger trg_DeductStockOnOrderComplete
-- Zmniejsza stan magazynu po potwierdzeniu odbioru zamówienia
GO
CREATE TRIGGER trg_DeductStockOnOrderComplete
ON orders
AFTER UPDATE
AS
BEGIN
    DECLARE @order_id INT, @status VARCHAR(30), @new_status VARCHAR(30);
    
    SELECT @order_id = order_id, @new_status = status FROM inserted;
    SELECT @status = status FROM deleted;
    
    IF @status <> @new_status AND @new_status = 'Zakończone'
    BEGIN
        UPDATE products
        SET units_in_stock = units_in_stock - od.quantity
        FROM products p
        JOIN order_details od ON p.product_id = od.product_id
        WHERE od.order_id = @order_id;
    END
END;
GO

-- 5.3 Trigger trg_UpdateOrderStatusOnPayment
-- Automatycznie zaktualizuje status zamówienia na "Opłacone"
GO
CREATE TRIGGER trg_UpdateOrderStatusOnPayment
ON payments
AFTER INSERT
AS
BEGIN
    DECLARE @order_id INT, @order_total DECIMAL(12,2), @paid_amount DECIMAL(10,2);
    
    SELECT @order_id = order_id FROM inserted;
    SELECT @order_total = price FROM orders WHERE order_id = @order_id;
    SELECT @paid_amount = ISNULL(SUM(price), 0) FROM payments 
        WHERE order_id = @order_id AND status = 'Zrealizowana';
    
    IF @paid_amount >= @order_total
    BEGIN
        UPDATE orders SET status = 'Opłacone' WHERE order_id = @order_id;
    END
END;
GO

-- 5.4 Trigger trg_LinkProductionDetailToOrder
-- Tworzy powiązanie między szczegółami produkcji a pozycją zamówienia
GO
CREATE TRIGGER trg_LinkProductionDetailToOrder
ON production_details
AFTER INSERT
AS
BEGIN
    DECLARE @production_order_id INT, @order_detail_id INT, @produced_qty INT;
    
    SELECT @production_order_id = production_order_id, @produced_qty = quantity FROM inserted;
    SELECT @order_detail_id = order_detail_id FROM production_orders 
        WHERE production_order_id = @production_order_id;
    
    -- Jeśli produkcja jest zakończona, oznacz pozycję jako gotową
    DECLARE @po_status VARCHAR(30);
    SELECT @po_status = status FROM production_orders WHERE production_order_id = @production_order_id;
    
    IF @po_status = 'Zakończone' AND @order_detail_id IS NOT NULL
    BEGIN
        UPDATE order_details SET status = 'Gotowe' WHERE order_detail_id = @order_detail_id;
    END
END;
GO

-- 5.5 Trigger trg_AuditOrderChanges
-- Loguje zmiany statusu zamówień (wymaga tabeli audit_orders)
-- Utwórz tabelę audit_orders przed utworzeniem triggera:
-- CREATE TABLE audit_orders (
--     audit_id INT PRIMARY KEY IDENTITY,
--     order_id INT,
--     old_status VARCHAR(30),
--     new_status VARCHAR(30),
--     changed_at DATETIME2 DEFAULT GETDATE()
-- );

GO
CREATE TRIGGER trg_AuditOrderChanges
ON orders
AFTER UPDATE
AS
BEGIN
    DECLARE @order_id INT, @old_status VARCHAR(30), @new_status VARCHAR(30);
    
    SELECT @order_id = order_id, @new_status = status FROM inserted;
    SELECT @old_status = status FROM deleted;
    
    IF @old_status <> @new_status
    BEGIN
        IF OBJECT_ID('audit_orders', 'U') IS NOT NULL
        BEGIN
            INSERT INTO audit_orders (order_id, old_status, new_status)
            VALUES (@order_id, @old_status, @new_status);
        END
    END
END;
GO
