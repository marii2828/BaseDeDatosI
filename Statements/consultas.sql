
GO
CREATE PROCEDURE ConsultarInformacionClientes
(
    @cedula VARCHAR(20) = NULL
)
AS 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE cedula = @cedula)
        BEGIN
            RAISERROR('No existe una persona con la cédula proporcionada.', 16, 1);
            RETURN;
        END

    BEGIN TRY 
    SELECT 
        c.cedula AS [Cédula], 
        trim(p.nombre)+' '+trim(p.apellido1)+' '+trim(p.apellido2) AS [Nombre Completo],
        STUFF((SELECT ', ' + telefono FROM telefonos_personas WHERE cedula = p.cedula FOR XML PATH('')), 1, 2, '') AS [Teléfonos],
        STUFF((SELECT ', ' + correo FROM correos_personas WHERE cedula = p.cedula FOR XML PATH('')), 1, 2, '') AS [Correos Electrónicos],
        d.distrito AS [Distrito],
        ca.canton AS [Cantón],
        pr.provincia AS [Provincia]
    FROM 
        cliente c
    JOIN 
        persona p ON c.cedula = p.cedula
    JOIN
        distritos d ON p.distrito = d.id_distrito
    JOIN 
        cantones ca ON d.id_canton = ca.id_canton       
    JOIN
        provincias pr ON ca.id_provincia = pr.id_provincia
    WHERE 
        (@cedula IS NULL OR c.cedula = @cedula)
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS MensajeError;
    END CATCH
END;

select * from distritos