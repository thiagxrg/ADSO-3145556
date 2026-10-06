-- =====================================================================
-- faceattend-edu — modelo de datos núcleo, 3FN
-- Fuente: code-sena/fae-docs (06-data/domains/*.md), curado para excluir
-- IAM/seguridad y catálogos de pura parametrización.
-- Corte: 2026-09-22.
-- =====================================================================
--
-- EXCLUIDO A PROPÓSITO (Identity + Authorization = 9 tablas de seguridad):
--   city, person, app_user, user_session, password_policy,
--   role, permission, role_permission, user_role
--
-- EXCLUIDO A PROPÓSITO (parametrización pura — pares nombre/valor sin
-- lógica propia): academic_configuration, security_configuration
--
-- EXCLUIDO A PROPÓSITO (catálogo id+nombre sin comportamiento propio):
--   alert_type
--
-- REUBICADO: `biometric_update_case` vivía en la carpeta "Configuration"
-- junto a pares nombre/valor genéricos, pero es un caso de negocio real
-- (el flujo de re-enrolar una huella o un rostro, con revisión y
-- aprobación) — aquí se mueve al dominio Biométrico, que es donde
-- pertenece funcionalmente.
--
-- El dominio Biométrico persiste en MongoDB en el diseño original
-- (colecciones `facial_embeddings` / `fingerprint_embeddings`, vectores
-- de tamaño variable) — se documenta como esquema de colección, no como
-- CREATE TABLE, respetando esa decisión de motor.
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — GESTIÓN ACADÉMICA (Academic Management) — `academic-service`
-- ---------------------------------------------------------------------

CREATE TABLE schools (
    school_id   SERIAL PRIMARY KEY,
    code        VARCHAR NOT NULL UNIQUE,
    name        VARCHAR NOT NULL,
    city_id     INT NOT NULL, -- referencia lógica: catálogo geográfico (excluido)
    address     VARCHAR,
    phone       VARCHAR,
    email       VARCHAR,
    status      BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE TABLE programs (
    program_id SERIAL PRIMARY KEY,
    school_id  INT NOT NULL REFERENCES schools(school_id),
    code       VARCHAR NOT NULL,
    name       VARCHAR NOT NULL,
    status     BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    UNIQUE (school_id, code)
);

CREATE TABLE academic_periods (
    academic_period_id SERIAL PRIMARY KEY,
    school_id  INT NOT NULL REFERENCES schools(school_id),
    name       VARCHAR NOT NULL,
    starts_on  DATE NOT NULL,
    ends_on    DATE NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CHECK (starts_on < ends_on)
);

CREATE TABLE cohorts (
    cohort_id          BIGSERIAL PRIMARY KEY,
    program_id         INT NOT NULL REFERENCES programs(program_id),
    academic_period_id INT NOT NULL REFERENCES academic_periods(academic_period_id),
    code               VARCHAR NOT NULL UNIQUE,
    status             BOOLEAN NOT NULL DEFAULT true,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at         TIMESTAMPTZ
);

CREATE TABLE courses (
    course_id    SERIAL PRIMARY KEY,
    program_id   INT NOT NULL REFERENCES programs(program_id),
    code         VARCHAR NOT NULL,
    name         VARCHAR NOT NULL,
    credit_hours SMALLINT NOT NULL,
    status       BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ,
    UNIQUE (program_id, code)
);

CREATE TABLE academic_actor_types (
    actor_type_id SMALLINT PRIMARY KEY, -- STUDENT / INSTRUCTOR / STAFF...
    code       VARCHAR NOT NULL UNIQUE,
    name       VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
    -- Se conserva como dominio propio (no como "parametrización básica"):
    -- decide qué puede hacer un academic_actor (ej. solo un INSTRUCTOR
    -- puede quedar como instructor_actor_id en schedule_block).
);

CREATE TABLE academic_actors (
    academic_actor_id BIGSERIAL PRIMARY KEY,
    person_id     UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    actor_type_id SMALLINT NOT NULL REFERENCES academic_actor_types(actor_type_id),
    school_id     INT NOT NULL REFERENCES schools(school_id),
    actor_code    VARCHAR NOT NULL,
    started_on    DATE NOT NULL,
    ended_on      DATE,
    status        BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ,
    UNIQUE (school_id, actor_code)
);

CREATE TABLE enrollments (
    enrollment_id     BIGSERIAL PRIMARY KEY,
    academic_actor_id BIGINT NOT NULL REFERENCES academic_actors(academic_actor_id),
    cohort_id         BIGINT NOT NULL REFERENCES cohorts(cohort_id),
    enrolled_on       DATE NOT NULL,
    enrollment_status VARCHAR NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at        TIMESTAMPTZ,
    UNIQUE (academic_actor_id, cohort_id)
);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — PROGRAMACIÓN DE CLASES (Scheduling) — `scheduling-service`
-- ---------------------------------------------------------------------

CREATE TABLE environments (
    environment_id SERIAL PRIMARY KEY,
    school_id  INT NOT NULL, -- referencia lógica al dominio "Gestión Académica"
    code       VARCHAR NOT NULL,
    name       VARCHAR NOT NULL,
    capacity   SMALLINT NOT NULL,
    status     BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE schedule_blocks (
    schedule_block_id   BIGSERIAL PRIMARY KEY,
    cohort_id           BIGINT NOT NULL, -- referencia lógica al dominio "Gestión Académica"
    course_id           INT NOT NULL,    -- referencia lógica al dominio "Gestión Académica"
    environment_id       INT NOT NULL REFERENCES environments(environment_id),
    instructor_actor_id  BIGINT NOT NULL, -- referencia lógica: academic_actor (INSTRUCTOR)
    day_of_week          SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    starts_at            TIME NOT NULL,
    ends_at              TIME NOT NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,
    CHECK (starts_at < ends_at)
);

CREATE TABLE class_sessions (
    class_session_id  BIGSERIAL PRIMARY KEY,
    schedule_block_id INT NOT NULL REFERENCES schedule_blocks(schedule_block_id),
    session_date      DATE NOT NULL,
    opened_by         BIGINT, -- referencia lógica: academic_actor
    opened_at         TIMESTAMPTZ,
    closed_by         BIGINT, -- referencia lógica: academic_actor
    closed_at         TIMESTAMPTZ,
    session_status    VARCHAR NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at        TIMESTAMPTZ,
    UNIQUE (schedule_block_id, session_date)
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — ASISTENCIA Y ALERTAS (Attendance & Alerts) — `attendance-service`
-- ---------------------------------------------------------------------

CREATE TABLE attendance_records (
    attendance_record_id BIGSERIAL PRIMARY KEY,
    class_session_id  BIGINT NOT NULL REFERENCES class_sessions(class_session_id),
    academic_actor_id BIGINT NOT NULL, -- referencia lógica al dominio "Gestión Académica"
    captured_at       TIMESTAMPTZ,
    attendance_status VARCHAR NOT NULL,
    capture_method    VARCHAR NOT NULL,
    match_score       DECIMAL(5,4), -- score de similitud devuelto por el dominio Biométrico
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at        TIMESTAMPTZ,
    UNIQUE (class_session_id, academic_actor_id)
);

CREATE TABLE justification_types (
    justification_type_id SERIAL PRIMARY KEY,
    name                VARCHAR NOT NULL UNIQUE,
    description         VARCHAR,
    requires_attachment BOOLEAN NOT NULL DEFAULT false,
    status              BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
    -- Se conserva como dominio propio: requires_attachment decide si
    -- justification exige un supporting_document — regla de negocio.
);

CREATE TABLE justifications (
    justification_id      BIGSERIAL PRIMARY KEY,
    attendance_record_id  BIGINT NOT NULL UNIQUE REFERENCES attendance_records(attendance_record_id),
    justification_type_id INT NOT NULL REFERENCES justification_types(justification_type_id),
    reason        TEXT NOT NULL,
    submitted_at  TIMESTAMPTZ NOT NULL,
    review_status VARCHAR NOT NULL,
    reviewed_by   UUID, -- referencia lógica al servicio de Identidad (excluido)
    reviewed_at   TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

CREATE TABLE supporting_documents (
    supporting_document_id BIGSERIAL PRIMARY KEY,
    justification_id BIGINT NOT NULL REFERENCES justifications(justification_id),
    file_name    VARCHAR NOT NULL,
    storage_uri  VARCHAR NOT NULL,
    mime_type    VARCHAR NOT NULL,
    size_bytes   BIGINT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ
);

CREATE TABLE alerts (
    alert_id          BIGSERIAL PRIMARY KEY,
    academic_actor_id BIGINT NOT NULL, -- referencia lógica al dominio "Gestión Académica"
    alert_type_id     SMALLINT NOT NULL, -- referencia lógica: catálogo excluido (LATE / ABSENT...)
    raised_at         TIMESTAMPTZ NOT NULL,
    resolved_at       TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at        TIMESTAMPTZ
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — RECONOCIMIENTO BIOMÉTRICO (Biometric Recognition) — `biometric-service`
-- ---------------------------------------------------------------------
-- Persiste en MongoDB en el diseño original (vectores de tamaño
-- variable). Se documenta el esquema de colección, no CREATE TABLE.

-- db.facial_embeddings: {
--   _id: ObjectId,
--   person_id: UUID,        // referencia lógica al servicio de Identidad
--   encoding: [Float],      // vector de 512/1024 posiciones
--   model_version: String,
--   template_version: Int,
--   enrolled_at: Date,
--   is_active: Boolean,
--   created_at/updated_at/deleted_at: Date
-- }
-- Índice compuesto: (person_id, is_active)

-- db.fingerprint_embeddings: misma forma que facial_embeddings, con
-- finger_number en vez de encoding facial.

-- Único table SQL de este dominio (reubicada desde "Configuration"):
CREATE TABLE biometric_update_cases (
    case_id               UUID PRIMARY KEY,
    person_id             UUID NOT NULL, -- referencia lógica al servicio de Identidad
    biometric_type        VARCHAR NOT NULL, -- FACE / FINGERPRINT
    finger_number         SMALLINT,
    current_embedding_ref VARCHAR, -- _id lógico en la colección Mongo correspondiente
    reason                TEXT NOT NULL,
    update_status         VARCHAR NOT NULL DEFAULT 'Pending',
    requested_by          UUID, -- referencia lógica al servicio de Identidad
    requested_at          TIMESTAMPTZ,
    reviewed_by           UUID, -- referencia lógica al servicio de Identidad
    reviewed_at           TIMESTAMPTZ,
    resolution_notes      VARCHAR,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at            TIMESTAMPTZ
);
