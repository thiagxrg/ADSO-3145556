-- =====================================================================
-- translates-sign-language — modelo de datos núcleo, 3FN
-- Fuente: code-sena/trans-sl-docs (06-data/domains/*.md), curado para
-- excluir IAM/seguridad y dominios secundarios/en pausa.
-- Corte: 2026-09-22. Ya en PostgreSQL en el original — se conservan sus
-- propios tipos ENUM (06-data/modeling-conventions.md).
--
-- Nota: este es el equipo con el análisis de normalización más riguroso
-- de los 10 (3NF+BCNF, autocrítico: su propio normalization-assessment.md
-- señala que sus tablas de rollup "currently contradict the domain map —
-- DATA-03"). Este archivo no toca esa discusión — solo recorta el núcleo.
--
-- EXCLUIDO A PROPÓSITO:
--   identity.* (6 tablas), authz.* (4 tablas)  -- seguridad
--   notification.* (3 tablas)                  -- Generic, delgado, reacciona a eventos de otros dominios
--   gamification.* (2 tablas)                  -- marcado ⏸ "provisional" en el propio domain-map, pendiente de RF8
--   audit.* (2 tablas)                         -- infraestructura transversal, no negocio
-- =====================================================================


-- ---------------------------------------------------------------------
-- Tipos compartidos (subconjunto de 06-data/modeling-conventions.md
-- relevante para los 4 dominios conservados)
-- ---------------------------------------------------------------------
CREATE TYPE ui_language     AS ENUM ('ES', 'EN');
CREATE TYPE theme_option    AS ENUM ('LIGHT', 'DARK');
CREATE TYPE sign_type       AS ENUM ('LETTER', 'WORD', 'PHRASE');
CREATE TYPE sign_language   AS ENUM ('LSC');
CREATE TYPE content_status  AS ENUM ('ACTIVE', 'INACTIVE', 'DRAFT');
CREATE TYPE resource_type   AS ENUM ('IMAGE', 'VIDEO', 'ANIMATION');
CREATE TYPE output_mode     AS ENUM ('TEXT', 'AUDIO');
CREATE TYPE usage_section   AS ENUM ('HOME', 'TRANSLATION', 'ALPHABET', 'LEXICON', 'HISTORY',
                                     'PROFILE', 'SETTINGS', 'NOTIFICATIONS', 'ACHIEVEMENTS', 'ADMIN');
CREATE TYPE usage_event_type AS ENUM ('SECTION_VIEW', 'TRANSLATION_STARTED', 'TRANSLATION_COMPLETED',
                                      'TRANSLATION_FAILED', 'AUDIO_PLAYED', 'SIGN_VIEWED',
                                      'SEARCH_PERFORMED', 'HISTORY_ENTRY_DELETED',
                                      'PREFERENCE_CHANGED', 'NOTIFICATION_OPENED');
CREATE TYPE reference_entity AS ENUM ('TRANSLATION', 'SIGN', 'CATEGORY', 'ACHIEVEMENT',
                                      'NOTIFICATION', 'AI_MODEL', 'USER');


-- ---------------------------------------------------------------------
-- DOMINIO 1 — RECONOCIMIENTO Y TRADUCCIÓN (Recognition & Translation)
-- CORE — `recognition-service`
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS ai;
CREATE TABLE ai.ai_models (
    model_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version           VARCHAR(50) NOT NULL UNIQUE, -- 1.0.0, 1.1.0
    description       VARCHAR(255),
    trained_at        TIMESTAMPTZ NOT NULL,
    trained_by        UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    sign_language     sign_language NOT NULL DEFAULT 'LSC',
    sample_count      INTEGER NOT NULL,
    sign_count        INTEGER NOT NULL,
    accuracy          DECIMAL(5,4), -- 0..1 sobre el conjunto de prueba
    storage_reference TEXT NOT NULL, -- ruta al .tflite publicado
    is_active         BOOLEAN NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE SCHEMA IF NOT EXISTS translation;
CREATE TABLE translation.translations (
    translation_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    recognized_text TEXT NOT NULL, -- denormalización deliberada: frase congelada, ver normalization-assessment.md #1
    confidence      DECIMAL(5,4),  -- confianza de la FRASE completa, no promedio de sus señas (#4)
    output_mode     output_mode NOT NULL DEFAULT 'TEXT',
    model_id        UUID REFERENCES ai.ai_models(model_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMPTZ
);

CREATE TABLE translation.translation_signs (
    translation_sign_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    translation_id      UUID NOT NULL REFERENCES translation.translations(translation_id) ON DELETE CASCADE,
    sign_id              UUID NOT NULL, -- referencia lógica al dominio "Aprendizaje y Léxico"
    "position"           INTEGER NOT NULL,
    confidence           DECIMAL(5,4) -- confianza de ESTA seña individual
);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — APRENDIZAJE Y LÉXICO (Learning & Lexicon) — `lexicon-service`
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS lexicon;
CREATE TABLE lexicon.categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE lexicon.sign_lexicon (
    sign_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(50) NOT NULL UNIQUE, -- ej. GREETING_HELLO — identificador estable, no traducible
    sign_type     sign_type NOT NULL DEFAULT 'WORD',
    letter        VARCHAR(1), -- solo cuando sign_type = LETTER
    sign_language sign_language NOT NULL DEFAULT 'LSC',
    category_id   UUID NOT NULL REFERENCES lexicon.categories(category_id) ON DELETE RESTRICT,
    status        content_status NOT NULL DEFAULT 'ACTIVE',
    created_by    UUID, -- referencia lógica al servicio de Identidad (excluido)
    updated_by    UUID,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lexicon.sign_localizations (
    sign_localization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sign_id              UUID NOT NULL REFERENCES lexicon.sign_lexicon(sign_id) ON DELETE CASCADE,
    ui_language          ui_language NOT NULL,
    name                 VARCHAR(150) NOT NULL, -- 'Hola' / 'Hello' — texto humano, sí traducible
    meaning              VARCHAR(255),
    description          TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lexicon.multimedia_resources (
    resource_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sign_id       UUID NOT NULL REFERENCES lexicon.sign_lexicon(sign_id) ON DELETE CASCADE,
    resource_type resource_type NOT NULL,
    uri           TEXT NOT NULL,
    mime_type     VARCHAR(100),
    "position"    INTEGER NOT NULL DEFAULT 1,
    description   TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — ANALÍTICA DE USO (Usage Analytics) — `analytics-service`
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS usage_stats;
CREATE TABLE usage_stats.usage_events (
    usage_event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID, -- referencia lógica al servicio de Identidad (excluido)
    session_id     UUID, -- referencia lógica al servicio de Identidad (excluido)
    section        usage_section NOT NULL,
    event_type     usage_event_type NOT NULL,
    reference_type reference_entity,
    reference_id   UUID,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE usage_stats.usage_daily_stats (
    stat_date     DATE NOT NULL, -- día calendario, America/Bogota
    section       usage_section NOT NULL,
    event_type    usage_event_type NOT NULL,
    event_count   INTEGER NOT NULL,
    unique_users  INTEGER NOT NULL, -- ⚠️ NO aditivo entre filas — ver normalization-assessment.md
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (stat_date, section, event_type)
);

CREATE TABLE usage_stats.session_daily_stats (
    stat_date              DATE PRIMARY KEY,
    session_count          INTEGER NOT NULL,
    unique_users           INTEGER NOT NULL, -- mismo aviso de no-aditividad
    total_duration_seconds BIGINT NOT NULL,
    avg_duration_seconds   INTEGER NOT NULL,
    calculated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — PERFIL Y PREFERENCIAS (Profile & Preferences) — `profile-service`
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS profile;
CREATE TABLE profile.user_preferences (
    user_preference_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL UNIQUE, -- referencia lógica al servicio de Identidad (excluido)
    ui_language           ui_language NOT NULL DEFAULT 'ES',
    theme                 theme_option NOT NULL DEFAULT 'LIGHT',
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
