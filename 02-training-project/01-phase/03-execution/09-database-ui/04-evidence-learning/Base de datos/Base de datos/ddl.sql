Use RentaMovil;
go


-- Creación de la tabla Tipo_mantenimiento
CREATE TABLE Tipo_mantenimiento (
    id_tipo_ma INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion VARCHAR(255)
);

-- Creación de la tabla Sucursal
CREATE TABLE Sucursal (
    id_sucursal INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    direccion VARCHAR(255),
    ciudad VARCHAR(255),
    telefono INT
);

-- Creación de la tabla Persona
CREATE TABLE Persona (
    id_persona INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    apellido VARCHAR(255) NOT NULL,
    correo VARCHAR(255) UNIQUE,
    telefono BIGINT,
    password VARCHAR(255) NOT NULL,
    tipo_usu VARCHAR(255) NOT NULL, -- Administrador, Cliente, Empleado, etc.
    permiso_aquilar VARCHAR(255), -- Podría ser un tipo ENUM o restringido si es necesario
    id_sucursal INT,
    
    FOREIGN KEY (id_sucursal) REFERENCES Sucursal(id_sucursal)
);

-- Creación de la tabla Vehiculo
CREATE TABLE Vehiculo (
    id_vehiculo INT PRIMARY KEY,
    placa VARCHAR(255) UNIQUE NOT NULL,
    marca VARCHAR(255),
    modelo VARCHAR(255),
    anio INT,
    tipo_vehiculo VARCHAR(255),
    estado VARCHAR(255) NOT NULL, -- Disponible, En Renta, En Mantenimiento, etc.
    id_sucursal INT,
    
    FOREIGN KEY (id_sucursal) REFERENCES Sucursal(id_sucursal)
);

-- Creación de la tabla Ubicacion_gps
CREATE TABLE Ubicacion_gps (
    id_ubicacion INT PRIMARY KEY,
    latitud VARCHAR(255) NOT NULL,
    longitud VARCHAR(255) NOT NULL,
    timestamp DATETIME NOT NULL,
    id_vehiculo INT,
    
    FOREIGN KEY (id_vehiculo) REFERENCES Vehiculo(id_vehiculo)
);

-- Creación de la tabla Mantenimiento_vehiculo
CREATE TABLE Mantenimiento_vehiculo (
    id_mantenimiento INT PRIMARY KEY,
    id_vehiculo INT,
    id_tipo_ma INT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    estado VARCHAR(255) NOT NULL, -- En curso, Completado, Programado, etc.
    
    FOREIGN KEY (id_vehiculo) REFERENCES Vehiculo(id_vehiculo),
    FOREIGN KEY (id_tipo_ma) REFERENCES Tipo_mantenimiento(id_tipo_ma)
);

-- Creación de la tabla Reserva
CREATE TABLE Reserva (
    id_reserva INT PRIMARY KEY,
    id_cliente INT, -- id_persona del tipo Cliente
    id_vehiculo INT,
    fecha_reserva DATE NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    tipo_res VARCHAR(255),
    valor_total DOUBLE PRECISION NOT NULL, -- DOUBLE PRECISION para SQL Server (equivale a DOUBLE o FLOAT)
    estado VARCHAR(255) NOT NULL, -- Pendiente, Confirmada, Cancelada, etc.
    sucursal_recog INT,
    sucursal_entre INT,
    condicion_vehiculo VARCHAR(255),
    
    FOREIGN KEY (id_cliente) REFERENCES Persona(id_persona),
    FOREIGN KEY (id_vehiculo) REFERENCES Vehiculo(id_vehiculo),
    FOREIGN KEY (sucursal_recog) REFERENCES Sucursal(id_sucursal),
    FOREIGN KEY (sucursal_entre) REFERENCES Sucursal(id_sucursal)
);

-- Creación de la tabla Pago
CREATE TABLE Pago (
    id_pago INT PRIMARY KEY,
    id_reserva INT,
    id_contrato INT, -- Asumiendo que esta FK apunta a una tabla de Contrato no mostrada, o es una referencia a algo más. Si es a Reserva, se cambia. Aquí se mantiene como se ve en el diagrama.
    fecha_pago DATE NOT NULL,
    monto DOUBLE PRECISION NOT NULL,
    metodo VARCHAR(255),
    
    FOREIGN KEY (id_reserva) REFERENCES Reserva(id_reserva)
    -- Asumiendo que id_contrato no es FK a una tabla mostrada.
);

-- Creación de la tabla Notificacion
CREATE TABLE Notificacion (
    id_notificacion INT PRIMARY KEY,
    id_persona INT,
    mensaje VARCHAR(255) NOT NULL,
    fecha_envio DATETIME NOT NULL,
    leido BIT NOT NULL, -- BIT para booleano en SQL Server
    id_reserva INT,
    id_mantenimiento INT,
    id_pago INT,
    
    FOREIGN KEY (id_persona) REFERENCES Persona(id_persona),
    FOREIGN KEY (id_reserva) REFERENCES Reserva(id_reserva),
    FOREIGN KEY (id_mantenimiento) REFERENCES Mantenimiento_vehiculo(id_mantenimiento),
    FOREIGN KEY (id_pago) REFERENCES Pago(id_pago)
);