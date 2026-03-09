


Use RentaMovil;
go


-- 1. Detalle Completo de Reservas (Reserva + Cliente + Vehículo)
SELECT
    R.id_reserva,
    P.nombre AS Nombre_Cliente,
    P.apellido AS Apellido_Cliente,
    V.marca,
    V.modelo,
    V.placa,
    R.fecha_inicio,
    R.fecha_fin,
    R.valor_total
FROM Reserva R
INNER JOIN Persona P ON R.id_cliente = P.id_persona
INNER JOIN Vehiculo V ON R.id_vehiculo = V.id_vehiculo;

-- 2. Vehículos Actualmente en Mantenimiento (Vehículo + Mantenimiento + Tipo)
SELECT
    V.placa,
    V.marca,
    V.modelo,
    M.fecha_inicio AS Inicio_Mantenimiento,
    T.nombre AS Tipo_Mantenimiento,
    M.estado AS Estado_Actual
FROM Vehiculo V
INNER JOIN Mantenimiento_vehiculo M ON V.id_vehiculo = M.id_vehiculo
INNER JOIN Tipo_mantenimiento T ON M.id_tipo_ma = T.id_tipo_ma
WHERE M.estado IN ('En curso', 'Programado');

-- 3. Historial de Pagos por Cliente (Persona + Reserva + Pago)
SELECT
    P.nombre,
    P.apellido,
    R.id_reserva,
    A.fecha_pago,
    A.monto
FROM Pago A
INNER JOIN Reserva R ON A.id_reserva = R.id_reserva
INNER JOIN Persona P ON R.id_cliente = P.id_persona
ORDER BY P.apellido, A.fecha_pago DESC;

-- 4. Ubicación GPS Actual de los Vehículos (Vehiculo + Ubicacion_gps)
-- Nota: Esto asume que el ID de ubicación más alto para un vehículo es la ubicación más reciente.
WITH UltimaUbicacion AS (
    SELECT
        id_ubicacion,
        id_vehiculo,
        latitud,
        longitud,
        timestamp,
        -- Clasifica por fecha descendente para obtener el registro más reciente (fila 1)
        ROW_NUMBER() OVER(PARTITION BY id_vehiculo ORDER BY timestamp DESC) as rn
    FROM Ubicacion_gps
)
SELECT
    V.placa,
    V.marca,
    V.modelo,
    U.latitud,
    U.longitud,
    U.timestamp AS Ultima_Actualizacion
FROM Vehiculo V
INNER JOIN UltimaUbicacion U ON V.id_vehiculo = U.id_vehiculo
WHERE U.rn = 1;