-->Todos los procedimeitnos de INSERCIÓN de la base de datos SistemaDeGestion, 
-->Con un ejemplo de inserción al final de cada uno para asegurar que funciona

USE SistemaDeGestion;

-->Visualizar las tablas de la base de datos junto con el tipo de dato de cada columna, para consulta
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'garantia';

-->Procedimeinto para insertar personas, con verificación de datos para no insertar cedulas repetidas, 
-- distritos inexistentes, y campos vacíos. 
GO
CREATE PROCEDURE InsertarPersona
(
    @cedula INT, 
    @nombre VARCHAR(30),
    @apellido1 VARCHAR(30),
    @apellido2 VARCHAR(30),
    @distrito INT, 
    @señas VARCHAR(200)
)
AS 
BEGIN 
    BEGIN TRY
        IF @cedula IN (SELECT cedula FROM persona)
            BEGIN 
                SELECT 'La persona ya existe.' AS Mensaje;
                RETURN;
            END
        IF @distrito NOT IN (SELECT id_distrito FROM distritos)
            BEGIN 
                SELECT 'El distrito no existe.' AS Mensaje;
                RETURN;
            END
        IF @cedula IS NULL OR @nombre IS NULL OR @apellido1 IS NULL OR @apellido2 IS NULL OR @señas IS NULL
            BEGIN 
                SELECT 'Todos los campos son obligatorios.' AS Mensaje;
                RETURN;
            END
        INSERT INTO persona (cedula, nombre, apellido1, apellido2, distrito, señas)
        VALUES (@cedula, @nombre, @apellido1, @apellido2, @distrito, @señas);
        SELECT 'Cliente insertado correctamente.' AS Mensaje;

    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END; 
GO 

EXEC InsertarPersona
    @cedula = 12345678, 
    @nombre = 'Juan', 
    @apellido1 = 'Pérez', 
    @apellido2 = 'Gómez', 
    @distrito = 1, 
    @señas = 'Calle Falsa 123';

select * from persona

-->Procedimiento para insertar clientes, verificando que la persona exista antes de insertarla como cliente.
GO
CREATE PROCEDURE InsertarCliente
(
    @cedulaCliente INT
)
AS 
BEGIN 

    IF @cedulaCliente IN (SELECT cedula FROM persona)
        BEGIN TRY 
            INSERT INTO cliente(cedula)
            VALUES (@cedulaCliente)

            SELECT 'Cliente insertado correctamente.' AS Mensaje;
        END TRY
        BEGIN CATCH
            SELECT 
                ERROR_NUMBER() AS ErrorNumero,
                ERROR_MESSAGE() AS ErrorMensaje;
        END CATCH
    ELSE 
        BEGIN 
            SELECT 'El cliente no existe.' AS Mensaje;
        END
END;
GO

EXEC InsertarCliente @cedulaCliente = 12345678; 

-->Procedimiento para insertar administrativos, verificando que la persona exista antes de insertarla.
GO
CREATE PROCEDURE InsertarAdministrativo
(
    @cedulaAdministrativo INT
)
AS 
BEGIN 
    IF @cedulaAdministrativo IN (SELECT cedula FROM persona)
        BEGIN TRY 
            INSERT INTO administrativos(cedula)
            VALUES (@cedulaAdministrativo)

            SELECT 'Administrativo insertado correctamente.' AS Mensaje;
        END TRY
        BEGIN CATCH
            SELECT 
                ERROR_NUMBER() AS ErrorNumero,
                ERROR_MESSAGE() AS ErrorMensaje;
        END CATCH
    ELSE 
        BEGIN 
            SELECT 'El administrativo no existe.' AS Mensaje;
        END
END;
GO

EXEC InsertarAdministrativo @cedulaAdministrativo = 12345678;

-->Procedimiento para insertar teléfonos de personas, verificando que la persona exista antes de insertarlo, 
-- y que el formato del teléfono sea válido.
GO
CREATE PROCEDURE InsertarTelefonoPersona
(
    @cedulaTelefono INT, 
    @telefono VARCHAR(15)
)
AS
BEGIN 
    BEGIN TRY
        IF @cedulaTelefono NOT IN (SELECT cedula FROM persona)
            BEGIN 
                SELECT 'La persona no existe.' AS Mensaje;
                RETURN;
            END
        
        IF @telefono NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' OR LEN(@telefono) < 9
            BEGIN 
                SELECT 'Formato de teléfono inválido.' AS Mensaje;
                RETURN;
            END
            
        INSERT INTO telefonos_personas (cedula, telefono)
        VALUES (@cedulaTelefono, @telefono);
            
        SELECT 'Teléfono insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;
GO 

EXEC InsertarTelefonoPersona @cedulaTelefono = 12345678, @telefono = '8888-9888';

-->Procedimiento para insertar correos de personas, verificando que la persona exista antes de insertarlo,
-- que el formato del correo sea válido, y que el correo no esté ya registrado.
GO
CREATE PROCEDURE InsertarCorreoPersona
(
    @cedulaCorreo INT, 
    @correo VARCHAR(50)
)
AS
BEGIN
    BEGIN TRY
        IF @cedulaCorreo NOT IN (SELECT cedula FROM persona) 
            BEGIN 
                SELECT 'La persona no existe.' AS Mensaje;
                RETURN;
            END
        IF @correo NOT LIKE '%_@__%.__%' 
            BEGIN 
                SELECT 'Formato de correo inválido.' AS Mensaje;
                RETURN;
            END
        IF @correo IN (SELECT correo FROM correos_personas)
            BEGIN 
                SELECT 'El correo ya esta registrado.' AS Mensaje;
                RETURN;
            END
            
        INSERT INTO correos_personas(cedula, correo)
        VALUES (@cedulaCorreo, @correo);
    END TRY 
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

EXEC InsertarCorreoPersona @cedulaCorreo = 12345678, @correo = 'juanperes@gmail.com';
SELECT * FROM correos_personas;


-->Procedimiento para insertar productos, verificando que el nombre y marca no esté vacío o que ya este registrado, 
-- que el precio sea mayor a cero, que el stock no sea negativo, y que la descripción no esté vacía.
--El id de la tabla es autoincremental
GO
CREATE PROCEDURE InsertarProducto
(
    @nombreProducto VARCHAR(50),
    @precio DECIMAL(10, 2),
    @marca VARCHAR(30),
    @stock INT, 
    @id_categoria INT, 
    @descripcion VARCHAR(200)
)
AS 
BEGIN 
    BEGIN TRY 
        IF @nombreProducto IN (SELECT nombre FROM producto)
            BEGIN 
                SELECT 'El producto ya ha sido registrado bajo este nombre.' AS Mensaje;
                RETURN;
            END
        IF @nombreProducto IS NULL OR @nombreProducto = ''
             BEGIN 
                SELECT 'El nombre del producto no puede estar vacío.' AS Mensaje;
                RETURN;
            END

        IF @precio <= 0
            BEGIN 
                SELECT 'El precio debe ser mayor que cero.' AS Mensaje;
                RETURN;
            END

         IF @marca IS NULL OR @marca = ''
            BEGIN 
                SELECT 'La marca no puede estar vacía.' AS Mensaje;
                RETURN;
            END

        IF @stock < 0
            BEGIN 
                SELECT 'El stock no puede ser negativo.' AS Mensaje;
                RETURN;
            END

        IF @descripcion IS NULL OR @descripcion = ''
            BEGIN 
                SELECT 'La descripción no puede estar vacía.' AS Mensaje;
                RETURN;
            END

        INSERT INTO producto(nombre, precio, marca, stock, id_categoria, descripcion)
        VALUES (@nombreProducto, @precio, @marca, @stock, @id_categoria, @descripcion);
        SELECT 'Producto insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

EXEC InsertarProducto @nombreProducto = 'Producto A', @precio = 10.50, @marca = 'Marca A', @stock = 100, @id_categoria = 1, @descripcion = 'Descripción del producto A';
SELECT * FROM producto;

-->Procedimiento para insertar un administrador de producto, verificando que el administrativo y el producto existan.
GO
CREATE PROCEDURE InsertarAdministradorProducto
(
    @cedulaAdministrador INT, 
    @idProducto INT
)
AS 
BEGIN 
    BEGIN TRY
        IF @cedulaAdministrador NOT IN (SELECT cedula FROM administrativos)
            BEGIN 
                SELECT 'El administrativo no existe.' AS Mensaje;
                RETURN;
            END

        IF @idProducto NOT IN (SELECT id_producto FROM producto)
            BEGIN 
                SELECT 'El producto no existe.' AS Mensaje;
                RETURN;
            END
            
        INSERT INTO administrador_producto(cedula, producto)
        VALUES (@cedulaAdministrador, @idProducto);

        SELECT 'Administrador de producto insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
        END CATCH
        RETURN;
END;
GO 

EXEC InsertarAdministradorProducto @cedulaAdministrador = 12345678, @idProducto = 3;

-->Procedimiento para insertar un producto de computación, verificando que el producto exista y que la gama no esté vacía.
GO
CREATE PROCEDURE InsertarProductoComputación
(
    @id INT, 
    @gama VARCHAR(15)
)
AS
BEGIN 
    BEGIN TRY
        IF @id NOT IN (SELECT id_producto FROM producto)
            BEGIN 
                SELECT 'El producto no existe.' AS Mensaje;
                RETURN;
            END

        IF @gama IS NULL OR @gama = ''
            BEGIN 
                SELECT 'La gama no puede estar vacía.' AS Mensaje;
                RETURN;
            END

        INSERT INTO computacion(id, gama)
        VALUES (@id, @gama);

        SELECT 'Producto de computación insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

EXEC InsertarProductoComputación @id = 3, @gama = 'Alta';

-->Procedimiento para insertar un producto de tecnología, verificando que el producto exista y que la resistencia no esté vacía.
GO
CREATE PROCEDURE InsertarProductoTecnología
(
    @id INT, 
    @resistencia VARCHAR(15)
)
AS
BEGIN 
    BEGIN TRY
        IF @id NOT IN (SELECT id_producto FROM producto)
            BEGIN 
                SELECT 'El producto no existe.' AS Mensaje;
                RETURN;
            END

        IF @resistencia IS NULL OR @resistencia = ''
            BEGIN 
                SELECT 'La resistencia no puede estar vacía.' AS Mensaje;
                RETURN;
            END

        INSERT INTO tecnologia(id, resistencia)
        VALUES (@id, @resistencia);

        SELECT 'Producto de tecnologia insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

EXEC InsertarProductoTecnología @id = 3, @resistencia = 'Alta';
SELECT * FROM tecnologia

-->Procedimiento para insertar un producto de línea blanca, verificando que el producto exista y que la dimensión no esté vacía.       
GO
CREATE PROCEDURE InsertarProductoLineaBlanca
(
    @id INT, 
    @dimension VARCHAR(15)
)
AS
BEGIN 
    BEGIN TRY
        IF @id NOT IN (SELECT id_producto FROM producto)
            BEGIN 
                SELECT 'El producto no existe.' AS Mensaje;
                RETURN;
            END

        IF @dimension IS NULL OR @dimension = ''
            BEGIN 
                SELECT 'La gama no puede estar vacía.' AS Mensaje;
                RETURN;
            END

        INSERT INTO linea_blanca(id, dimensiones)
        VALUES (@id, @dimension);

        SELECT 'Producto de linea blanca insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

EXEC InsertarProductoLineaBlanca @id = 3, @dimension = 'Alta';
SELECT * FROM linea_blanca

-->Procedimiento para insertar un pedido, verificando que el cliente exista, que el estado sea válido,
-- que el distrito exista, y que los detalles y señas no estén vacíos.
-->Se agrego una nueva tabla de estado, 0 (Pendiente), 1 (Enviado), 2 (Entregado) o 3 (Cancelado) que tiene estos valores
--no son modificables y no se pueden añadir más estados. Es una tabla de referencia
--El id es autoincremental 
GO
CREATE PROCEDURE InsertarPedido
(
    @cedula INT, 
    @estado TINYINT, 
    @fecha DATE, 
    @distrito INT, 
    @señas VARCHAR(200)
) 
AS
BEGIN 
    BEGIN TRY 
        IF @cedula NOT IN (SELECT cedula FROM cliente)
            BEGIN 
                SELECT 'El cliente no existe.' AS Mensaje;
                RETURN;
            END

        IF @estado NOT IN (0, 1, 2, 3)
            BEGIN 
                SELECT 'Estado inválido. Debe ser 0 (Pendiente), 1 (Enviado), 2 (Entregado) o 3 (Cancelado).' AS Mensaje;
                RETURN;
            END

        IF @distrito NOT IN (SELECT id_distrito FROM distritos)
            BEGIN 
                SELECT 'El distrito no existe.' AS Mensaje;
                RETURN;
            END

        INSERT INTO pedido(cedula, estado, fecha, distrito, señas)
        VALUES (@cedula, @estado, @fecha, @distrito, @señas);

        SELECT 'Pedido insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END; 


EXEC InsertarPedido 
    @cedula = 12345678, 
    @estado = 0, 
    @fecha = '2023-10-01', 
    @distrito = 1, 
    @señas = 'Calle Falsa 123';
SELECT * FROM pedido

-->Procedimiento para insertar detalles de un pedido, verificando que el pedido exista, que la cantidad sea mayor a cero,
-- y que las observaciones no estén vacías.
GO
CREATE PROCEDURE InsertarDetallesPedido
(
    @id_pedido INT, 
    @cantidad INT, 
    @observaciones VARCHAR(200)
)
AS
BEGIN 
    BEGIN TRY 
        IF @id_pedido NOT IN (SELECT id_pedido FROM pedido)
            BEGIN 
                SELECT 'El pedido no existe.' AS Mensaje;
                RETURN;
            END

        IF @cantidad <= 0
            BEGIN 
                SELECT 'La cantidad debe ser mayor que cero.' AS Mensaje;
                RETURN;
            END

        IF @observaciones IS NULL OR @observaciones = ''
            BEGIN 
                SELECT 'Las observaciones no pueden estar vacías.' AS Mensaje;
                RETURN;
            END

        INSERT INTO detalles_pedido(id_pedido, cantidad, observaciones)
        VALUES (@id_pedido, @cantidad, @observaciones);

        SELECT 'Detalles del pedido insertados correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END; 

EXEC InsertarDetallesPedido 
    @id_pedido = 1, 
    @cantidad = 2, 
    @observaciones = 'Cosas de pedidos';
SELECT * FROM detalles_pedido;

-->Procedimiento para insertar un pedido de compra, verificando que el pedido y la compra existan.
GO
CREATE PROCEDURE InsertarPedidoCompra
(
    @id_pedido INT, 
    @id_compra INT
)
AS
BEGIN 
    BEGIN TRY 
        IF @id_pedido NOT IN (SELECT id_pedido FROM pedido)
            BEGIN 
                SELECT 'El pedido no existe.' AS Mensaje;
                RETURN;
            END

        IF @id_compra NOT IN (SELECT id_compra FROM compra)
            BEGIN 
                SELECT 'La compra no existe.' AS Mensaje;
                RETURN;
            END

        INSERT INTO pedido_compra(id_pedido, id_compra)
        VALUES (@id_pedido, @id_compra);

        SELECT 'Pedido de compra insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

-->Procedimiento para insertar una compra, verificando que la fecha no esté vacía, que el cliente exista,
-- y que la devolución sea válida (puede ser NULL).
--El id es autoincremental 
GO 
CREATE PROCEDURE InsertarCompra
(
    @fecha DATE, 
    @cedula INT, 
    @devolucion INT,
    @id_generado INT OUTPUT -- Parámetro de salida para el ID generado automáticamente
)
AS
BEGIN 
    BEGIN TRY 
        IF @cedula NOT IN (SELECT cedula FROM cliente)
            BEGIN 
                SELECT 'El cliente no existe.' AS Mensaje;
                RETURN;
            END

        INSERT INTO compra(fecha, cedula, devolucion)
        VALUES (@fecha, @cedula, @devolucion);

        SET @id_generado = SCOPE_IDENTITY(); -- Recupera el ID generado automáticamente para la compra para usarlo en otras inserciones

        SELECT 'Compra insertada correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

EXEC InsertarCompra 
    @fecha = '2023-10-01', 
    @cedula = 12345678, 
    @devolucion = NULL;
SELECT * FROM compra;

-->Procedimiento para insertar una devolución, verificando que el producto exista, que la fecha no esté vacía,
-- que el motivo no esté vacío, y que el estado sea válido (0, 1 o 2).
-->Se creo una nueva tabla de estado_devolucion, con los estados 0 (Pendiente), 1 (Aprobada) y 2 (Rechazada). 
--Es una tabla de referencia y no se pueden añadir más estados. 
--El id de la tabla es autoincremental 
GO 
CREATE PROCEDURE InsertarDevolucion
(
    @producto INT, 
    @fecha_devolucion DATE, 
    @motivo VARCHAR(200),
    @estado TINYINT
)
AS
BEGIN 
    BEGIN TRY 
        IF @fecha_devolucion IS NULL OR @fecha_devolucion = '' OR @fecha_devolucion > GETDATE() OR @fecha_devolucion < '2000-01-01'
            BEGIN 
                SELECT 'La fecha de devolución no puede estar vacía, ser mayor a la fecha actual, o ser menor al 2000' AS Mensaje;
                RETURN;
            END
        IF @motivo IS NULL OR @motivo = ''
            BEGIN 
                SELECT 'El motivo de la devolución no puede estar vacío.' AS Mensaje;
                RETURN;
            END

        IF @estado NOT IN (0, 1, 2)
            BEGIN 
                SELECT 'Estado inválido. Debe ser 0 (Pendiente), 1 (Aprobada) o 2 (Rechazada).' AS Mensaje;
                RETURN;
            END

        INSERT INTO devolucion(producto_devuelto, fecha_devolucion, razon, estado)
        VALUES (@producto, @fecha_devolucion, @motivo, @estado);

        SELECT 'Devolución insertada correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

EXEC InsertarDevolucion 
    @producto = 3, 
    @fecha_devolucion = '2023-10-01', 
    @motivo = 'Producto defectuoso', 
    @estado = 0;
SELECT * FROM devolucion 

-->Procedimiento para insertar una garantía, verificando que las fechas no estén vacías, que la fecha de inicio sea menor a la fecha de fin,
-- que las fechas estén dentro de un rango válido (2000-01-01 a fecha actual), y que la descripción no esté vacía.
--> El id de la tabla es autoincremental 
GO 

CREATE PROCEDURE InsertarGarantia
(
    @fecha_inicio DATE, 
    @fecha_fin DATE,
    @descripcion VARCHAR(200),
    @id_generado INT OUTPUT -- Parámetro de salida para el ID generado automáticamente
)
AS 
BEGIN 
    BEGIN TRY 
        IF @fecha_inicio IS NULL OR @fecha_fin IS NULL OR @fecha_inicio >= @fecha_fin
            BEGIN 
                SELECT 'Las fechas de inicio y fin son inválidas.' AS Mensaje;
                RETURN;
            END

        IF @fecha_inicio < '2000-01-01' OR @fecha_fin > GETDATE()
            BEGIN 
                SELECT 'Las fechas deben estar entre el 2000-01-01 y la fecha actual.' AS Mensaje;
                RETURN;
            END

        IF @descripcion IS NULL OR @descripcion = ''
            BEGIN 
                SELECT 'La descripción no puede estar vacía.' AS Mensaje;
                RETURN;
            END

        INSERT INTO garantia(fecha_inicio, fecha_fin, descripcion)
        VALUES (@fecha_inicio, @fecha_fin, @descripcion);

        SET @id_generado = SCOPE_IDENTITY(); -- Recupera el ID generado automáticamente para la garantía

        SELECT 'Garantía insertada correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

EXEC InsertarGarantia 
    @fecha_inicio = '2023-01-01', 
    @fecha_fin = '2024-01-01', 
    @descripcion = 'Garantía de prueba';
SELECT * FROM garantia

-->Procedimiento para insertar una compra de producto, verificando que la compra y el producto existan,
-- que la garantía sea válida (no negativa), que el monto pagado sea mayor a cero, y que el método de pago no esté vacío.
GO
CREATE PROCEDURE InsertarCompraProducto
(
    @id_compra INT, 
    @id_producto INT, 
    @garantia INT, 
    @monto_pagado FLOAT, 
    @metodo_pago VARCHAR(20)
)
AS 
BEGIN 
    BEGIN TRY 
        IF @id_compra NOT IN (SELECT id_compra FROM compra)
            BEGIN 
                SELECT 'La compra no existe.' AS Mensaje;
                RETURN;
            END

        IF @id_producto NOT IN (SELECT id_producto FROM producto)
            BEGIN 
                SELECT 'El producto no existe.' AS Mensaje;
                RETURN;
            END

        IF @garantia < 0
            BEGIN 
                SELECT 'La garantía no puede ser negativa.' AS Mensaje;
                RETURN;
            END

        IF @monto_pagado <= 0
            BEGIN 
                SELECT 'El monto pagado debe ser mayor que cero.' AS Mensaje;
                RETURN;
            END

        IF @metodo_pago IS NULL OR @metodo_pago = ''
            BEGIN 
                SELECT 'El método de pago no puede estar vacío.' AS Mensaje;
                RETURN;
            END

        INSERT INTO compra_producto(id_compra, id_producto, garantia, monto_pagado, metodo_pago)
        VALUES (@id_compra, @id_producto, @garantia, @monto_pagado, @metodo_pago);

        SELECT 'Compra de producto insertada correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;

SELECT * FROM compra

EXEC InsertarCompraProducto 
    @id_compra = 1, 
    @id_producto = 3, 
    @garantia = 1, 
    @monto_pagado = 100.00, 
    @metodo_pago = 'Tarjeta de crédito';
SELECT * FROM compra_producto

-->Procedimiento para insertar provincias, verificando que no existan duplicados.
-- ID autoincremental 
GO
CREATE PROCEDURE InsertarProvincia
AS 
BEGIN
    BEGIN TRY
        INSERT INTO provincias (provincia)
        VALUES ('San José'),
               ('Alajuela'),
               ('Cartago'),
               ('Heredia'),
               ('Guanacaste'),
               ('Puntarenas'),
               ('Limón');
        
        SELECT 'Provincia insertada correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;
exec InsertarProvincia;

SELECT * FROM cantones

-->Procedimiento para insertar cantones, verificando que la provincia exista y que no existan duplicados.
-- ID autoincremental
GO
CREATE PROCEDURE InsertarCanton 
AS 
BEGIN 
    BEGIN TRY 
        INSERT INTO cantones (canton, id_provincia)
        VALUES  ('San José', 1),
                ('Escazú', 1),
                ('Desamparados', 1),
                ('Alajuela', 2),
                ('San Ramón', 2),
                ('Cartago', 3),
                ('Paraíso', 3),
                ('Heredia', 4),
                ('Barva', 4),
                ('Liberia', 5),
                ('Nicoya', 5),
                ('Puntarenas', 6),
                ('Esparza', 6),
                ('Limón', 7),
                ('Guápiles', 7);
        
        SELECT 'Cantón insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END;
GO 
EXEC InsertarCanton;
SELECT * FROM cantones

-->Procedimiento para insertar distritos, verificando que el cantón exista y que no existan duplicados.
-- ID autoincremental
GO
CREATE PROCEDURE InsertarDistrito
AS 
BEGIN 
    BEGIN TRY 
        INSERT INTO distritos (distrito, id_canton)
        VALUES  ('Carmen', 1),
                ('Merced', 1),
                ('Hospital', 1),
                ('Zapote', 1),
                ('San Francisco', 1),
                ('Uruca', 1),
                ('Mata Redonda', 1),
                ('Pavas', 1),
                ('Hatillo', 1),
                ('San Sebastián', 1),
                ('Calle Blancos', 1),
                ('San Francisco de Dos Ríos', 1),
                ('Escazú',2),
                ('San Antonio',2),
                ('San Rafael',2),
                ('Desamparados',3),
                ('San Miguel',3),
                ('San Juan de Dios',3),
                ('San Vicente',3), 
                ('San Atonio',3), 
                ('Patarrá', 3), 
                ('Frailes', 3), 
                ('San Cristóbal', 3), 
                ('Rosario', 3), 
                ('Gravilias', 3), 
                ('Los Guido', 3),
                ('Alajuela',4),
                ('San José',4),
                ('Sabanilla',4), 
                ('Garita', 4), 
                ('Tambor', 4), 
                ('Sarapiquí', 4), 
                ('Guácima', 4), 
                ('Desemparados', 4), 
                ('San Rafael', 4), 
                ('San Antonio', 4), 
                ('San Isidro', 4), 
                ('San Juan', 4), 
                ('San Pedro', 4), 
                ('San Pablo', 4),
                ('San Ramón',5),
                ('Santiago',5),
                ('San Juan',5),
                ('Piedades del Sur',5),
                ('Piedades del Norte',5),
                ('San Isidro',5),
                ('Los Ángeles',5),
                ('Volio', 5),
                ('Concepción', 5),
                ('Oriental',6),
                ('Carmen',6),
                ('Occidental',6),
                ('San Nicolas',6),
                ('Corralillo', 6),
                ('Llano Grande', 6),
                ('Agua Caliente', 6),
                ('Tierra Blanca', 6),
                ('Dulce Nombre', 6),
                ('Guadalupe', 6), 
                ('Paraíso',7),
                ('Santiago',7), 
                ('Orosi', 7), 
                ('Cachí', 7), 
                ('Llanos de Santa Lucía', 7),
                ('Heredia', 8), 
                ('Mercedes', 8), 
                ('San Francisco', 8), 
                ('Ulloa', 8), 
                ('Varablanca', 8), 
                ('Barva', 9), 
                ('San Pedro', 9), 
                ('San Pablo', 9), 
                ('San Roque', 9), 
                ('Santa Lucía', 9), 
                ('San José de la Montaña', 9), 
                ('Liberia', 10), 
                ('Cañas Dulces', 10), 
                ('Mayorga', 10), 
                ('Nacascolo', 10), 
                ('Curubandé', 10),
                ('Nicoya', 11), 
                ('Mansion', 11), 
                ('San Antonio', 11), 
                ('Quebrada Honda', 11), 
                ('Sámara', 11), 
                ('Nosara', 11), 
                ('Bélen de Nosarita', 11), 
                ('Puntarenas', 12), 
                ('Pitahaya', 12), 
                ('Chomes', 12), 
                ('Lepanto', 12), 
                ('Paquera', 12), 
                ('Manzanillo', 12), 
                ('Guacimal', 12), 
                ('Barranca', 12), 
                ('Monte verde', 12), 
                ('Isla del Coco', 12),
                ('Cóbano', 12), 
                ('Espíritu Santo', 13), 
                ('San Juan Grande', 13), 
                ('Macacona', 13), 
                ('San Rafael', 13), 
                ('San Jerónimo', 13), 
                ('Limón', 14), 
                ('Valle La Estrella', 14), 
                ('Río Blanco', 14), 
                ('Matama', 14), 
                ('Guápiles', 15), 
                ('Jiménez', 15), 
                ('Rita', 15), 
                ('Roxana', 15), 
                ('Cariari', 15), 
                ('Colorado', 15), 
                ('La Colonia', 15)
                ;
        
        SELECT 'Distrito insertado correctamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumero,
            ERROR_MESSAGE() AS ErrorMensaje;
    END CATCH
END; 
GO
EXEC InsertarDistrito;
SELECT * FROM distritos;
