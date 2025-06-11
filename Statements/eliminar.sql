SELECT 
    PARAMETER_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.PARAMETERS
WHERE SPECIFIC_NAME = 'InsertarAdministrativo';

-->Procedimeinto para eliminar los detalles de un pedido, utilizando el parametro @idPedido y validando que el 
--id del pedido se encuentre en la tabla pedido
GO
CREATE PROCEDURE EliminarDetallesPedido
(
    @idPedido INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF @idPedido IS NULL
        BEGIN
            SELECT 'Debe proporcionar un ID de pedido.' AS Mensaje;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM pedido WHERE id_pedido = @idPedido)
        BEGIN
            SELECT 'El pedido especificado no existe.' AS Mensaje;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM detalles_pedido WHERE id_pedido = @idPedido)
            BEGIN
            SELECT 'El pedido no tiene detalles asociados.' AS Mensaje;
            RETURN;
        END

        DELETE FROM detalles_pedido WHERE id_pedido = @idPedido;
        
        COMMIT TRANSACTION;
        SELECT 'Los detalles del pedido fueron eliminados correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END

-->Procedimiento para eliminar un pedido, utilizando los parametros @idPedido y @cedulaCliente, validando que el
--id del pedido se encuentre en la tabla pedido y que la cedula del cliente se encuentre en la tabla cliente.
--Elimina al mismo tiempo los detalles del pedido, si existe, utilizando el procedimeinto EliminarDetallesPedido.
--Puede ser utilizado tanto con solo la cedula del cliente, como con el id del pedido.
--Si se proporciona ambos parametros, se valida que el pedido pertenezca al cliente.
GO 
CREATE PROCEDURE EliminarPedido
(
    @idPedido INT = NULL,
    @cedulaCliente INT = NULL 
)
AS
BEGIN 
    BEGIN TRY
        BEGIN TRANSACTION

        IF @idPedido IS NULL AND @cedulaCliente IS NULL
        BEGIN
            SELECT 'Debe proporcionar al menos un ID de pedido o una cédula de cliente.' AS Mensaje;
            RETURN;
        END
        
        IF @idPedido IS NOT NULL AND @cedulaCliente IS NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pedido WHERE id_pedido = @idPedido)
            BEGIN
                SELECT 'El pedido especificado no existe.' AS Mensaje;
                RETURN;
            END
            
            EXEC EliminarDetallesPedido @idPedido; 
            DELETE FROM pedido WHERE id_pedido = @idPedido;
            SELECT 'El pedido específico fue eliminado correctamente.' AS Mensaje;
        END
        
        ELSE IF @cedulaCliente IS NOT NULL AND @idPedido IS NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cliente WHERE cedula = @cedulaCliente)
            BEGIN
                SELECT 'El cliente especificado no existe.' AS Mensaje;
                RETURN;
            END
            
            IF NOT EXISTS (SELECT 1 FROM pedido WHERE cedula = @cedulaCliente)
            BEGIN
                SELECT 'El cliente no tiene pedidos registrados.' AS Mensaje;
                RETURN;
            END
            
            -->CREACIÓN DE CURSOR PARA ELIMINAR DETALLES DE PEDIDO
            -- Crear tabla temporal para almacenar todos los IDs de pedido
            DECLARE @pedidos TABLE (id_pedido INT);
            
            -- Insertar todos los IDs de pedido del cliente
            INSERT INTO @pedidos
            SELECT id_pedido FROM pedido WHERE cedula = @cedulaCliente;
            
            -- Eliminar detalles para cada pedido
            DECLARE @current_id INT;
            DECLARE pedido_cursor CURSOR FOR 
            SELECT id_pedido FROM @pedidos;
            
            OPEN pedido_cursor;
            FETCH NEXT FROM pedido_cursor INTO @current_id;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC EliminarDetallesPedido @current_id;
                FETCH NEXT FROM pedido_cursor INTO @current_id;
            END
            
            CLOSE pedido_cursor;
            DEALLOCATE pedido_cursor;

            DELETE FROM pedido WHERE cedula = @cedulaCliente;
        END

        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cliente WHERE cedula = @cedulaCliente)
            BEGIN
                SELECT 'El cliente especificado no existe.' AS Mensaje;
                RETURN;
            END
            
            IF NOT EXISTS (SELECT 1 FROM pedido WHERE id_pedido = @idPedido AND cedula = @cedulaCliente)
            BEGIN
                SELECT 'El pedido especificado no pertenece al cliente.' AS Mensaje;
                RETURN;
            END
            
            EXEC EliminarDetallesPedido @idPedido; 
            DELETE FROM pedido WHERE id_pedido = @idPedido AND cedula = @cedulaCliente;
            SELECT 'El pedido específico del cliente fue eliminado correctamente.' AS Mensaje;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END
GO

--> IMPORTANTE: Se elimino la columna detalles de la tabla pedido, ya que se estaba utilizando para almacenar
--detalles del pedido, pero se ha creado una tabla separada para los detalles del pedido.
ALTER TABLE pedido
DROP COLUMN detalles;
SELECT * FROM garantia

--> Procedimiento para eliminar un pedido de compra, utilizando los parametros @idPedido y @idCompra, 
-- validando que el
GO
CREATE PROCEDURE EliminarPedidoCompra
(
    @idPedido INT = NULL,
    @idCompra INT = NULL
)
AS
BEGIN 
    BEGIN TRY 
        BEGIN TRANSACTION

        IF @idPedido IS NULL AND @idCompra IS NULL
        BEGIN
            SELECT 'Debe proporcionar al menos un ID de pedido o un ID de compra.' AS Mensaje;
            RETURN;
        END
        
        IF @idPedido IS NOT NULL AND @idCompra IS NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pedido WHERE id_pedido = @idPedido)
            BEGIN
                SELECT 'El pedido especificado no existe.' AS Mensaje;
                RETURN;
            END
            
            EXEC EliminarDetallesPedido @idPedido; 
            DELETE FROM pedido WHERE id_pedido = @idPedido;
            SELECT 'El pedido específico fue eliminado correctamente.' AS Mensaje;
        END
        
        ELSE IF @idCompra IS NOT NULL AND @idPedido IS NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM compra WHERE id_compra = @idCompra)
            BEGIN
                SELECT 'La compra especificada no existe.' AS Mensaje;
                RETURN;
            END
            
            EXEC EliminarCompraProducto @idCompra; 
            DELETE FROM compra WHERE id_compra = @idCompra;
            SELECT 'La compra específica fue eliminada correctamente.' AS Mensaje;
        END

        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pedido WHERE id_pedido = @idPedido)
            BEGIN
                SELECT 'El pedido especificado no existe.' AS Mensaje;
                RETURN;
            END
            
            IF NOT EXISTS (SELECT 1 FROM compra WHERE id_compra = @idCompra)
            BEGIN
                SELECT 'La compra especificada no existe.' AS Mensaje;
                RETURN;
            END
            
            EXEC EliminarDetallesPedido @idPedido; 
            EXEC EliminarCompraProducto @idCompra; 
            
            DELETE FROM pedido WHERE id_pedido = @idPedido;
            DELETE FROM compra WHERE id_compra = @idCompra;

            SELECT 'El pedido y la compra específicos fueron eliminados correctamente.' AS Mensaje;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END

--> Procedimiento para eliminar un producto de una compra, utilizando el parametro @idCompra y validando que el
--id de la compra se encuentre en la tabla compra_producto.
GO
CREATE PROCEDURE EliminarCompraProducto
(
    @idCompra INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF @idCompra IS NULL
        BEGIN
            SELECT 'Debe proporcionar un ID de compra.' AS Mensaje;
            RETURN;
        END

        -- Elimina TODOS los productos asociados a la compra
        DELETE FROM compra_producto 
        WHERE id_compra = @idCompra;
        
        SELECT 'Productos de la compra eliminados correctamente.' AS Mensaje;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END

--> Procedimiento para eliminar una compra, utilizando los parametros @idCompra y @cedulaCliente, validando que el
--id de la compra se encuentre en la tabla compra y que la cedula del cliente se encuentre en la tabla cliente.
--Puede ser utilizado tanto con solo la cedula del cliente, como con el id de la compra.
--Al ejecutarse elimina tambien los productos asociados a la compra utilizando el procedimiento EliminarCompraProducto
--lo que altera la tabla compra_producto.
GO
CREATE PROCEDURE EliminarCompra
(
    @idCompra INT = NULL,
    @cedulaCliente INT = NULL 
)
AS
BEGIN 
    BEGIN TRY 
        BEGIN TRANSACTION

        IF @idCompra IS NULL AND @cedulaCliente IS NULL
        BEGIN
            SELECT 'Debe proporcionar al menos un ID de compra o una cédula de cliente.' AS Mensaje;
            RETURN;
        END
        
        IF @idCompra IS NOT NULL AND @cedulaCliente IS NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM compra WHERE id_compra = @idCompra)
            BEGIN
                SELECT 'La compra especificada no existe.' AS Mensaje;
                RETURN;
            END
            
            EXEC EliminarCompraProducto @idCompra; 
            DELETE FROM compra WHERE id_compra = @idCompra;
            SELECT 'La compra específica fue eliminada correctamente.' AS Mensaje;
        END
        
        ELSE IF @cedulaCliente IS NOT NULL AND @idCompra IS NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cliente WHERE cedula = @cedulaCliente)
            BEGIN
                SELECT 'El cliente especificado no existe.' AS Mensaje;
                RETURN;
            END
            
            IF NOT EXISTS (SELECT 1 FROM compra WHERE cedula = @cedulaCliente)
            BEGIN
                SELECT 'El cliente no tiene compras registradas.' AS Mensaje;
                RETURN;
            END
            
            -- Crear tabla temporal para almacenar todos los IDs de compra
            DECLARE @compras TABLE (id_compra INT);
            
            -- Insertar todos los IDs de compra del cliente
            INSERT INTO @compras
            SELECT id_compra FROM compra WHERE cedula = @cedulaCliente;
            
            -- Eliminar productos para cada compra
            DECLARE @current_id INT;
            DECLARE compra_cursor CURSOR FOR 
            SELECT id_compra FROM @compras;
            
            OPEN compra_cursor;
            FETCH NEXT FROM compra_cursor INTO @current_id;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC EliminarCompraProducto @current_id;
                FETCH NEXT FROM compra_cursor INTO @current_id;
            END
            
            CLOSE compra_cursor;
            DEALLOCATE compra_cursor;
            
            -- Eliminar las compras
            DELETE FROM compra WHERE cedula = @cedulaCliente;
            SELECT 'Todas las compras del cliente fueron eliminadas correctamente.' AS Mensaje;
        END

        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM cliente WHERE cedula = @cedulaCliente)
            BEGIN
                SELECT 'El cliente especificado no existe.' AS Mensaje;
                RETURN;
            END
            
            IF NOT EXISTS (SELECT 1 FROM compra WHERE id_compra = @idCompra AND cedula = @cedulaCliente)
            BEGIN
                SELECT 'La compra especificada no pertenece al cliente.' AS Mensaje;
                RETURN;
            END
            
            EXEC EliminarCompraProducto @idCompra; 
            DELETE FROM compra WHERE id_compra = @idCompra AND cedula = @cedulaCliente;
            SELECT 'La compra específica del cliente fue eliminada correctamente.' AS Mensaje;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END
GO

-- IMPORTANTE: Se elimino la llave primaria de la tabla compra_prodcuto ya que una compra puede tener varias
-- compras de un producto, no solo una 
-- ERROR: Violation of PRIMARY KEY constraint 'PK_compra_producto'. Cannot insert duplicate key in object 'dbo.compra_producto'. 
--The duplicate key value is (2, 3).
ALTER TABLE compra_producto
    DROP CONSTRAINT PK_compra_producto;

--> Procedimiento para eliminar un cliente, utilizando el parametro @cedulaCliente, validando que la cedula del cliente
-- se encuentre en la tabla cliente. Elimina al mismo tiempo los pedidos y compras asociados al cliente, utilizando 
-- los procedimientos EliminarPedido y EliminarCompra.
GO
CREATE PROCEDURE EliminarCliente 
(
    @cedulaCliente INT
)
AS
BEGIN
    DECLARE @idPedido INT; 
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @cedulaCliente IS NULL
        BEGIN
            SELECT 'Debe proporcionar una cédula de cliente.' AS Mensaje;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM cliente WHERE cedula = @cedulaCliente)
        BEGIN
            SELECT 'El cliente especificado no existe.' AS Mensaje;
            RETURN;
        END

        
        EXEC EliminarPedido @cedulaCliente = @cedulaCliente;
        EXEC EliminarCompra @cedulaCliente = @cedulaCliente;

        DELETE FROM cliente WHERE cedula = @cedulaCliente;

        COMMIT TRANSACTION;
        SELECT 'El cliente fue eliminado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH

    IF @@TRANCOUNT > 0
        COMMIT TRANSACTION;
END

EXEC EliminarCliente @cedulaCliente = 12345678; -- Reemplaza con una cédula de cliente válida para probar
SELECT * FROM cliente;
SELECT * FROM pedido;
SELECT * FROM compra;
SELECT * FROM compra_producto;
SELECT * FROM detalles_pedido;

EXEC EliminarPedido @cedulaCliente = 12345678; 
EXEC InsertarPedido @cedula = 12345678, @estado = 1, @fecha = '2023-10-01', @distrito = 1, @señas = 'Lo que sea';
EXEC InsertarPedido @cedula = 12345678, @estado = 2, @fecha = '2023-10-01', @distrito = 2, @señas = 'Lo que sea';
EXEC InsertarDetallesPedido @id_pedido = 11, @cantidad = 2, @observaciones = 'Lo que sea';
EXEC InsertarDetallesPedido @id_pedido = 12, @cantidad = 2, @observaciones = 'Lo que sea';
SELECT * FROM detalles_pedido
SELECT * FROM pedido
select * from cliente 

EXEC EliminarCompra @cedulaCliente = 12345678;

EXEC InsertarCompra @fecha = '2023-10-01', @cedula = 12345678, @devolucion = 1;
EXEC InsertarCompra @fecha = '2023-10-01', @cedula = 12345678, @devolucion = 1;
EXEC InsertarCompra @fecha = '2023-10-01', @cedula = 12345678, @devolucion = 1;
EXEC InsertarCompraProducto @id_compra = 7, @id_producto = 3, @garantia = 1, @monto_pagado = 100.00, @metodo_pago = 'targeta';
EXEC InsertarCompraProducto @id_compra = 7, @id_producto = 3, @garantia = 1, @monto_pagado = 100.00, @metodo_pago = 'targeta';
EXEC InsertarCompraProducto @id_compra = 9, @id_producto = 3, @garantia = 1, @monto_pagado = 100.00, @metodo_pago = 'targeta';
EXEC EliminarCompra @cedulaCliente = 12345678;
SELECT * FROM compra
SELECT * FROM compra_producto;
select * from producto


GO
CREATE PROCEDURE EliminarLineaBlanca
(
    @idLineaBlanca INT
)
AS
BEGIN 
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF @idLineaBlanca IS NULL
        BEGIN
            SELECT 'Debe proporcionar un ID de línea blanca.' AS Mensaje;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM linea_blanca WHERE id_linea_blanca = @idLineaBlanca)
        BEGIN
            SELECT 'La línea blanca especificada no existe.' AS Mensaje;
            RETURN;
        END

        DELETE FROM linea_blanca WHERE id_linea_blanca = @idLineaBlanca;
        
        COMMIT TRANSACTION;
        SELECT 'La línea blanca fue eliminada correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END

select * from producto

GO
CREATE PROCEDURE EliminarAdministradorProducto
(
    @cedula INT = NULL,
    @idProducto INT = NULL
)
AS 
BEGIN 
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF @idProducto IS NULL AND @cedula IS NULL
        BEGIN
            SELECT 'Debe proporcionar al menos un ID de producto o una cédula de administrador.' AS Mensaje;
            RETURN;
        END

        IF @idProducto IS NOT NULL AND NOT EXISTS (SELECT 1 FROM producto WHERE id_producto = @idProducto)
        BEGIN
            SELECT 'El producto especificado no existe.' AS Mensaje;
            RETURN;
        END

        IF @cedula IS NOT NULL AND NOT EXISTS (SELECT 1 FROM administrativos WHERE cedula = @cedula)
        BEGIN
            SELECT 'El administrativo especificado no existe.' AS Mensaje;
            RETURN;
        END

        IF @cedula IS NOT NULL AND @idProducto IS NULL
        BEGIN
            -- Eliminar todos los productos asociados al administrativo
            DELETE FROM administrador_producto WHERE cedula = @cedula;
            SELECT 'Todos los productos del administrativo fueron eliminados correctamente.' AS Mensaje;
            COMMIT TRANSACTION;  -- Añadir COMMIT aquí
            RETURN;  -- Añadir RETURN explícito
        END

        -- Si llegamos aquí, es porque @idProducto NO es NULL
        DELETE FROM administrador_producto WHERE producto = @idProducto;
        
        COMMIT TRANSACTION;
        SELECT 'El producto fue eliminado correctamente de administrador_producto.' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END


GO
CREATE PROCEDURE EliminarProducto
(
    @idProducto INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF @idProducto IS NULL
        BEGIN
            SELECT 'Debe proporcionar un ID de producto.' AS Mensaje;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM producto WHERE id_producto = @idProducto)
        BEGIN
            SELECT 'El producto especificado no existe.' AS Mensaje;
            RETURN;
        END

        EXEC EliminarAdministradorProducto @idProducto;
        DELETE FROM producto WHERE id_producto = @idProducto;
        
        COMMIT TRANSACTION;
        SELECT 'El producto fue eliminado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END



DROP PROCEDURE EliminarAdministradorProducto
EXEC EliminarProducto @idProducto = 3; -- Reemplaza con un ID de producto válido para probar
select * from producto 
select * from administrador_producto
select * from administrativos

EXEC InsertarProducto @nombreProducto = 'Producto de prueba', @precio = 100.00, @marca = 'Lo que sea', @stock = 100, @id_categoria = 1, @descripcion = 'Descripción de prueba';
EXEC InsertarAdministradorProducto @cedulaAdministrador = 12345678, @idProducto = 4;

GO
CREATE PROCEDURE EliminarTelefonoPersona
(
    @cedula INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF  @cedula IS NULL 
        BEGIN
            SELECT 'Debe proporcionar una cédula de persona.' AS Mensaje;
            RETURN;
        END

        DELETE FROM telefonos_personas WHERE cedula = @cedula;
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END

GO 
CREATE PROCEDURE EliminarCorreoPersona
(
    @cedula INT
)
AS
BEGIN 
    BEGIN TRY 
        BEGIN TRANSACTION 
        IF @cedula IS NULL
        BEGIN
            SELECT 'Debe proporcionar una cédula de persona.' AS Mensaje;
            RETURN;
        END 

        DELETE FROM correos_personas WHERE cedula = @cedula;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END

GO
CREATE PROCEDURE EliminarAdministrativo
(
    @cedulaAdministrador INT
)
AS
BEGIN 
    BEGIN TRY
        BEGIN TRANSACTION
        
        IF @cedulaAdministrador IS NULL
        BEGIN
            SELECT 'Debe proporcionar una cédula de administrativo.' AS Mensaje;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM administrativos WHERE cedula = @cedulaAdministrador)
        BEGIN
            SELECT 'El administrativo especificado no existe.' AS Mensaje;
            RETURN;
        END

        EXEC EliminarAdministradorProducto @cedula = @cedulaAdministrador;
        DELETE FROM administrativos WHERE cedula = @cedulaAdministrador;
        
        COMMIT TRANSACTION;
        SELECT 'El administrativo fue eliminado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END

GO 
CREATE PROCEDURE EliminarPersona
(
    @cedulaPersona INT
)
AS
BEGIN
    -- Primero validaciones sin transacción
    IF @cedulaPersona IS NULL
    BEGIN
        SELECT 'Debe proporcionar una cédula de persona.' AS Mensaje;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM persona WHERE cedula = @cedulaPersona)
    BEGIN
        SELECT 'La persona especificada no existe.' AS Mensaje;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Eliminar teléfonos y correos primero (relaciones más simples)
        EXEC EliminarTelefonoPersona @cedula = @cedulaPersona;
        EXEC EliminarCorreoPersona @cedula = @cedulaPersona;

        -- Luego eliminar roles específicos
        IF EXISTS (SELECT 1 FROM administrativos WHERE cedula = @cedulaPersona)
        BEGIN
            EXEC EliminarAdministrativo @cedulaAdministrador = @cedulaPersona;
            DELETE FROM administrativos WHERE cedula = @cedulaPersona;
        END

        IF EXISTS (SELECT 1 FROM cliente WHERE cedula = @cedulaPersona)
        BEGIN
            EXEC EliminarCliente @cedulaCliente = @cedulaPersona;
            DELETE FROM cliente WHERE cedula = @cedulaPersona;
        END
        
        -- Finalmente eliminar el registro principal
        DELETE FROM persona WHERE cedula = @cedulaPersona;
        
        COMMIT TRANSACTION;
        SELECT 'La persona y todos sus datos relacionados fueron eliminados correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 'Error al eliminar la persona: ' + ERROR_MESSAGE() AS MensajeError;
    END CATCH
END

SELECT 
    fk.name AS ForeignKey,
    tp.name AS TablaQueReferencia,
    cp.name AS ColumnaQueReferencia,
    tr.name AS TablaReferenciada,
    cr.name AS ColumnaReferenciada
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS tp ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.columns AS cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.tables AS tr ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns AS cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
WHERE cr.name = 'cedula';

EXEC EliminarPersona @cedulaPersona = 87654321; -- Reemplaza con una cédula de persona válida para probar
SELECT * FROM administrativos;
EXEC InsertarAdministrativo @cedulaAdministrativo = 12345678; 
EXEC InsertarAdministradorProducto @cedulaAdministrador = 12345678, @idProducto = 4; -- Reemplaza con un ID de producto válido para probar
SELECT * FROM administrador_producto;
SELECT * FROM producto;
EXEC EliminarAdministrativo @cedulaAdministrador = 12345678; -- Reemplaza con una cédula de administrativo válida para probar
EXEC EliminarCliente @cedulaCliente = 87654321; -- Reemplaza con una cédula de cliente válida para probar


SELECT * FROM telefonos_personas
GO 



DROP PROCEDURE EliminarPersona
BEGIN TRANSACTION;
EXEC InsertarPersona @cedula = 87654321, @nombre = 'Alison', @apellido1 = 'Cordoba', @apellido2 = 'Marquez', @distrito = 3, @señas = 'Lo que sea';
EXEC InsertarPersona @cedula = 67854323, @nombre = 'Alison', @apellido1 = 'Cordoba', @apellido2 = 'Marquez', @distrito = 3, @señas = 'Lo que sea';

EXEC InsertarCliente @cedulaCliente = 87654321; 
EXEC InsertarAdministrativo @cedulaAdministrativo = 67854323;

EXEC InsertarPedido @cedula = 87654321, @estado = 1, @fecha = '2023-10-01', @distrito = 3, @señas = 'Lo que sea';
EXEC InsertarDetallesPedido @id_pedido = 19, @cantidad = 2, @observaciones = 'Lo que sea';
EXEC InsertarCompra @fecha = '2023-10-01', @cedula = 87654321, @devolucion = 1;
EXEC InsertarCompraProducto @id_compra = 16, @id_producto = 4, @garantia = 1, @monto_pagado = 100.00, @metodo_pago = 'targeta';

EXEC InsertarAdministradorProducto @cedulaAdministrador = 67854323, @idProducto = 5;
EXEC InsertarProducto @nombreProducto = 'Producto de prueba 2', @precio = 200.00, @marca = 'Marca de prueba', @stock = 50, @id_categoria = 2, @descripcion = 'Descripción de prueba 2';
EXEC InsertarCompraProducto @id_compra = 13, @id_producto = 5, @garantia = 1, @monto_pagado = 200.00, @metodo_pago = 'targeta';
EXEC InsertarTelefonoPersona @cedulaTelefono = 87654321, @telefono = '1234-5689';
EXEC InsertarCorreoPersona @cedulaCorreo = 87654321, @correo = 'ESTOESLOQUESEA@GMAIL.COM'
EXEC InsertarTelefonoPersona @cedulaTelefono = 67854323, @telefono = '9876-5432';
EXEC InsertarCorreoPersona @cedulaCorreo = 67854323, @correo = 'kajdflkakfd@gmail.com';

select * from correos_personas
select * from telefonos_personas
select * from persona
select * from cliente 
select * from administrativos
select * from pedido 
select * from detalles_pedido
select * from compra
select * from compra_producto
select * from producto

EXEC EliminarPersona @cedulaPersona = 87654321; 
exec InsertarCliente @cedulaCliente = 12345678;
SELECT 
    PARAMETER_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.PARAMETERS
WHERE SPECIFIC_NAME = 'InsertarTelefonoPersona';


