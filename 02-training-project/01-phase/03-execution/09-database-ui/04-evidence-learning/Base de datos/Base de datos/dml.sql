
Use RentaMovil;
go
-- 1. TIPO_MANTENIMIENTO
INSERT INTO Tipo_mantenimiento (id_tipo_ma, nombre, descripcion) VALUES
(1, 'Preventivo Básico', 'Cambio de aceite y filtros.'),
(2, 'Correctivo Mayor', 'Reparación de motor o transmisión.'),
(3, 'Inspección General', 'Revisión de frenos, luces y suspensión.');

-- 2. SUCURSAL
INSERT INTO Sucursal (id_sucursal, nombre, direccion, ciudad, telefono) VALUES
(101, 'Neiva Principal', 'Carrera 5 # 10-20', 'Neiva', 8754321),
(102, 'Pitalito Centro', 'Calle 3 Sur # 5-15', 'Pitalito', 8361234);

-- 3. PERSONA (Teléfonos ahora encajan en BIGINT)
INSERT INTO Persona (id_persona, nombre, apellido, correo, telefono, password, tipo_usu, permiso_aquilar, id_sucursal) VALUES
(1, 'Thiago', 'Rojas', 'thiago.rojas@email.com', 3001234567, 'pass123', 'Cliente', 'Si', NULL),
(2, 'David', 'Erez', 'david.erez@email.com', 3109876543, 'pass123', 'Cliente', 'Si', NULL),
(3, 'Nicol', 'Ramirez', 'nicol.ramirez@email.com', 3205551122, 'pass123', 'Cliente', 'Si', NULL),
(4, 'Juan', 'Suaza', 'juan.suaza@email.com', 3154443322, 'pass123', 'Empleado', NULL, 101),
(5, 'Brayan', 'Patiño', 'brayan.patino@email.com', 3187779900, 'pass123', 'Administrador', NULL, 101),
(6, 'Juan', 'Ome', 'juan.ome@email.com', 3112233445, 'pass123', 'Empleado', NULL, 102);

-- 4. VEHICULO
INSERT INTO Vehiculo (id_vehiculo, placa, marca, modelo, anio, tipo_vehiculo, estado, id_sucursal) VALUES
(10, 'HUI123', 'Mazda', 'Mazda 3', 2022, 'Sedan', 'Disponible', 101),
(11, 'HUI456', 'Mazda', 'Mazda 3', 2023, 'Sedan', 'En Renta', 101),
(12, 'CAL789', 'Renault', 'Duster', 2021, 'SUV', 'En Mantenimiento', 102);

-- 5. UBICACION_GPS
INSERT INTO Ubicacion_gps (id_ubicacion, latitud, longitud, timestamp, id_vehiculo) VALUES
(1001, '2.9299', '-75.2863', GETDATE(), 10),
(1002, '2.9280', '-75.2850', GETDATE(), 11);

-- 6. MANTENIMIENTO_VEHICULO
INSERT INTO Mantenimiento_vehiculo (id_mantenimiento, id_vehiculo, id_tipo_ma, fecha_inicio, fecha_fin, estado) VALUES
(201, 12, 1, '2025-11-01', '2025-11-05', 'Completado'),
(202, 10, 3, '2025-12-05', NULL, 'Programado');

-- 7. RESERVA
INSERT INTO Reserva (id_reserva, id_cliente, id_vehiculo, fecha_reserva, fecha_inicio, fecha_fin, tipo_res, valor_total, estado, sucursal_recog, sucursal_entre, condicion_vehiculo) VALUES
(301, 1, 11, '2025-12-01', '2025-12-08', '2025-12-15', 'Diaria', 450.00, 'Confirmada', 101, 101, 'Perfecto estado'),
(302, 2, 10, '2025-12-05', '2025-12-16', '2025-12-20', 'Semanal', 300.50, 'Pendiente', 101, 102, 'Nuevo');

-- 8. PAGO
INSERT INTO Pago (id_pago, id_reserva, id_contrato, fecha_pago, monto, metodo) VALUES
(401, 301, 5001, '2025-12-01', 450.00, 'Tarjeta de Crédito'),
(402, 302, 5002, '2025-12-05', 100.00, 'PSE');

-- 9. NOTIFICACION
INSERT INTO Notificacion (id_notificacion, id_persona, mensaje, fecha_envio, leido, id_reserva, id_mantenimiento, id_pago) VALUES
(501, 1, 'Su reserva 301 ha sido confirmada.', GETDATE(), 0, 301, NULL, NULL),
(502, 4, 'El Mazda 3 (HUI123) requiere revisión.', GETDATE(), 0, NULL, 202, NULL),
(503, 2, 'Primer pago de la reserva 302 recibido.', GETDATE(), 1, 302, NULL, 402);
GO
