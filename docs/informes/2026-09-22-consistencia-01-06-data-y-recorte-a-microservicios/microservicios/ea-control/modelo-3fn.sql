-- =====================================================================
-- edu-air-control — modelo de datos núcleo, 3FN
-- Fuente: code-sena/ea-control-docs (06-data/domain/*.md), curado para
-- excluir IAM/seguridad y catálogos de pura parametrización.
-- Corte: 2026-09-22.
-- =====================================================================
--
-- EXCLUIDO A PROPÓSITO (13 tablas de ms-iam.md):
--   users, roles, permissions, role_permissions, user_roles, user_statuses,
--   session_statuses, user_sessions, audit_actions, audit_logs, error_logs,
--   security_configurations, password_policies
--   -> Estas seguirían siendo un microservicio propio (IAM). Nada del
--      dominio de negocio depende de su esquema interno, solo de un
--      identificador de usuario (uuid) que aquí se trata como referencia
--      lógica, no física.
--
-- EXCLUIDO A PROPÓSITO (catálogos de parametrización pura, sin lógica
-- de negocio propia — solo enumeran un valor fijo):
--   sensor_statuses, sensor_models, measurement_units, alert_status
--   -> Se conservan como columna (ver "referencia lógica" abajo) para no
--      perder el dato, pero sin tabla ni FK física: en una partición en
--      microservicios da igual si viven en un pequeño servicio de
--      catálogos o como tabla de referencia dentro de cada dominio.
--
-- CONVENCIÓN: una columna que en el modelo original apuntaba a una tabla
-- EXCLUIDA se deja como "-- referencia lógica" (uuid sin REFERENCES): es
-- justo lo que pasaría si esa tabla vive en otro servicio.
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — GESTIÓN DE ESPACIOS (Classroom / Space Management)
-- ---------------------------------------------------------------------

CREATE TABLE campuses (
    campus_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code         VARCHAR(30)  NOT NULL UNIQUE,
    name         VARCHAR(150) NOT NULL,
    city         VARCHAR(100),
    status       VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE',
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_at   TIMESTAMPTZ
);

CREATE TABLE environment_types (
    environment_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                 VARCHAR(30) NOT NULL UNIQUE,
    name                 VARCHAR(80) NOT NULL UNIQUE,
    description          VARCHAR(255),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at           TIMESTAMPTZ
    -- Se conserva como dominio propio (no como "parametrización básica"):
    -- el tipo de ambiente decide qué umbral de variable_threshold aplica,
    -- es una regla de negocio real, no una etiqueta decorativa.
);

CREATE TABLE educational_environments (
    educational_environment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id            UUID NOT NULL REFERENCES campuses(campus_id),
    code                 VARCHAR(30)  NOT NULL,
    name                 VARCHAR(120) NOT NULL,
    environment_type_id  UUID NOT NULL REFERENCES environment_types(environment_type_id),
    floor                INTEGER,
    area_m2              NUMERIC(8,2),
    occupancy_capacity   INTEGER,
    status               VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE',
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_at           TIMESTAMPTZ,
    UNIQUE (campus_id, code)
);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — GESTIÓN DE SENSORES (Sensor Management)
-- ---------------------------------------------------------------------

CREATE TABLE sensors (
    sensor_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    serial_number    VARCHAR(60) NOT NULL UNIQUE,
    sensor_model_id  UUID NOT NULL, -- referencia lógica: catálogo de modelos (excluido)
    sensor_status_id UUID NOT NULL, -- referencia lógica: catálogo de estados (excluido)
    last_seen_at     TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ
);

CREATE TABLE variables (
    variable_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(30) NOT NULL UNIQUE,     -- TEMP, HUM, CO2, NOISE
    name                VARCHAR(80) NOT NULL,
    measurement_unit_id UUID NOT NULL, -- referencia lógica: catálogo de unidades (excluido)
    description         VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sensor_installations (
    sensor_installation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id      UUID NOT NULL REFERENCES sensors(sensor_id),
    environment_id UUID NOT NULL, -- referencia lógica al dominio "Espacios"
    installed_at   TIMESTAMPTZ NOT NULL,
    removed_at     TIMESTAMPTZ
);
CREATE INDEX idx_sensor_installations_sensor  ON sensor_installations (sensor_id, installed_at);
CREATE INDEX idx_sensor_installations_env     ON sensor_installations (environment_id, installed_at);

CREATE TABLE sensor_variables (
    sensor_id   UUID NOT NULL REFERENCES sensors(sensor_id),
    variable_id UUID NOT NULL REFERENCES variables(variable_id),
    PRIMARY KEY (sensor_id, variable_id)
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — MONITOREO Y ANÁLISIS AMBIENTAL
-- (Environmental Monitoring & Analytics — incluye alertas: se generan
--  directamente del flujo de medición, están acopladas por diseño)
-- ---------------------------------------------------------------------

CREATE TABLE variable_thresholds (
    variable_threshold_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    variable_id         UUID NOT NULL REFERENCES variables(variable_id),
    environment_type_id UUID NOT NULL REFERENCES environment_types(environment_type_id),
    min_value  NUMERIC(12,4),
    max_value  NUMERIC(12,4),
    severity_id UUID NOT NULL, -- referencia lógica: catálogo de severidad (excluido)
    valid_from DATE NOT NULL,
    valid_to   DATE,
    CHECK (min_value IS NULL OR max_value IS NULL OR min_value < max_value),
    CHECK (valid_to IS NULL OR valid_from < valid_to)
);

CREATE TABLE environment_measurements (
    environment_measurement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_installation_id UUID NOT NULL REFERENCES sensor_installations(sensor_installation_id),
    variable_id    UUID NOT NULL REFERENCES variables(variable_id),
    measured_value NUMERIC(12,4) NOT NULL,
    measured_at    TIMESTAMPTZ NOT NULL,
    quality_flag_id UUID NOT NULL -- referencia lógica: catálogo de calidad (excluido)
);
CREATE INDEX idx_measurements_variable_time ON environment_measurements (variable_id, measured_at);

CREATE TABLE environmental_analyses (
    environmental_analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    educational_environment_id UUID NOT NULL, -- referencia lógica al dominio "Espacios"
    period_start TIMESTAMPTZ NOT NULL,
    period_end   TIMESTAMPTZ NOT NULL,
    analysis_status_id UUID NOT NULL, -- referencia lógica: catálogo de estado (excluido)
    requested_by UUID, -- referencia lógica al servicio IAM (excluido)
    computed_at  TIMESTAMPTZ,
    CHECK (period_start < period_end)
);

CREATE TABLE analysis_results (
    analysis_result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    environmental_analysis_id UUID NOT NULL REFERENCES environmental_analyses(environmental_analysis_id),
    variable_id      UUID NOT NULL REFERENCES variables(variable_id),
    min_value        NUMERIC(12,4) NOT NULL,
    max_value        NUMERIC(12,4) NOT NULL,
    avg_value        NUMERIC(12,4) NOT NULL,
    sample_count     INTEGER NOT NULL,
    exceedance_count INTEGER NOT NULL,
    UNIQUE (environmental_analysis_id, variable_id)
);

CREATE TABLE environment_alerts (
    environment_alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    educational_environment_id UUID NOT NULL, -- referencia lógica al dominio "Espacios"
    variable_id            UUID NOT NULL REFERENCES variables(variable_id),
    variable_threshold_id  UUID NOT NULL REFERENCES variable_thresholds(variable_threshold_id),
    triggering_measurement_id UUID NOT NULL REFERENCES environment_measurements(environment_measurement_id),
    raised_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID -- referencia lógica al servicio IAM (excluido)
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — EXPERIENCIA DE USUARIO (User Experience)
-- ---------------------------------------------------------------------

CREATE TABLE user_preferences (
    user_id     UUID PRIMARY KEY, -- referencia lógica al servicio IAM (excluido)
    theme       VARCHAR(20),
    language    VARCHAR(10),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE favorites (
    user_id        UUID NOT NULL, -- referencia lógica al servicio IAM (excluido)
    environment_id UUID NOT NULL, -- referencia lógica al dominio "Espacios"
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, environment_id)
);

CREATE TABLE classroom_ratings (
    classroom_rating_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL, -- referencia lógica al servicio IAM (excluido)
    environment_id UUID NOT NULL, -- referencia lógica al dominio "Espacios"
    score          SMALLINT NOT NULL CHECK (score BETWEEN 1 AND 5),
    comment        VARCHAR(500),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, environment_id)
);

CREATE TABLE searches (
    search_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL, -- referencia lógica al servicio IAM (excluido)
    query_text VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
