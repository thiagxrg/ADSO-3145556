-- =====================================================================
-- save-your-water — modelo de datos núcleo, 3FN
-- Fuente: code-sena/sy-water-docs (06-data/models.md), curado para
-- excluir IAM/seguridad y catálogos de pura parametrización.
-- Corte: 2026-09-22. Traducido de SQL Server a sintaxis PostgreSQL para
-- que el paquete sea uniforme entre los 10 equipos de la ficha.
--
-- Nota: el propio equipo YA agrupó sus 11 bounded contexts en solo 6
-- servicios físicos (columna "Owner:" de cada schema en su models.md):
-- auth-service, place-service, device-service, consumption-service
-- (monitoring+goals+billing), valve-service, notification-service
-- (alerts+notifications+content). Los 4 dominios de abajo son
-- exactamente esa agrupación, quitando auth-service (seguridad) y
-- fusionando los dos servicios más pequeños (place+device).
--
-- EXCLUIDO A PROPÓSITO (schema `security` completo — 7 tablas):
--   security.users, security.user_credentials, security.email_verifications,
--   security.password_resets, security.refresh_tokens,
--   security.login_attempts, security.activity_log
--
-- EXCLUIDO A PROPÓSITO (parametrización pura):
--   billing.tariff_catalog   -- tarifas públicas de referencia por país/región
--   alerts.alert_type_config -- catálogo de tipos de alerta con seed data fija
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — LUGARES Y DISPOSITIVOS (Place & Device Management)
-- `place-service` + `device-service` fusionados (BC-02 + BC-03)
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS places;
CREATE TABLE places.places (
    id               BIGSERIAL PRIMARY KEY,
    uuid             UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    owner_id         UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    name             VARCHAR(200) NOT NULL,
    place_type       VARCHAR(15)  NOT NULL CHECK (place_type IN ('RESIDENTIAL','COMMERCIAL')),
    address          VARCHAR(500) NOT NULL,
    city             VARCHAR(100) NOT NULL,
    country_code     VARCHAR(2)   NOT NULL CHECK (country_code IN ('CO','EC','US')),
    currency         VARCHAR(3)   NOT NULL DEFAULT 'COP',
    measurement_unit VARCHAR(15)  NOT NULL DEFAULT 'LITERS'
                     CHECK (measurement_unit IN ('LITERS','CUBIC_METERS','GALLONS')),
    is_default       BOOLEAN NOT NULL DEFAULT false,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at       TIMESTAMPTZ
);

CREATE TABLE places.place_members (
    id         BIGSERIAL PRIMARY KEY,
    place_id   BIGINT NOT NULL REFERENCES places.places(id),
    user_id    UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    role       VARCHAR(10) NOT NULL CHECK (role IN ('OWNER','GUEST')), -- 'GUEST' = "Miembro" en el glosario
    joined_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at TIMESTAMPTZ,
    UNIQUE (place_id, user_id)
);

CREATE TABLE places.invitations (
    id           BIGSERIAL PRIMARY KEY,
    place_id     BIGINT NOT NULL REFERENCES places.places(id),
    invited_by   UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    email        VARCHAR(320) NOT NULL,
    status       VARCHAR(10) NOT NULL DEFAULT 'PENDING'
                 CHECK (status IN ('PENDING','ACCEPTED','EXPIRED','REJECTED')),
    token_hash   VARCHAR(256) NOT NULL UNIQUE,
    expires_at   TIMESTAMPTZ NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at TIMESTAMPTZ
);
CREATE INDEX idx_invitations_place_email ON places.invitations (place_id, email);

CREATE SCHEMA IF NOT EXISTS devices;
CREATE TABLE devices.devices (
    id                       BIGSERIAL PRIMARY KEY,
    uuid                     UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    serial_number            VARCHAR(100) NOT NULL UNIQUE,
    place_id                 BIGINT REFERENCES places.places(id), -- NULL = disponible, sin asignar
    auth_token_hash          VARCHAR(256) NOT NULL,
    auth_token_last_used_at  TIMESTAMPTZ,
    auth_token_revoked_at    TIMESTAMPTZ,
    status                   VARCHAR(20) NOT NULL DEFAULT 'NEVER_REPORTED'
                             CHECK (status IN ('CONNECTED','DISCONNECTED','NEVER_REPORTED')),
    last_report_at           TIMESTAMPTZ,
    inactivity_threshold_min INT NOT NULL DEFAULT 15,
    linked_at                TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_devices_place ON devices.devices (place_id) WHERE place_id IS NOT NULL;

CREATE TABLE devices.device_link_history (
    id          BIGSERIAL PRIMARY KEY,
    device_id   BIGINT NOT NULL REFERENCES devices.devices(id),
    place_id    BIGINT NOT NULL REFERENCES places.places(id),
    linked_by   UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    linked_at   TIMESTAMPTZ NOT NULL,
    unlinked_at TIMESTAMPTZ,
    unlinked_by UUID
);
CREATE INDEX idx_linkhistory_device_time ON devices.device_link_history (device_id, linked_at);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — CONSUMO Y FACTURACIÓN (Consumption Monitoring & Billing)
-- `consumption-service` (BC-04 + BC-05 + BC-06, ya fusionados por el equipo)
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS monitoring;
CREATE TABLE monitoring.readings (
    id                BIGSERIAL PRIMARY KEY,
    device_id         BIGINT NOT NULL, -- referencia lógica al dominio "Lugares y Dispositivos"
    place_id          BIGINT NOT NULL, -- referencia lógica (denormalización documentada D1: evita join en cada lectura)
    flow_rate_lph     DECIMAL(18,3) NOT NULL CHECK (flow_rate_lph >= 0),
    cumulative_liters DECIMAL(18,3) NOT NULL CHECK (cumulative_liters >= 0),
    recorded_at       TIMESTAMPTZ NOT NULL,
    received_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (device_id, recorded_at)
);
CREATE INDEX idx_readings_place_time ON monitoring.readings (place_id, recorded_at);
-- Tabla de mayor volumen de escritura: particionar por recorded_at al superar ~50M filas.

CREATE TABLE monitoring.consumption_hourly (
    id            BIGSERIAL PRIMARY KEY,
    place_id      BIGINT NOT NULL REFERENCES places.places(id),
    hour_start    TIMESTAMPTZ NOT NULL,
    total_liters  DECIMAL(18,3) NOT NULL CHECK (total_liters >= 0),
    reading_count INT NOT NULL CHECK (reading_count >= 0),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (place_id, hour_start)
);

CREATE TABLE monitoring.consumption_daily (
    id            BIGSERIAL PRIMARY KEY,
    place_id      BIGINT NOT NULL REFERENCES places.places(id),
    reading_date  DATE NOT NULL,
    total_liters  DECIMAL(18,3) NOT NULL CHECK (total_liters >= 0),
    avg_hourly    DECIMAL(18,3),
    peak_hour     SMALLINT CHECK (peak_hour BETWEEN 0 AND 23),
    reading_count INT NOT NULL CHECK (reading_count >= 0),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (place_id, reading_date)
);

CREATE TABLE monitoring.consumption_monthly (
    id             BIGSERIAL PRIMARY KEY,
    place_id       BIGINT NOT NULL REFERENCES places.places(id),
    bucket_month   DATE NOT NULL,
    total_liters   DECIMAL(18,3) NOT NULL CHECK (total_liters >= 0),
    avg_daily      DECIMAL(18,3),
    peak_day       DATE,
    reading_count  INT NOT NULL CHECK (reading_count >= 0),
    days_with_data INT NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (place_id, bucket_month)
);

CREATE SCHEMA IF NOT EXISTS goals;
CREATE TABLE goals.consumption_goals (
    id            BIGSERIAL PRIMARY KEY,
    place_id      BIGINT NOT NULL REFERENCES places.places(id),
    bucket_month  DATE NOT NULL,
    target_liters DECIMAL(18,3) NOT NULL CHECK (target_liters > 0),
    source        VARCHAR(15) NOT NULL CHECK (source IN ('MANUAL','SUGGESTED','CARRIED_OVER')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (place_id, bucket_month)
);

CREATE TABLE goals.goal_suggestions (
    id               BIGSERIAL PRIMARY KEY,
    place_id         BIGINT NOT NULL REFERENCES places.places(id),
    bucket_month     DATE NOT NULL,
    suggested_liters DECIMAL(18,3) NOT NULL CHECK (suggested_liters > 0),
    based_on_months  INT NOT NULL CHECK (based_on_months >= 1),
    accepted         BOOLEAN,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (place_id, bucket_month)
);

CREATE SCHEMA IF NOT EXISTS billing;
CREATE TABLE billing.water_bills (
    id                 BIGSERIAL PRIMARY KEY,
    place_id           BIGINT NOT NULL REFERENCES places.places(id),
    billed_consumption DECIMAL(18,3) NOT NULL CHECK (billed_consumption >= 0),
    billed_unit        VARCHAR(20) NOT NULL,
    total_amount       DECIMAL(18,2) NOT NULL CHECK (total_amount >= 0),
    currency           VARCHAR(3) NOT NULL,
    period_start       DATE NOT NULL,
    period_end         DATE NOT NULL,
    due_date           DATE,
    paid               BOOLEAN NOT NULL DEFAULT false,
    paid_at            TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (period_start < period_end)
);
CREATE INDEX idx_bills_place_period ON billing.water_bills (place_id, period_start);
CREATE INDEX idx_bills_place_due    ON billing.water_bills (place_id, due_date);

CREATE TABLE billing.tariffs (
    id                   BIGSERIAL PRIMARY KEY,
    place_id             BIGINT NOT NULL REFERENCES places.places(id),
    price_per_unit       DECIMAL(18,2) NOT NULL CHECK (price_per_unit > 0),
    unit                 VARCHAR(20) NOT NULL,
    fixed_monthly_charge DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (fixed_monthly_charge >= 0),
    currency             VARCHAR(3) NOT NULL,
    source               VARCHAR(10) NOT NULL DEFAULT 'MANUAL' CHECK (source IN ('MANUAL','CATALOG')),
    catalog_tariff_id    BIGINT, -- referencia lógica: catálogo de tarifas públicas (excluido)
    effective_from       DATE NOT NULL,
    effective_to         DATE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (effective_to IS NULL OR effective_from < effective_to)
);
CREATE INDEX idx_tariffs_place_from ON billing.tariffs (place_id, effective_from);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — CONTROL DE VÁLVULA (Valve Control) — `valve-service`
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS valve;
CREATE TABLE valve.valve_states (
    id                BIGSERIAL PRIMARY KEY,
    device_id         BIGINT NOT NULL UNIQUE, -- referencia lógica al dominio "Lugares y Dispositivos"
    place_id          BIGINT NOT NULL UNIQUE REFERENCES places.places(id),
    state             VARCHAR(10) NOT NULL DEFAULT 'UNKNOWN' CHECK (state IN ('OPEN','CLOSED','UNKNOWN')),
    last_confirmed_at TIMESTAMPTZ,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE valve.valve_commands (
    id                BIGSERIAL PRIMARY KEY,
    device_id         BIGINT NOT NULL, -- referencia lógica al dominio "Lugares y Dispositivos"
    place_id          BIGINT NOT NULL REFERENCES places.places(id),
    commanded_by      UUID, -- referencia lógica al servicio de Identidad; NULL = automático
    command           VARCHAR(10) NOT NULL CHECK (command IN ('OPEN','CLOSE')),
    origin            VARCHAR(15) NOT NULL CHECK (origin IN ('MANUAL','AUTO_LEAK','AUTO_GOAL')),
    status            VARCHAR(25) NOT NULL DEFAULT 'PENDING_CONFIRMATION'
                      CHECK (status IN ('PENDING_CONFIRMATION','CONFIRMED','SENT','ACK_SUCCESS','ACK_TIMEOUT','FAILED')),
    confirmation_code VARCHAR(10),
    confirmed_at      TIMESTAMPTZ,
    sent_at           TIMESTAMPTZ,
    device_ack_at     TIMESTAMPTZ,
    timeout_at        TIMESTAMPTZ,
    failure_reason    VARCHAR(500),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_valve_commands_place_time ON valve.valve_commands (place_id, created_at);
-- Ciclo de vida: PENDING_CONFIRMATION -> CONFIRMED -> SENT -> ACK_SUCCESS | ACK_TIMEOUT.

CREATE TABLE valve.valve_rules (
    id                       BIGSERIAL PRIMARY KEY,
    place_id                 BIGINT NOT NULL REFERENCES places.places(id),
    rule_type                VARCHAR(20) NOT NULL CHECK (rule_type IN ('LEAK_DETECTION','GOAL_EXCEEDED')),
    enabled                  BOOLEAN NOT NULL DEFAULT false,
    requires_confirmation    BOOLEAN NOT NULL DEFAULT true,
    confirmation_timeout_min INT NOT NULL DEFAULT 10 CHECK (confirmation_timeout_min > 0),
    created_by               UUID NOT NULL, -- referencia lógica al servicio de Identidad
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (place_id, rule_type)
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — ALERTAS Y NOTIFICACIONES (Alerts & Notifications)
-- `notification-service` (BC-08 + BC-09 + BC-11, ya fusionados por el equipo)
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS alerts;
CREATE TABLE alerts.alert_events (
    id           BIGSERIAL PRIMARY KEY,
    place_id     BIGINT NOT NULL REFERENCES places.places(id),
    alert_type   VARCHAR(30) NOT NULL, -- referencia lógica: catálogo de tipos excluido
    severity     VARCHAR(15) NOT NULL, -- foto del catálogo al momento de crearse (denormalización documentada D3)
    title        VARCHAR(200) NOT NULL,
    message      VARCHAR(2000) NOT NULL,
    metadata     JSONB,
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at      TIMESTAMPTZ,
    deleted_at   TIMESTAMPTZ
);
CREATE INDEX idx_alerts_place_time  ON alerts.alert_events (place_id, triggered_at);
CREATE INDEX idx_alerts_dedup       ON alerts.alert_events (place_id, alert_type, triggered_at);

CREATE TABLE alerts.notification_preferences (
    id             BIGSERIAL PRIMARY KEY,
    user_id        UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    alert_severity VARCHAR(15) NOT NULL CHECK (alert_severity IN ('CRITICAL','IMPORTANT','INFORMATIVE')),
    channel_app    BOOLEAN NOT NULL DEFAULT true,
    channel_push   BOOLEAN NOT NULL DEFAULT true,
    channel_email  BOOLEAN NOT NULL DEFAULT false,
    channel_sms    BOOLEAN NOT NULL DEFAULT false,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, alert_severity),
    CHECK (alert_severity <> 'CRITICAL' OR channel_app = true)
);

CREATE SCHEMA IF NOT EXISTS notifications;
CREATE TABLE notifications.notification_log (
    id             BIGSERIAL PRIMARY KEY,
    alert_event_id BIGINT NOT NULL REFERENCES alerts.alert_events(id),
    user_id        UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    channel        VARCHAR(10) NOT NULL CHECK (channel IN ('APP','PUSH','EMAIL','SMS','WHATSAPP')),
    status         VARCHAR(15) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SENT','DELIVERED','FAILED')),
    provider_ref   VARCHAR(200),
    sent_at        TIMESTAMPTZ,
    delivered_at   TIMESTAMPTZ,
    failed_at      TIMESTAMPTZ,
    error_message  VARCHAR(1000),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (alert_event_id, user_id, channel)
);
CREATE INDEX idx_notiflog_user_time ON notifications.notification_log (user_id, created_at);

CREATE TABLE notifications.push_subscriptions (
    id           BIGSERIAL PRIMARY KEY,
    user_id      UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    device_token VARCHAR(500) NOT NULL,
    platform     VARCHAR(10) NOT NULL,
    active       BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, device_token)
);

CREATE SCHEMA IF NOT EXISTS content;
CREATE TABLE content.savings_tips (
    id         BIGSERIAL PRIMARY KEY,
    category   VARCHAR(15) NOT NULL CHECK (category IN ('RESIDENTIAL','COMMERCIAL','GENERAL')),
    title      VARCHAR(200) NOT NULL,
    body       VARCHAR(2000) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    active     BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE content.tip_favorites (
    user_id  UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    tip_id   BIGINT NOT NULL REFERENCES content.savings_tips(id),
    saved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, tip_id)
);
