-- =====================================================================
-- energy-monitor — modelo de datos núcleo, 3FN
-- Fuente: code-sena/en-monitor-docs (06-data/models.md), curado para
-- excluir IAM/seguridad y catálogos de pura parametrización.
-- Corte: 2026-09-22.
--
-- Nota: el equipo ya verificó y documentó 3FN sin excepciones en su
-- propio 06-data/normalization-assessment.md ("every table is in 3NF...
-- stated plainly rather than manufactured content to fill the section").
-- Este archivo no corrige nada — recorta el núcleo de negocio del resto.
-- =====================================================================
--
-- EXCLUIDO A PROPÓSITO (13 tablas de IAM/seguridad/auditoría):
--   person, user, user_configuration, password_reset_token, user_session,
--   security_configuration, password_policy, login_error_log, system_role,
--   user_system_role, permission, system_role_permission, audit_log
--
-- EXCLUIDO A PROPÓSITO (parametrización pura — catálogo id+nombre, sin
-- lógica de negocio propia):
--   home_type, appliance_type
--
-- CONSERVADO aunque parezca catálogo: consumption_level. Trae
-- min_limit/max_limit — es la regla de negocio que decide cuándo se
-- dispara una alerta, no una simple etiqueta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — GESTIÓN DE VIVIENDAS (Home Management) — `home-service`
-- ---------------------------------------------------------------------

CREATE TABLE homes (
    id_home       VARCHAR(10) PRIMARY KEY,
    name          VARCHAR(50) NOT NULL,
    home_type_id  VARCHAR(10) NOT NULL, -- referencia lógica: catálogo excluido
    address       VARCHAR(200) NOT NULL,
    access_code   VARCHAR(8)  NOT NULL UNIQUE,
    description   VARCHAR(200),
    creation_date TIMESTAMP   NOT NULL,
    created_at    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMP
);

CREATE TABLE home_thresholds (
    id_threshold        VARCHAR(10) PRIMARY KEY,
    home_id             VARCHAR(10) NOT NULL UNIQUE REFERENCES homes(id_home),
    daily_limit         DOUBLE PRECISION NOT NULL,
    monthly_limit       DOUBLE PRECISION NOT NULL,
    use_system_default  BOOLEAN NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMP
);

CREATE TABLE user_homes (
    user_id    VARCHAR(10) NOT NULL, -- referencia lógica al servicio IAM (excluido)
    home_id    VARCHAR(10) NOT NULL REFERENCES homes(id_home),
    role       VARCHAR(10) NOT NULL CHECK (role IN ('OWNER','MEMBER')),
    favorite   BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    PRIMARY KEY (user_id, home_id)
);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — GESTIÓN DE DISPOSITIVOS (Device Management) — `device-service`
-- ---------------------------------------------------------------------

CREATE TABLE devices (
    id_device          VARCHAR(10) PRIMARY KEY,
    name               VARCHAR(50) NOT NULL,
    appliance_type_id  VARCHAR(10) NOT NULL, -- referencia lógica: catálogo excluido
    location           VARCHAR(50),
    description        VARCHAR(200),
    installation_date  TIMESTAMP NOT NULL,
    device_code        VARCHAR(6)  NOT NULL UNIQUE,
    api_key            VARCHAR(100) NOT NULL,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at         TIMESTAMP
);

CREATE TABLE device_status_logs (
    id_device_status VARCHAR(10) PRIMARY KEY,
    device_id        VARCHAR(10) NOT NULL REFERENCES devices(id_device),
    status           VARCHAR(10) NOT NULL CHECK (status IN ('ONLINE','OFFLINE')),
    signal_strength  INTEGER,
    last_seen        TIMESTAMP NOT NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at       TIMESTAMP
);

CREATE TABLE device_homes (
    device_id  VARCHAR(10) NOT NULL REFERENCES devices(id_device),
    home_id    VARCHAR(10) NOT NULL, -- referencia lógica al dominio "Viviendas"
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    PRIMARY KEY (device_id, home_id)
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — MONITOREO Y ALERTAS (Monitoring & Alerts) — `monitoring-service`
-- ---------------------------------------------------------------------

CREATE TABLE measurements (
    id_measurement VARCHAR(10) PRIMARY KEY,
    device_id      VARCHAR(10) NOT NULL, -- referencia lógica al dominio "Dispositivos"
    date_time      TIMESTAMP NOT NULL,
    voltage        DOUBLE PRECISION NOT NULL,
    current        DOUBLE PRECISION NOT NULL,
    active_power   DOUBLE PRECISION NOT NULL,
    stored_energy  DOUBLE PRECISION NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at     TIMESTAMP
);
CREATE INDEX idx_measurements_device_time ON measurements (device_id, date_time);

CREATE TABLE consumption_levels (
    id_consumption_level VARCHAR(10) PRIMARY KEY,
    name        VARCHAR(10) NOT NULL UNIQUE CHECK (name IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    description VARCHAR(200) NOT NULL,
    min_limit   DOUBLE PRECISION NOT NULL,
    max_limit   DOUBLE PRECISION NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMP
    -- Se conserva como dominio propio: define el umbral que dispara una
    -- alerta, es regla de negocio, no una etiqueta decorativa.
);

CREATE TABLE alerts (
    id_alert             VARCHAR(10) PRIMARY KEY,
    home_id              VARCHAR(10) NOT NULL, -- referencia lógica al dominio "Viviendas"
    device_id            VARCHAR(10),          -- referencia lógica al dominio "Dispositivos"
    type                 VARCHAR(15) NOT NULL CHECK (type IN ('THRESHOLD','CONNECTIVITY')),
    message_key          VARCHAR(100) NOT NULL,
    date_time            TIMESTAMP NOT NULL,
    alert_status         VARCHAR(10) NOT NULL CHECK (alert_status IN ('PENDING','RESOLVED')),
    consumption_level_id VARCHAR(10) REFERENCES consumption_levels(id_consumption_level),
    measurement_id       VARCHAR(10), -- referencia lógica a measurements (misma tabla, mismo dominio; sin FK física porque es opcional/histórica)
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at           TIMESTAMP
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — RECOMENDACIONES (Recommendations) — `recommendation-service`
-- ---------------------------------------------------------------------

CREATE TABLE recommendations (
    id_recommendation VARCHAR(10) PRIMARY KEY,
    home_id     VARCHAR(10) NOT NULL, -- referencia lógica al dominio "Viviendas"
    device_id   VARCHAR(10),          -- referencia lógica al dominio "Dispositivos"
    message_key VARCHAR(100) NOT NULL,
    date_time   TIMESTAMP NOT NULL,
    status      VARCHAR(10) NOT NULL CHECK (status IN ('READ','UNREAD')),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMP
);
