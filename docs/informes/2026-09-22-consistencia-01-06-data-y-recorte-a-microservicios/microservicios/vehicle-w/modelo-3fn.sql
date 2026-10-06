-- =====================================================================
-- vehicle-washing — modelo de datos núcleo, 3FN
-- Fuente: code-sena/vehicle-w-docs (06-data/models.md), curado para
-- excluir IAM/seguridad y catálogos de pura parametrización.
-- Corte: 2026-09-22. Traducido de SQL Server a sintaxis PostgreSQL para
-- que el paquete sea uniforme entre los 10 equipos de la ficha.
--
-- Convención de auditoría del equipo (se conserva igual en cada tabla):
-- created_at/created_by, updated_at/updated_by, deleted_at/deleted_by,
-- row_version — soft delete + optimistic locking. Se omiten los
-- comentarios repetidos por tabla para no inflar el archivo.
--
-- EXCLUIDO A PROPÓSITO (schemas `security` + `audit` completos — 9 tablas):
--   security.person, security.app_user, security.role, security.permission,
--   security.role_permission, security.user_role, security.user_session,
--   security.password_reset_token, audit.audit_log
--
-- EXCLUIDO A PROPÓSITO (schema `settings` — configuración, no negocio de
-- lavado de vehículos):
--   settings.establishment (fila única con datos de la empresa — logo, NIT)
--   settings.user_preference (tema/idioma por usuario)
--
-- EXCLUIDO A PROPÓSITO (schema `notification` — Generic, reacciona a
-- eventos de los otros dominios, no tiene lógica de negocio propia):
--   notification.notification_type, notification.notification
--
-- NOTA (hallazgo del informe de consistencia 2026-09-22): la entidad
-- `Booking` de 02-domain/entities-and-rules.md se llama `reserve` en este
-- modelo de datos — mismo concepto, dos nombres distintos según el
-- documento. Se respeta el nombre real de la base de datos (`reserve`)
-- aquí, y se deja la nota para quien compare contra el dominio.
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — CLIENTES Y VEHÍCULOS (Customer & Vehicle) — `customer-service`
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS customer;
CREATE TABLE customer.vehicle_type (
    vehicle_type_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code          VARCHAR(30) NOT NULL UNIQUE,
    name          VARCHAR(60) NOT NULL,
    size_factor   DECIMAL(4,2) NOT NULL, -- solo sugiere precio al crear tarifa; nunca lo calcula (ver normalization-assessment.md)
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ,
    deleted_at    TIMESTAMPTZ,
    row_version   INT NOT NULL DEFAULT 1
);

CREATE TABLE customer.customer (
    customer_id    BIGSERIAL PRIMARY KEY,
    person_id      UUID NOT NULL UNIQUE, -- referencia lógica al servicio de Identidad (excluido)
    loyalty_points INT NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0), -- denormalización controlada: reconciliable contra loyalty_transaction
    customer_since DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ,
    deleted_at     TIMESTAMPTZ,
    row_version    INT NOT NULL DEFAULT 1
    -- No repite nombre/teléfono de la persona: viven en el servicio de
    -- Identidad. Duplicarlos violaría 3FN (ver normalization-assessment.md).
);

CREATE TABLE customer.customer_vehicle (
    customer_vehicle_id BIGSERIAL PRIMARY KEY,
    customer_id     BIGINT NOT NULL REFERENCES customer.customer(customer_id),
    license_plate   VARCHAR(10) NOT NULL,
    vehicle_type_id SMALLINT NOT NULL REFERENCES customer.vehicle_type(vehicle_type_id),
    brand VARCHAR(50),
    color VARCHAR(30),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    row_version INT NOT NULL DEFAULT 1
);
-- Único mientras esté activo (índice filtrado): una placa dada de baja puede reingresar.
CREATE UNIQUE INDEX ux_customer_vehicle_plate_active ON customer.customer_vehicle (license_plate) WHERE deleted_at IS NULL;


-- ---------------------------------------------------------------------
-- DOMINIO 2 — CATÁLOGO Y RESERVAS (Catalog & Booking) — `booking-service`
-- =reserve= en el modelo original =Booking en 02-domain (ver nota arriba)
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS catalog;
CREATE TABLE catalog.service_category (
    service_category_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    description VARCHAR(200),
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE catalog.service (
    service_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    service_category_id SMALLINT NOT NULL REFERENCES catalog.service_category(service_category_id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE catalog.service_price (
    service_price_id BIGSERIAL PRIMARY KEY,
    service_id      INT NOT NULL REFERENCES catalog.service(service_id),
    vehicle_type_id SMALLINT NOT NULL REFERENCES customer.vehicle_type(vehicle_type_id),
    price             DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    estimated_minutes SMALLINT NOT NULL CHECK (estimated_minutes > 0),
    valid_from DATE NOT NULL,
    valid_to   DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    CHECK (valid_to IS NULL OR valid_to > valid_from)
    -- Inmutable tras crearse en el diseño original (trigger de aplicación):
    -- así una reserva puede apuntar al precio exacto que se cobró (ver DOMINIO 4).
);

CREATE SCHEMA IF NOT EXISTS reserve;
CREATE TABLE reserve.business_hour (
    business_hour_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    day_of_week SMALLINT NOT NULL UNIQUE CHECK (day_of_week BETWEEN 1 AND 7),
    opens_at  TIME NOT NULL,
    closes_at TIME NOT NULL CHECK (closes_at > opens_at),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE reserve.business_hour_exception (
    business_hour_exception_id SERIAL PRIMARY KEY,
    exception_date DATE NOT NULL UNIQUE,
    is_closed BOOLEAN NOT NULL DEFAULT true,
    opens_at  TIME,
    closes_at TIME,
    reason    VARCHAR(120) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    CHECK ((is_closed AND opens_at IS NULL AND closes_at IS NULL)
        OR (NOT is_closed AND opens_at IS NOT NULL AND closes_at IS NOT NULL AND closes_at > opens_at))
);

CREATE TABLE reserve.service_bay (
    service_bay_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
    -- La capacidad concurrente se cuenta con bahías activas, no se
    -- almacena repetida en business_hour (3FN, ver normalization-assessment.md).
);

CREATE TABLE reserve.reserve_status (
    reserve_status_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    is_final BOOLEAN NOT NULL DEFAULT false,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
    -- Catálogo propio en vez de un `status` genérico compartido, a
    -- propósito: así una FK a `reserve_status` nunca puede aceptar por
    -- error un estado de pago (ver modeling-conventions.md).
);

CREATE TABLE reserve.cancellation_reason (
    cancellation_reason_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    is_customer_fault BOOLEAN NOT NULL DEFAULT false,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE reserve.reserve (
    reserve_id BIGSERIAL PRIMARY KEY,
    customer_vehicle_id    BIGINT NOT NULL REFERENCES customer.customer_vehicle(customer_vehicle_id),
    service_bay_id         SMALLINT REFERENCES reserve.service_bay(service_bay_id),
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end   TIMESTAMPTZ NOT NULL CHECK (scheduled_end > scheduled_start),
    reserve_status_id      SMALLINT NOT NULL REFERENCES reserve.reserve_status(reserve_status_id),
    booked_by              UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    cancellation_reason_id SMALLINT REFERENCES reserve.cancellation_reason(cancellation_reason_id),
    points_redeemed        INT NOT NULL DEFAULT 0,
    points_discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    notes VARCHAR(300),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    CHECK ((points_redeemed = 0 AND points_discount_amount = 0) OR (points_redeemed > 0 AND points_discount_amount > 0))
    -- No tiene columna `total`: es derivado de reserve_service + service_price
    -- menos reserve_promotion/points_discount_amount, a propósito, para
    -- que nunca haya un total guardado que se desactualice.
);

CREATE TABLE reserve.reserve_service (
    reserve_service_id BIGSERIAL PRIMARY KEY,
    reserve_id       BIGINT NOT NULL REFERENCES reserve.reserve(reserve_id),
    service_price_id BIGINT NOT NULL REFERENCES catalog.service_price(service_price_id), -- precio congelado por referencia inmutable
    quantity SMALLINT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    UNIQUE (reserve_id, service_price_id)
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — OPERACIÓN Y EJECUCIÓN (Operations & Assignment) — `operations-service`
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS execution;
CREATE TABLE execution.execution_status (
    execution_status_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    is_final BOOLEAN NOT NULL DEFAULT false,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE execution.operator (
    operator_id SERIAL PRIMARY KEY,
    user_id   UUID NOT NULL UNIQUE, -- referencia lógica al servicio de Identidad (excluido)
    hired_on  DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
    -- No guarda person_id directo: operator -> app_user -> person ya es
    -- una ruta a ese dato; guardarlo aquí también sería una segunda ruta
    -- a la misma verdad (ver normalization-assessment.md).
);

CREATE TABLE execution.operator_availability (
    operator_availability_id SERIAL PRIMARY KEY,
    operator_id INT NOT NULL REFERENCES execution.operator(operator_id),
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    starts_at TIME NOT NULL,
    ends_at   TIME NOT NULL CHECK (ends_at > starts_at),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    UNIQUE (operator_id, day_of_week)
);

CREATE TABLE execution.operator_absence (
    operator_absence_id SERIAL PRIMARY KEY,
    operator_id INT NOT NULL REFERENCES execution.operator(operator_id),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at   TIMESTAMPTZ NOT NULL CHECK (ends_at > starts_at),
    reason VARCHAR(120) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE execution.service_execution (
    service_execution_id BIGSERIAL PRIMARY KEY,
    reserve_service_id  BIGINT NOT NULL UNIQUE, -- referencia lógica al dominio "Catálogo y Reservas"
    operator_id          INT NOT NULL REFERENCES execution.operator(operator_id),
    execution_status_id  SMALLINT NOT NULL REFERENCES execution.execution_status(execution_status_id),
    started_at  TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    quality_rating     SMALLINT CHECK (quality_rating BETWEEN 1 AND 5), -- calificación del cliente sobre ESTE ítem (no existe tabla "Rating" aparte)
    quality_comment    VARCHAR(500),
    rated_at           TIMESTAMPTZ,
    is_comment_visible BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    CHECK (finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at),
    CHECK ((quality_rating IS NULL AND rated_at IS NULL) OR (quality_rating IS NOT NULL AND rated_at IS NOT NULL))
    -- Nota (informe de consistencia 2026-09-22): 02-domain define `Rating`
    -- como entidad propia; aquí es un atributo de service_execution, no
    -- una tabla aparte. Decisión defendible (una calificación no existe
    -- sin el servicio que califica) pero no documentada como tal en el
    -- repo original — se deja explícita aquí.
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — PAGOS, PROMOCIONES Y FIDELIZACIÓN
-- (Payment, Promotions & Loyalty) — `payment-service`
-- ---------------------------------------------------------------------

CREATE TABLE customer.loyalty_movement_type (
    loyalty_movement_type_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    sign SMALLINT NOT NULL CHECK (sign IN (-1, 1)),
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE customer.loyalty_transaction (
    loyalty_transaction_id BIGSERIAL PRIMARY KEY,
    customer_id  BIGINT NOT NULL REFERENCES customer.customer(customer_id),
    loyalty_movement_type_id SMALLINT NOT NULL REFERENCES customer.loyalty_movement_type(loyalty_movement_type_id),
    reserve_id   BIGINT REFERENCES reserve.reserve(reserve_id),
    points       INT NOT NULL CHECK (points <> 0),
    balance_after INT NOT NULL CHECK (balance_after >= 0), -- convierte el saldo cacheado en un libro auditable
    expires_on   DATE,
    description  VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE SCHEMA IF NOT EXISTS promotion;
CREATE TABLE promotion.discount_type (
    discount_type_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE promotion.promotion (
    promotion_id SERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(300),
    discount_type_id SMALLINT NOT NULL REFERENCES promotion.discount_type(discount_type_id),
    discount_value DECIMAL(12,2) NOT NULL CHECK (discount_value > 0),
    max_discount_amount DECIMAL(12,2),
    min_purchase_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    is_public BOOLEAN NOT NULL DEFAULT true,
    min_completed_reserve INT NOT NULL DEFAULT 0 CHECK (min_completed_reserve >= 0),
    valid_from DATE NOT NULL,
    valid_to   DATE NOT NULL CHECK (valid_to >= valid_from),
    max_redemptions INT,
    max_redemptions_per_customer INT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE promotion.promotion_service (
    promotion_service_id SERIAL PRIMARY KEY,
    promotion_id INT NOT NULL REFERENCES promotion.promotion(promotion_id),
    service_id   INT NOT NULL, -- referencia lógica al dominio "Catálogo y Reservas"
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    UNIQUE (promotion_id, service_id)
);

CREATE TABLE promotion.promotion_customer (
    promotion_customer_id BIGSERIAL PRIMARY KEY,
    promotion_id INT NOT NULL REFERENCES promotion.promotion(promotion_id),
    customer_id  BIGINT NOT NULL REFERENCES customer.customer(customer_id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by UUID, -- referencia lógica al servicio de Identidad (excluido)
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    UNIQUE (promotion_id, customer_id)
);

CREATE TABLE promotion.reserve_promotion (
    reserve_promotion_id BIGSERIAL PRIMARY KEY,
    reserve_id   BIGINT NOT NULL REFERENCES reserve.reserve(reserve_id),
    promotion_id INT NOT NULL REFERENCES promotion.promotion(promotion_id),
    applied_amount DECIMAL(12,2) NOT NULL CHECK (applied_amount > 0), -- descuento congelado al momento de aplicarse, no recalculado
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    UNIQUE (reserve_id, promotion_id)
);

CREATE SCHEMA IF NOT EXISTS payment;
CREATE TABLE payment.payment_method_type (
    payment_method_type_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    requires_account BOOLEAN NOT NULL DEFAULT true,
    requires_receipt BOOLEAN NOT NULL DEFAULT true,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE payment.payment_account (
    payment_account_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_method_type_id SMALLINT NOT NULL REFERENCES payment.payment_method_type(payment_method_type_id),
    account_holder VARCHAR(120) NOT NULL,
    account_number VARCHAR(50),
    qr_image_url   VARCHAR(500),
    instructions   VARCHAR(300),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE payment.payment_status (
    payment_status_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL,
    is_final BOOLEAN NOT NULL DEFAULT false,
    display_order SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE payment.payment (
    payment_id BIGSERIAL PRIMARY KEY,
    reserve_id         BIGINT NOT NULL REFERENCES reserve.reserve(reserve_id),
    payment_account_id SMALLINT NOT NULL REFERENCES payment.payment_account(payment_account_id),
    payment_status_id  SMALLINT NOT NULL REFERENCES payment.payment_status(payment_status_id),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    processed_at TIMESTAMPTZ,
    approved_by  UUID, -- referencia lógica al servicio de Identidad (excluido)
    rejection_reason VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1
);

CREATE TABLE payment.payment_receipt (
    payment_receipt_id BIGSERIAL PRIMARY KEY,
    payment_id BIGINT NOT NULL REFERENCES payment.payment(payment_id),
    file_url  VARCHAR(500) NOT NULL,
    transaction_reference VARCHAR(100),
    reported_amount DECIMAL(12,2) CHECK (reported_amount IS NULL OR reported_amount > 0),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    uploaded_by UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID, -- referencia lógica al servicio de Identidad (excluido)
    review_comment VARCHAR(300),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ, row_version INT NOT NULL DEFAULT 1,
    CHECK ((reviewed_at IS NULL AND reviewed_by IS NULL) OR (reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL))
);
