Use RentaMovil;
go




CREATE TABLE Log_Auditoria (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tabla VARCHAR(100) NOT NULL,
    tipo_operacion CHAR(10) NOT NULL,
    fecha_registro DATETIME DEFAULT GETDATE(),
    usuario_bd VARCHAR(100) DEFAULT SUSER_SNAME(),
    registro_afectado_id INT,
    detalle_cambio NVARCHAR(MAX) 
);
GO


-- Trigger 1.1: INSTEAD OF para prevenir reservas y registrar cambios (INSERT/UPDATE)
CREATE TRIGGER tr_Reserva_INSTEAD_OF
ON Reserva
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted I
        INNER JOIN Vehiculo V ON I.id_vehiculo = V.id_vehiculo
        WHERE V.estado IN ('En Mantenimiento', 'No Disponible')
    )
    BEGIN
        RAISERROR('ERROR: El vehículo no se puede reservar. Su estado actual es En Mantenimiento o No Disponible.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM deleted) AND EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
        SELECT 
            'Reserva', 'UPDATE', I.id_reserva,
            'Estado: ' + D.estado + ' -> ' + I.estado + '. Total: ' + CAST(D.valor_total AS VARCHAR) + ' -> ' + CAST(I.valor_total AS VARCHAR)
        FROM inserted I
        INNER JOIN deleted D ON I.id_reserva = D.id_reserva;

        UPDATE R
        SET id_cliente = I.id_cliente, id_vehiculo = I.id_vehiculo, fecha_reserva = I.fecha_reserva, fecha_inicio = I.fecha_inicio, fecha_fin = I.fecha_fin, tipo_res = I.tipo_res, valor_total = I.valor_total, estado = I.estado, sucursal_recog = I.sucursal_recog, sucursal_entre = I.sucursal_entre, condicion_vehiculo = I.condicion_vehiculo
        FROM Reserva R INNER JOIN inserted I ON R.id_reserva = I.id_reserva;
    END
    ELSE 
    BEGIN
        INSERT INTO Reserva (id_reserva, id_cliente, id_vehiculo, fecha_reserva, fecha_inicio, fecha_fin, tipo_res, valor_total, estado, sucursal_recog, sucursal_entre, condicion_vehiculo)
        SELECT id_reserva, id_cliente, id_vehiculo, fecha_reserva, fecha_inicio, fecha_fin, tipo_res, valor_total, estado, sucursal_recog, sucursal_entre, condicion_vehiculo
        FROM inserted;

        INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
        SELECT 
            'Reserva', 'INSERT', I.id_reserva,
            'Nueva reserva en estado: ' + I.estado + '. Total: ' + CAST(I.valor_total AS VARCHAR) + '. Cliente ID: ' + CAST(I.id_cliente AS VARCHAR)
        FROM inserted I;
    END
END;
GO

-- Trigger 1.2: AFTER DELETE para registrar la eliminación de una reserva
CREATE TRIGGER tr_Reserva_AFTER_DELETE
ON Reserva
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
    SELECT 
        'Reserva', 'DELETE', D.id_reserva,
        'Reserva Eliminada. Cliente: ' + CAST(D.id_cliente AS VARCHAR) + ', Vehículo: ' + CAST(D.id_vehiculo AS VARCHAR) +
        ', Monto: ' + CAST(D.valor_total AS VARCHAR)
    FROM deleted D;
END;
GO

-- Trigger 2.1: AFTER INSERT/UPDATE para cambiar estado del Vehículo y Log de Actualización/Inserción
CREATE TRIGGER tr_Mantenimiento_AFTER_IU
ON Mantenimiento_vehiculo
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE V
    SET V.estado = 'En Mantenimiento'
    FROM Vehiculo V
    INNER JOIN inserted I ON V.id_vehiculo = I.id_vehiculo
    WHERE I.estado IN ('En curso', 'Programado');
      
    UPDATE V
    SET V.estado = 'Disponible'
    FROM Vehiculo V
    INNER JOIN inserted I ON V.id_vehiculo = I.id_vehiculo
    INNER JOIN deleted D ON I.id_mantenimiento = D.id_mantenimiento
    WHERE I.estado = 'Completado' AND D.estado <> 'Completado';

    IF NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
        SELECT 
            'Mantenimiento_vehiculo', 'INSERT', I.id_mantenimiento,
            'Inicio de Mantenimiento (' + I.estado + '). Vehículo ID: ' + CAST(I.id_vehiculo AS VARCHAR) + '. Tipo MA: ' + CAST(I.id_tipo_ma AS VARCHAR)
        FROM inserted I;
    END
    ELSE 
    BEGIN
        INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
        SELECT 
            'Mantenimiento_vehiculo', 'UPDATE', I.id_mantenimiento,
            'Cambio de estado: ' + D.estado + ' -> ' + I.estado + '. Vehículo ID: ' + CAST(I.id_vehiculo AS VARCHAR)
        FROM inserted I
        INNER JOIN deleted D ON I.id_mantenimiento = D.id_mantenimiento
        WHERE I.estado <> D.estado OR I.fecha_fin <> D.fecha_fin; 
    END
END;
GO

-- Trigger 2.2: AFTER DELETE para registrar la eliminación de Mantenimiento
CREATE TRIGGER tr_Mantenimiento_AFTER_DELETE
ON Mantenimiento_vehiculo
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
    SELECT
        'Mantenimiento_vehiculo', 'DELETE', D.id_mantenimiento,
        'Vehículo ID: ' + CAST(D.id_vehiculo AS VARCHAR) + ', Estado Final: ' + D.estado + 
        ', Fechas: ' + CONVERT(VARCHAR, D.fecha_inicio, 101) + ' a ' + COALESCE(CONVERT(VARCHAR, D.fecha_fin, 101), 'N/A')
    FROM deleted D;
END;
GO

-- Trigger 3.1: AFTER INSERT para Notificación y Log
CREATE TRIGGER tr_Pago_AFTER_INSERT
ON Pago
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Notificación al cliente
    INSERT INTO Notificacion (id_persona, mensaje, fecha_envio, leido, id_reserva, id_pago)
    SELECT
        R.id_cliente,
        'Hemos recibido un pago de $' + CAST(I.monto AS VARCHAR) + ' por su reserva ' + CAST(I.id_reserva AS VARCHAR) + '.',
        GETDATE(),
        0,
        I.id_reserva,
        I.id_pago
    FROM inserted I
    INNER JOIN Reserva R ON I.id_reserva = R.id_reserva;

    INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
    SELECT 
        'Pago', 'INSERT', I.id_pago,
        'Monto: ' + CAST(I.monto AS VARCHAR) + ', Reserva ID: ' + CAST(I.id_reserva AS VARCHAR) + ', Método: ' + I.metodo
    FROM inserted I;
END;
GO

-- Trigger 3.2: AFTER UPDATE para Log
CREATE TRIGGER tr_Pago_AFTER_UPDATE
ON Pago
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
    SELECT 
        'Pago', 'UPDATE', I.id_pago,
        'Monto: ' + CAST(D.monto AS VARCHAR) + ' -> ' + CAST(I.monto AS VARCHAR) + 
        ', Método: ' + D.metodo + ' -> ' + I.metodo
    FROM inserted I
    INNER JOIN deleted D ON I.id_pago = D.id_pago
    WHERE I.monto <> D.monto OR I.metodo <> D.metodo;
END;
GO

-- Trigger 3.3: AFTER DELETE para Log
CREATE TRIGGER tr_Pago_AFTER_DELETE
ON Pago
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Log_Auditoria (nombre_tabla, tipo_operacion, registro_afectado_id, detalle_cambio)
    SELECT
        'Pago', 'DELETE', D.id_pago,
        'Monto Eliminado: ' + CAST(D.monto AS VARCHAR) + ', Reserva ID: ' + CAST(D.id_reserva AS VARCHAR) +
        ', Método: ' + D.metodo
    FROM deleted D;
END;
GO