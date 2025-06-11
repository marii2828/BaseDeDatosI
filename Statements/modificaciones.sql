-->Procedimiento de modificar una persona en la tabla personas, toma la cedula como parametro para saber cual persona alterar, 
-- y luego se pueden modificar los siguientes campos: nombre, apellido1, apellido2, distrito y señas.
GO
CREATE PROCEDURE ModificarPersona 
(
    @cedula INT, 
    @nombre VARCHAR(50) = NULL,
    @apellido1 VARCHAR(50) = NULL,
    @apellido2 VARCHAR(50) = NULL,
    @distrito VARCHAR(50) = NULL,
    @señas VARCHAR(100) = NULL
)
AS
BEGIN 
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM persona WHERE cedula = @cedula)
        BEGIN
            RAISERROR('No existe una persona con la cédula proporcionada.', 16, 1);
            RETURN;
        END
    UPDATE persona
    SET 
        nombre = COALESCE(@nombre, nombre),
        apellido1 = COALESCE(@apellido1, apellido1),
        apellido2 = COALESCE(@apellido2, apellido2),
        distrito = COALESCE(@distrito, distrito),
        señas = COALESCE(@señas, señas)
    WHERE cedula = @cedula;
    
    END TRY 
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;


SELECT * FROM persona
EXEC ModificarPersona 87654321, 'Juan', NULL, 'Pérez', 4, 'Calle 123';
EXEC InsertarPersona @cedula = 87654321, @nombre = 'Alison', @apellido1 = 'Cordoba', @apellido2 = 'Marquez', @distrito = 3, @señas = 'Lo que sea';

-->Procedimiento de modificar un telefono de una persona, toma la cedula como parametro para saber cual telefono alterar,
-- y y el telefono actual para saber cual modificar si la persona tiene más de un telefono registrado. 
--Telefono nuevo es el nuevo telefono que se quiere asignar a la persona.
GO 
CREATE PROCEDURE ModificarTelefonoPersona
(
    @cedula INT, 
    @telefonoActual VARCHAR(15) = NULL,
    @telefonoNuevo VARCHAR(15) = NULL

)
AS
BEGIN
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM telefonos_personas WHERE cedula = @cedula)
        BEGIN
            RAISERROR('No existe una persona con la cédula proporcionada.', 16, 1);
            RETURN;
        END

    IF NOT EXISTS (SELECT 1 FROM telefonos_personas WHERE telefono = @telefonoActual)
        BEGIN
            RAISERROR('El telefono proporcionado no existe.', 16, 1);
            RETURN;
        END

    IF @telefonoNuevo NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' OR LEN(@telefonoNuevo) < 9
        BEGIN 
            SELECT 'Formato de teléfono inválido.' AS Mensaje;
            RETURN;
        END
    IF @telefonoNuevo IS NULL OR @telefonoNuevo = ''
        BEGIN
            SELECT 'El teléfono no puede ser nulo o vacío.' AS Mensaje;
            RETURN;
        END
    UPDATE telefonos_personas
    SET 
        telefono = COALESCE(@telefonoNuevo, telefono)
    WHERE cedula = @cedula;
    END TRY 
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;


select * from telefonos_personas
EXEC ModificarTelefonoPersona 67854323, '8887-8086';

-->Procedimeinto de modificar un correo de una persona, toma la cedula como parametro para saber cual correo alterar,
-- y el correo actual para saber cual modificar si la persona tiene más de un correo registrado.
GO
CREATE PROCEDURE ModifiarCorreoPersona
(
    @cedula INT, 
    @correoActual VARCHAR(50) = NULL,
    @correoNuevo VARCHAR(50) = NULL
)
AS
BEGIN
    BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM correos_personas WHERE cedula = @cedula)
        BEGIN
            RAISERROR('No existe una persona con la cédula proporcionada.', 16, 1);
            RETURN;
        END

    IF NOT EXISTS (SELECT 1 FROM correos_personas WHERE correo = @correoActual)
        BEGIN
            RAISERROR('No existe el correo proporcionado.', 16, 1);
            RETURN;
        END

    IF @correoNuevo IS NULL OR @correoNuevo = ''
        BEGIN
            SELECT 'El correo no puede ser nulo o vacío.' AS Mensaje;
            RETURN;
        END

    IF @correoNuevo NOT LIKE '%_@__%.__%' 
            BEGIN 
                SELECT 'Formato de correo inválido.' AS Mensaje;
                RETURN;
            END

    IF @correoNuevo IS NULL OR @correoNuevo = ''
        BEGIN
            SELECT 'El correo no puede ser nulo o vacío.' AS Mensaje;
            RETURN;
        END
    UPDATE correos_personas
    SET 
        correo = COALESCE(@correoNuevo, correo)
    WHERE cedula = @cedula;
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

-->Procedimiento de modificar un administrador de producto, toma la cedula del administrador actual y la nueva cedula del administrador que se quiere asignar.
-- Si la nueva cedula no existe en la tabla administrador_producto, se genera un error.
GO 
CREATE PROCEDURE ModificarAdministradorProducto
(
    @cedula INT, 
    @nuevoAdministrador INT = NULL,
    @nuevoProducto INT = NULL
)
AS
BEGIN 
    BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM administrador_producto WHERE cedula = @cedula)
        BEGIN
            RAISERROR('No existe un administrador con la cédula proporcionada.', 16, 1);
            RETURN;
        END

    IF NOT EXISTS (SELECT 1 FROM administrador_producto WHERE cedula = @nuevoAdministrador)
        BEGIN
            RAISERROR('El nuevo administrador no existe.', 16, 1);
            RETURN;
        END

    IF @nuevoProducto IS NOT NULL AND NOT EXISTS (SELECT 1 FROM producto WHERE id_producto = @nuevoProducto)
        BEGIN
            RAISERROR('El nuevo producto no existe.', 16, 1);
            RETURN;
        END
        ELSE IF @nuevoProducto IS NOT NULL 
        BEGIN
            UPDATE administrador_producto
            SET 
                producto = @nuevoProducto
            WHERE cedula = @cedula;
        END

    UPDATE administrador_producto
    SET 
        cedula = COALESCE(@nuevoAdministrador, cedula)
    WHERE cedula = @cedula;
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

-->Procedimiento de modificar un producto, toma el codigo del producto como parametro para saber cual producto alterar,
-- y luego se pueden modificar los siguientes campos: nombre, precio, marca, stock, id_categoria y descripcion.
GO
CREATE PROCEDURE ModificarProducto
(
    @codigo INT, 
    @nombre VARCHAR(50) = NULL,
    @precio FLOAT = NULL,
    @marca VARCHAR(30) = NULL,
    @stock INT = NULL, 
    @id_categoria INT = NULL,
    @descripcion VARCHAR(100) = NULL
)
AS
BEGIN 
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM producto WHERE id_producto = @codigo)
        BEGIN
            RAISERROR('No existe un producto con el código proporcionado.', 16, 1);
            RETURN;
        END
    UPDATE producto
    SET 
        nombre = COALESCE(@nombre, nombre),
        precio = COALESCE(@precio, precio),
        marca = COALESCE(@marca, marca),
        stock = COALESCE(@stock, stock),
        id_categoria = COALESCE(@id_categoria, id_categoria),
        descripcion = COALESCE(@descripcion, descripcion)
    WHERE id_producto = @codigo;
    
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

GO
CREATE PROCEDURE ModificarCompraProducto
(
    @codigo INT, 
    @id_producto INT = NULL,
    @garantia INT = NULL,
    @monto_pagado FLOAT = NULL,
    @metodo_pago VARCHAR(20) = NULL
)
AS
BEGIN 
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM compra_producto WHERE id_compra = @codigo)
        BEGIN
            RAISERROR('No existe una compra con el código proporcionado.', 16, 1);
            RETURN;
        END
    UPDATE compra_producto
    SET 
        id_producto = COALESCE(@id_producto, id_producto),
        garantia = COALESCE(@garantia, garantia),
        monto_pagado = COALESCE(@monto_pagado, monto_pagado),
        metodo_pago = COALESCE(@metodo_pago, metodo_pago)
    WHERE id_compra = @codigo;
    
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

-->Procedimiento de modificar una compra, toma el codigo de la compra como parametro para saber cual compra alterar,
-- y luego se pueden modificar los siguientes campos: fecha, cedula del cliente y devolucion.
GO
CREATE PROCEDURE ModificarCompra
(
    @codigo INT, 
    @fecha DATE = NULL,
    @cedula INT = NULL,
    @devolución INT = NULL
)
AS
BEGIN 
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM compra WHERE id_compra = @codigo)
        BEGIN
            RAISERROR('No existe una compra con el código proporcionado.', 16, 1);
            RETURN;
        END
    UPDATE compra
    SET 
        fecha = COALESCE(@fecha, fecha),
        cedula = COALESCE(@cedula, cedula),
        devolucion = COALESCE(@devolución, devolucion)
    WHERE id_compra = @codigo;
    
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

-->Procedimiento de modificar una garantia, toma el codigo de la garantia como parametro para saber cual garantia alterar,
-- y luego se pueden modificar los siguientes campos: fecha_inicio, fecha_fin y descripcion.
GO
CREATE PROCEDURE ModificarGarantia
(
    @codigo INT, 
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL,
    @descripcion VARCHAR(200) = NULL
)
AS
BEGIN 
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM garantia WHERE id_garantia = @codigo)
        BEGIN
            RAISERROR('No existe una garantía con el código proporcionado.', 16, 1);
            RETURN;
        END
    UPDATE garantia
    SET 
        fecha_inicio = COALESCE(@fecha_inicio, fecha_inicio),
        fecha_fin = COALESCE(@fecha_fin, fecha_fin),
        descripcion = COALESCE(@descripcion, descripcion)
    WHERE id_garantia = @codigo;
    
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

-->Procedimiento de modificar una devolución, toma el codigo de la devolución como parametro para saber cual devolución alterar,
-- y luego se pueden modificar los siguientes campos: producto_devuelto, fecha_devolucion, razon y estado.
GO
CREATE PROCEDURE ModificarDevolución
(
    @codigo INT, 
    @producto_devuelto INT = NULL,
    @fecha_devolucion DATE = NULL,
    @razon VARCHAR(100) = NULL,
    @estado VARCHAR(20) = NULL
)
AS
BEGIN 
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM devolucion WHERE id_devolucion = @codigo)
        BEGIN
            RAISERROR('No existe una devolución con el código proporcionado.', 16, 1);
            RETURN;
        END
    UPDATE devolucion
    SET 
        producto_devuelto = COALESCE(@producto_devuelto, producto_devuelto),
        fecha_devolucion = COALESCE(@fecha_devolucion, fecha_devolucion),
        razon = COALESCE(@razon, razon),
        estado = COALESCE(@estado, estado)
    WHERE id_devolucion = @codigo;
    
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;           

-->IMPORTANTE: se cambio el dato varchar de la columna producto_devuelto a int, 
-- ya que se relaciona con la tabla producto
ALTER TABLE devolucion
    ALTER COLUMN producto_devuelto INT;

-->Procedimiento de modificar un pedido, toma el codigo del pedido como parametro para saber cual pedido alterar,
-- y luego se pueden modificar los siguientes campos: cedula del cliente, estado, fecha, distrito y señas.
GO
CREATE PROCEDURE ModificarPedido
(
    @codigo INT, 
    @cedula INT = NULL,
    @estado TINYINT = NULL, 
    @fecha DATE = NULL,
    @distrito VARCHAR(200) = NULL,
    @señas VARCHAR(200) = NULL
)
AS
BEGIN 
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM pedido WHERE id_pedido = @codigo)
        BEGIN
            RAISERROR('No existe una garantía de producto con el código proporcionado.', 16, 1);
            RETURN;
        END
    UPDATE pedido
    SET 
        cedula = COALESCE(@cedula, cedula),
        estado = COALESCE(@estado, estado),
        fecha = COALESCE(@fecha, fecha),
        distrito = COALESCE(@distrito, distrito),
        señas = COALESCE(@señas, señas)
    WHERE id_pedido = @codigo;
    
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;

-->Procedimiento de modificar un detalle de pedido, toma el id del pedido como parametro para saber cual detalle alterar,
-- y luego se pueden modificar los siguientes campos: cantidad y observaciones.
GO
CREATE PROCEDURE ModificarDetallesPedido
(
    @id_pedido INT = NULL,
    @cantidad INT = NULL,
    @observaciones VARCHAR(200) = NULL
)
AS 
BEGIN 
    BEGIN TRY 
    IF NOT EXISTS (SELECT 1 FROM detalles_pedido WHERE id_pedido = @id_pedido)
        BEGIN
            RAISERROR('No existe un detalle de pedido con el código proporcionado.', 16, 1);
            RETURN;
        END
    UPDATE detalles_pedido
    SET 
        cantidad = COALESCE(@cantidad, cantidad),
        observaciones = COALESCE(@observaciones, observaciones)
    WHERE id_pedido = @id_pedido;
    
    END TRY
    BEGIN CATCH
        ROLLBACK 
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;


SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'detalles_pedido';