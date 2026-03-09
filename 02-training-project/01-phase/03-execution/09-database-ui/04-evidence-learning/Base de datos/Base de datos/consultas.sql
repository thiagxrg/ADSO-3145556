
Use RentaMovil;
go


-- 1. Vehículos Disponibles en la sucursal de Neiva (ID 101)
SELECT
    placa,
    marca,
    modelo,
    anio
FROM Vehiculo
WHERE estado = 'Disponible'
AND id_sucursal = 101;

-- 2. Próximas Reservas (Reservas confirmadas que inician después de hoy y en los próximos 7 días)
SELECT
    id_reserva,
    id_cliente,
    fecha_inicio,
    fecha_fin
FROM Reserva
WHERE estado = 'Confirmada'
AND fecha_inicio BETWEEN GETDATE() AND DATEADD(day, 7, GETDATE());

-- 3. Empleados asignados a la sucursal de Neiva (ID 101)
SELECT
    nombre,
    apellido,
    correo,
    tipo_usu
FROM Persona
WHERE id_sucursal = 101
AND tipo_usu IN ('Empleado', 'Administrador');