-- =====================================================================
-- school-guardian — modelo de datos PROPUESTO, 3FN
-- ADVERTENCIA: sg-docs no tiene contenido real (un solo commit, el
-- scaffold del instructor — ver README.md de esta carpeta). Este
-- archivo NO refleja ninguna decisión del equipo: es una línea base
-- construida solo desde la descripción del repo ("school route
-- management and monitoring"), para completar el ejercicio de la ficha.
-- Corte: 2026-09-22.
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — RUTAS Y PARADAS (propuesto) — `route-service`
-- ---------------------------------------------------------------------

CREATE TABLE routes (
    route_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code       VARCHAR(30) NOT NULL UNIQUE,
    name       VARCHAR(120) NOT NULL,
    shift      VARCHAR(10) NOT NULL CHECK (shift IN ('AM','PM')),
    active     BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE stops (
    stop_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(150) NOT NULL,
    latitude   DECIMAL(10,8) NOT NULL,
    longitude  DECIMAL(11,8) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE route_stops (
    route_id       UUID NOT NULL REFERENCES routes(route_id),
    stop_id        UUID NOT NULL REFERENCES stops(stop_id),
    sequence_order SMALLINT NOT NULL,
    estimated_time TIME NOT NULL,
    PRIMARY KEY (route_id, stop_id)
);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — ESTUDIANTES Y ACUDIENTES (propuesto) — `student-service`
-- ---------------------------------------------------------------------

CREATE TABLE guardians (
    guardian_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    full_name   VARCHAR(150) NOT NULL,
    phone       VARCHAR(20) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE students (
    student_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name    VARCHAR(150) NOT NULL,
    grade        VARCHAR(20),
    guardian_id  UUID NOT NULL REFERENCES guardians(guardian_id),
    stop_id      UUID NOT NULL, -- referencia lógica al dominio "Rutas y Paradas"
    active       BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE student_route_assignments (
    student_id UUID NOT NULL REFERENCES students(student_id),
    route_id   UUID NOT NULL, -- referencia lógica al dominio "Rutas y Paradas"
    starts_on  DATE NOT NULL,
    ends_on    DATE,
    PRIMARY KEY (student_id, route_id, starts_on)
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — SEGUIMIENTO EN TIEMPO REAL (propuesto) — `tracking-service`
-- ---------------------------------------------------------------------

CREATE TABLE buses (
    bus_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plate      VARCHAR(10) NOT NULL UNIQUE,
    capacity   SMALLINT NOT NULL,
    driver_id  UUID, -- referencia lógica al servicio de Identidad (excluido)
    active     BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE trip_instances (
    trip_instance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id   UUID NOT NULL, -- referencia lógica al dominio "Rutas y Paradas"
    bus_id     UUID NOT NULL REFERENCES buses(bus_id),
    trip_date  DATE NOT NULL,
    started_at TIMESTAMPTZ,
    ended_at   TIMESTAMPTZ,
    status     VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED'
               CHECK (status IN ('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED')),
    UNIQUE (route_id, bus_id, trip_date)
);

CREATE TABLE gps_positions (
    gps_position_id  BIGSERIAL PRIMARY KEY,
    trip_instance_id UUID NOT NULL REFERENCES trip_instances(trip_instance_id),
    latitude   DECIMAL(10,8) NOT NULL,
    longitude  DECIMAL(11,8) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_gps_positions_trip_time ON gps_positions (trip_instance_id, recorded_at);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — NOTIFICACIONES A ACUDIENTES (propuesto) — `notification-service`
-- ---------------------------------------------------------------------

CREATE TABLE notification_preferences (
    guardian_id UUID PRIMARY KEY, -- referencia lógica al dominio "Estudiantes y Acudientes"
    channel_app   BOOLEAN NOT NULL DEFAULT true,
    channel_sms   BOOLEAN NOT NULL DEFAULT false,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
    notification_id  BIGSERIAL PRIMARY KEY,
    guardian_id       UUID NOT NULL, -- referencia lógica al dominio "Estudiantes y Acudientes"
    trip_instance_id  UUID, -- referencia lógica al dominio "Seguimiento en Tiempo Real"
    notification_type VARCHAR(30) NOT NULL, -- BUS_APPROACHING, BUS_ARRIVED, TRIP_CANCELLED...
    message   VARCHAR(500) NOT NULL,
    sent_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_read   BOOLEAN NOT NULL DEFAULT false
);
