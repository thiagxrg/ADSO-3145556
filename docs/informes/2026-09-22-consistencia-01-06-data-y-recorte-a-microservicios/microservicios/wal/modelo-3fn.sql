-- =====================================================================
-- woman-alert — modelo de datos núcleo, 3FN
-- Fuente: code-sena/wal-docs (06-data/models.md), curado para excluir
-- IAM/seguridad, dispositivos y administración/moderación.
-- Corte: 2026-09-22.
--
-- Nota sobre el propio normalization-assessment.md del equipo: es
-- exhaustivo (12 tablas, todas marcadas 3NF) pero llama "denormalización
-- intencional" a tener una FK nulable (alert_id nulable en location_log y
-- en notification, para el caso sin alerta activa). Una FK nulable no es
-- una denormalización — es una relación opcional, sin dato duplicado ni
-- dependencia transitiva. El esquema de abajo respeta las columnas tal
-- cual las diseñó el equipo; la única corrección es en el comentario,
-- no en la estructura.
--
-- EXCLUIDO A PROPÓSITO (Identity and Accounts — 11 tablas, seguridad y
-- gestión de dispositivos del propio usuario):
--   role, user, account, user_profile, admin_profile, recovery_request,
--   device, device_permission, alert_activation_setting, device_session,
--   user_preference
--
-- EXCLUIDO A PROPÓSITO (Administration and Moderation — 4 tablas,
-- infraestructura de back-office, no negocio de atención de emergencias):
--   audit_log, user_report, moderation_action, system_configuration
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — GESTIÓN DE ALERTAS (Alert Management) — CORE — `alert-service`
-- ---------------------------------------------------------------------

CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    device_id       UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    alert_type varchar(20) NOT NULL DEFAULT 'main' CHECK (alert_type IN ('main','mini','reminder')),
    activation_method varchar(30) NOT NULL
        CHECK (activation_method IN ('panic_button','widget','sudden_movement','physical_button','discreet_confirmation','automatic')),
    status varchar(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active','resolved','cancelled','completed','failed')),
    message      varchar(500),
    started_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at     TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE alert_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id             UUID NOT NULL REFERENCES alerts(id),
    emergency_contact_id UUID NOT NULL, -- referencia lógica al dominio "Contactos y Notificaciones"
    channel     varchar(20) NOT NULL CHECK (channel IN ('sms','email','call','push')),
    destination varchar(150) NOT NULL,
    status      varchar(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','sent','delivered','failed','retrying')),
    sent_at      TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    attempts     INTEGER NOT NULL DEFAULT 0,
    error_message varchar(500),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (alert_id, emergency_contact_id, channel)
);

CREATE TABLE location_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    alert_id  UUID REFERENCES alerts(id), -- opcional: puede registrarse sin alerta activa
    latitude  DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    accuracy  DECIMAL(6,2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_location_logs_user_time ON location_logs (user_profile_id, recorded_at);

CREATE TABLE alert_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id UUID NOT NULL REFERENCES alerts(id),
    reminder_type   varchar(20) NOT NULL CHECK (reminder_type IN ('mini_alert','reminder')),
    sequence_number INTEGER NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    sent_at      TIMESTAMPTZ,
    status varchar(20) NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled','sent','failed','cancelled')),
    error_message varchar(500),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE frequent_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    name      varchar(100) NOT NULL,
    address   varchar(255),
    city      varchar(100),
    latitude  DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    notes     varchar(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ
);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — ZONAS Y RECURSOS DE AYUDA (Zones & Emergency Resources)
-- `zone-service`
-- ---------------------------------------------------------------------

CREATE TABLE zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by_admin_profile_id UUID, -- referencia lógica al servicio de Identidad (excluido)
    name        varchar(150) NOT NULL,
    zone_type   varchar(20) NOT NULL CHECK (zone_type IN ('safe','risk')),
    risk_level  varchar(20) NOT NULL DEFAULT 'medium' CHECK (risk_level IN ('low','medium','high','critical')),
    description varchar(500),
    address     varchar(255),
    city        varchar(100) NOT NULL,
    latitude    DECIMAL(9,6) NOT NULL,
    longitude   DECIMAL(9,6) NOT NULL,
    radius_meters DECIMAL(8,2) NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ
);

CREATE TABLE zone_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id UUID NOT NULL REFERENCES zones(id),
    user_profile_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    classification varchar(20) NOT NULL CHECK (classification IN ('safe','dangerous','regular')),
    comment  varchar(500),
    status   varchar(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    reviewed_by_admin_profile_id UUID, -- referencia lógica al servicio de Identidad (excluido)
    reviewed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (zone_id, user_profile_id) -- un usuario reporta una zona una sola vez
);

CREATE TABLE emergency_resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(150) NOT NULL,
    resource_type varchar(40) NOT NULL
        CHECK (resource_type IN ('emergency_line','hospital','health_center','police_station','police_post','shelter','support_organization')),
    telephone           varchar(30),
    secondary_telephone varchar(30),
    email    varchar(150),
    address  varchar(255),
    city     varchar(100) NOT NULL,
    latitude  DECIMAL(9,6),
    longitude DECIMAL(9,6),
    description varchar(500),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE TABLE resource_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    emergency_resource_id UUID NOT NULL REFERENCES emergency_resources(id),
    user_profile_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    alert_id  UUID, -- referencia lógica al dominio "Gestión de Alertas"; opcional
    device_id UUID, -- referencia lógica al servicio de Identidad (excluido)
    telephone_dialed varchar(30) NOT NULL,
    status varchar(20) NOT NULL CHECK (status IN ('started','answered','unanswered','failed','cancelled')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at   TIMESTAMPTZ,
    duration_seconds INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — EVIDENCIA (Evidence) — `evidence-service`
-- ---------------------------------------------------------------------

CREATE TABLE evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id UUID NOT NULL, -- referencia lógica al dominio "Gestión de Alertas"
    media_type varchar(20) NOT NULL CHECK (media_type IN ('photo','video','audio')),
    file_url   varchar(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — CONTACTOS Y NOTIFICACIONES (Contacts & Notifications)
-- `contact-notification-service`
-- ---------------------------------------------------------------------

CREATE TABLE emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    contact_name varchar(100) NOT NULL,
    telephone    varchar(20) NOT NULL,
    email        varchar(150),
    relationship varchar(30),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    alert_id UUID, -- referencia lógica al dominio "Gestión de Alertas"; opcional (no toda notificación viene de una alerta)
    type     varchar(30) NOT NULL CHECK (type IN ('reminder','warning','update','emergency')),
    priority varchar(20) NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal','high','critical')),
    title    varchar(100) NOT NULL,
    message  varchar(500) NOT NULL,
    is_read       BOOLEAN NOT NULL DEFAULT false,
    is_persistent BOOLEAN NOT NULL DEFAULT false, -- persiste mientras la alerta siga activa
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
