-- =====================================================================
-- rent-car — modelo de datos núcleo, 3FN
-- Fuente: code-sena/rtm-docs (06-data/models.md), curado para excluir
-- IAM/seguridad y auditoría transversal.
-- Corte: 2026-09-22.
--
-- Nota: este equipo ya pasó por una revisión externa de normalización
-- (06-data/normalization-assessment.md documenta el paso de un
-- instructor sobre Mer.dbml, con cambios adoptados y rechazados con
-- razón). Este archivo respeta cada una de esas decisiones —incluida la
-- de NO crear catálogo para status (son CHECK, no tablas, a propósito)—
-- y solo recorta lo que no es negocio de alquiler de vehículos.
-- =====================================================================
--
-- EXCLUIDO A PROPÓSITO (Identity & Access + auditoría transversal):
--   person, user, role, permission, role_permission, verification_code,
--   session, audit
--   -> `audit` en particular no pertenece a ningún bounded context en el
--      diseño original (todos escriben ahí directo) — se excluye por la
--      misma razón que la seguridad: es infraestructura, no negocio.
--
-- A DIFERENCIA DE OTROS EQUIPOS DE LA FICHA: aquí casi no hay
-- "parametrización básica" que excluir. `category`, `engine_type`,
-- `maintenance_type` e `insurance_type` se conservan tal cual porque el
-- propio equipo ya los justificó como catálogos de negocio editables por
-- un Admin, no simples etiquetas (ver normalization-assessment.md) — y
-- deliberadamente NO crearon catálogo para los campos `status`, que son
-- CHECK constraints porque los controla el código, no un Admin. Ese
-- criterio se respeta tal cual en este archivo.
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — FLOTA Y MANTENIMIENTO (Fleet & Maintenance) — `fleet-service`
-- ---------------------------------------------------------------------

CREATE TABLE branches (
    branch_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    city    VARCHAR(100) NOT NULL, -- texto libre a propósito, ver decisión original
    phone   VARCHAR(20)
);

CREATE TABLE branch_operating_hours (
    branch_operating_hour_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id   INT NOT NULL REFERENCES branches(branch_id),
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    opens_at    TIME NOT NULL,
    closes_at   TIME NOT NULL
);

CREATE TABLE brands (
    brand_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name     VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE categories (
    category_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Economy, SUV, Luxury...
    name        VARCHAR(50) NOT NULL,
    description VARCHAR(255)
    -- Catálogo de negocio editable por Admin — no es "parametrización básica".
);

CREATE TABLE engine_types (
    engine_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Gasoline, Diesel, Electric...
    name           VARCHAR(50) NOT NULL
);

CREATE TABLE vehicle_models (
    model_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    brand_id       INT NOT NULL REFERENCES brands(brand_id),
    name           VARCHAR(50) NOT NULL,
    category_id    INT NOT NULL REFERENCES categories(category_id),
    engine_type_id INT NOT NULL REFERENCES engine_types(engine_type_id)
    -- category/engine_type viven en el MODELO, no en cada unidad física
    -- (evita repetir el mismo dato en cada `vehicle` del mismo modelo).
);

CREATE TABLE vehicles (
    vehicle_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plate        VARCHAR(10) NOT NULL UNIQUE,
    model_id     INT NOT NULL REFERENCES vehicle_models(model_id),
    capacity     INT,
    year         INT,
    image_url    VARCHAR(255),
    status       VARCHAR(30) NOT NULL CHECK (status IN ('AVAILABLE','RENTED','MAINTENANCE')),
    mileage      DECIMAL(10,2) NOT NULL,
    daily_price  DECIMAL(10,2) NOT NULL,
    branch_id    INT NOT NULL REFERENCES branches(branch_id) -- sede actual del vehículo
);

CREATE TABLE maintenance_types (
    maintenance_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Oil change, Tires...
    name        VARCHAR(50) NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE vehicle_maintenances (
    maintenance_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_id           INT NOT NULL REFERENCES vehicles(vehicle_id),
    maintenance_type_id  INT NOT NULL REFERENCES maintenance_types(maintenance_type_id),
    start_date DATE NOT NULL,
    end_date   DATE, -- null mientras está en progreso
    cost       DECIMAL(10,2),
    status     VARCHAR(30) NOT NULL CHECK (status IN ('SCHEDULED','IN_PROGRESS','COMPLETED'))
);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — RESERVA Y ALQUILER (Booking & Rental Lifecycle) — `booking-service`
-- Fusiona Booking & Reservation + Rental Execution + Notification: son
-- el mismo hilo de negocio (reservar -> recoger -> devolver -> avisar).
-- ---------------------------------------------------------------------

CREATE TABLE insurance_types (
    insurance_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    coverage_details  TEXT,
    daily_cost        DECIMAL(10,2) NOT NULL
);

CREATE TABLE reservations (
    reservation_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id           UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    vehicle_id          INT NOT NULL REFERENCES vehicles(vehicle_id),
    insurance_type_id   INT REFERENCES insurance_types(insurance_type_id), -- opcional
    pickup_branch_id    INT NOT NULL REFERENCES branches(branch_id),
    return_branch_id    INT NOT NULL REFERENCES branches(branch_id), -- puede ser distinta a pickup
    reservation_date TIMESTAMP NOT NULL,
    start_date       TIMESTAMP NOT NULL,
    end_date         TIMESTAMP NOT NULL,
    vehicle_subtotal   DECIMAL(10,2) NOT NULL,
    insurance_subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount       DECIMAL(10,2) NOT NULL,
    status VARCHAR(30) NOT NULL
        CHECK (status IN ('PENDING_PAYMENT','PENDING_REVIEW','CONFIRMED','CANCELLED','COMPLETED'))
);

CREATE TABLE rentals (
    rental_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reservation_id INT NOT NULL UNIQUE REFERENCES reservations(reservation_id), -- 1:1
    gps_id         INT NOT NULL, -- referencia lógica al dominio "Telemetría y GPS"
    actual_start_date TIMESTAMP NOT NULL,
    actual_end_date   TIMESTAMP, -- null mientras IN_PROGRESS
    initial_mileage   DECIMAL(10,2) NOT NULL,
    final_mileage     DECIMAL(10,2), -- se fija al registrar la devolución
    status VARCHAR(30) NOT NULL CHECK (status IN ('IN_PROGRESS','COMPLETED'))
);

CREATE TABLE notifications (
    notification_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    person_id  UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    notification_type VARCHAR(50) NOT NULL, -- RESERVATION_CREATED, PAYMENT_APPROVED...
    message    TEXT NOT NULL,
    sent_date  TIMESTAMP NOT NULL,
    is_read    BOOLEAN NOT NULL DEFAULT false,
    -- Solo una de las cuatro se llena por fila (regla de aplicación, no de esquema):
    reservation_id INT REFERENCES reservations(reservation_id),
    invoice_id     INT, -- referencia lógica al dominio "Pagos y Facturación"
    payment_id     INT, -- referencia lógica al dominio "Pagos y Facturación"
    maintenance_id INT REFERENCES vehicle_maintenances(maintenance_id)
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — PAGOS Y FACTURACIÓN (Payment & Billing) — `payment-service`
-- ---------------------------------------------------------------------

CREATE TABLE bank_accounts (
    bank_account_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bank_name      VARCHAR(100) NOT NULL,
    account_holder VARCHAR(150) NOT NULL,
    qr_image_url   VARCHAR(255) NOT NULL,
    is_active      BOOLEAN NOT NULL
);

CREATE TABLE payments (
    payment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reservation_id   INT NOT NULL, -- referencia lógica al dominio "Reserva y Alquiler"
    bank_account_id  INT NOT NULL REFERENCES bank_accounts(bank_account_id),
    payment_date     TIMESTAMP NOT NULL,
    amount           DECIMAL(10,2) NOT NULL, -- debe igualar reservation.total_amount (regla de app)
    reference_number VARCHAR(100),
    receipt_file_url VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL CHECK (status IN ('PENDING_REVIEW','APPROVED','REJECTED')),
    reviewed_by      UUID, -- referencia lógica al servicio de Identidad (excluido)
    reviewed_at      TIMESTAMP,
    rejection_reason VARCHAR(255)
);

CREATE TABLE invoices (
    invoice_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reservation_id INT NOT NULL UNIQUE, -- referencia lógica, 1:1 con reserva
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    generated_date TIMESTAMP NOT NULL,
    invoice_pdf_url VARCHAR(255)
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — TELEMETRÍA Y GPS (Telemetry & GPS) — `telemetry-service`
-- ---------------------------------------------------------------------

CREATE TABLE gps_devices (
    gps_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    serial    VARCHAR(100) NOT NULL UNIQUE,
    model     VARCHAR(50),
    is_active BOOLEAN NOT NULL
);

CREATE TABLE locations (
    location_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gps_id    INT NOT NULL REFERENCES gps_devices(gps_id),
    latitude  DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    "timestamp" TIMESTAMP NOT NULL
);
CREATE INDEX idx_locations_gps_time ON locations (gps_id, "timestamp");
