-- =====================================================================
-- your-event — modelo de datos núcleo, 3FN
-- ADVERTENCIA (ver README.md de esta carpeta): yev-docs NO tiene el
-- modelo de datos en su archivo canónico (06-data/models.md es la
-- plantilla sin diligenciar). Este archivo se reconstruyó a partir de
-- 06-data/evidence/models.md, que describe las tablas por propósito y
-- "campos clave" — no DDL completo. Los tipos y columnas que no estaban
-- explícitos se completaron con criterio razonable (marcados abajo);
-- verificar contra el repositorio externo que cita esa evidencia
-- (`TuEvento-Docs/05_Diseno_Software/SQL/`) antes de usar en producción.
-- Corte: 2026-09-22.
--
-- EXCLUIDO A PROPÓSITO (módulo Security, `auth-service` — 15 tablas):
--   user_status, role, permission, role_permission, user,
--   user_status_history, login_credentials, oauth_account, auth_session,
--   refresh_token, account_activation, account_lockout,
--   organizer_petition, recover_password, password_history
--
-- EXCLUIDO A PROPÓSITO (parametrización pura — personalización de UI,
-- no negocio de venta de boletos):
--   theme, user_theme, theme_customization, theme_log, language
--   (el idioma de la interfaz es preferencia de usuario; las tablas de
--   traducción de CONTENIDO sí se conservan dentro de cada dominio)
-- =====================================================================


-- ---------------------------------------------------------------------
-- DOMINIO 1 — EVENTOS Y VENUES (Event & Venue Management) — `event-service`
-- ---------------------------------------------------------------------

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE cities (
    city_id SERIAL PRIMARY KEY,
    department_id INT NOT NULL REFERENCES departments(department_id),
    name VARCHAR(100) NOT NULL,
    UNIQUE (department_id, name)
);

CREATE TABLE sites (
    site_id SERIAL PRIMARY KEY,
    city_id   INT NOT NULL REFERENCES cities(city_id),
    name      VARCHAR(150) NOT NULL,
    address   VARCHAR(200) NOT NULL,
    capacity  INT,
    latitude  DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    dad_id  INT REFERENCES categories(category_id) ON DELETE SET NULL, -- jerarquía padre-hijo
    name    VARCHAR(100) NOT NULL,
    active  BOOLEAN NOT NULL DEFAULT true,
    visible BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE events (
    event_id   SERIAL PRIMARY KEY,
    user_id    UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido) — el organizador
    site_id    INT NOT NULL REFERENCES sites(site_id),
    event_name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    finish_date DATE NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT','PUBLISHED','CANCELLED','COMPLETED')),
    is_public BOOLEAN NOT NULL DEFAULT true,
    available_seats INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (finish_date > start_date),
    UNIQUE (event_name, start_date, site_id)
);

CREATE TABLE category_events (
    category_id INT NOT NULL REFERENCES categories(category_id),
    event_id    INT NOT NULL REFERENCES events(event_id),
    PRIMARY KEY (category_id, event_id)
);

CREATE TABLE event_layouts (
    event_id    INT PRIMARY KEY REFERENCES events(event_id),
    layout_data JSONB NOT NULL -- secciones/bloques/asientos, diseñado desde la web
);

CREATE TABLE event_media (
    event_media_id SERIAL PRIMARY KEY,
    event_id  INT NOT NULL REFERENCES events(event_id),
    image_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE event_media_log (
    event_media_log_id SERIAL PRIMARY KEY,
    event_media_id INT NOT NULL REFERENCES event_media(event_media_id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by UUID -- referencia lógica al servicio de Identidad (excluido)
);

CREATE TABLE event_status_log (
    event_status_log_id SERIAL PRIMARY KEY,
    event_id   INT NOT NULL REFERENCES events(event_id),
    old_status VARCHAR(15),
    new_status VARCHAR(15) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by UUID -- referencia lógica al servicio de Identidad (excluido)
);

CREATE TABLE section_types (
    section_type_id SERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE, -- VIP, General, Tribuna...
    name VARCHAR(60) NOT NULL
    -- Se conserva como dominio propio: define el nivel de servicio que
    -- justifica el precio, no una etiqueta decorativa.
);

CREATE TABLE event_sections (
    event_section_id SERIAL PRIMARY KEY,
    event_id        INT NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
    section_type_id INT NOT NULL REFERENCES section_types(section_type_id),
    capacity        INT NOT NULL CHECK (capacity > 0),
    available_seats INT NOT NULL CHECK (available_seats <= capacity),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (event_id, section_type_id)
);

-- Reseñas de eventos: el documento fuente las describe dos veces
-- (`event_rating` en el módulo Event y `review` en el módulo Profile,
-- con el mismo propósito) — señal de que "evidence/" es una instantánea
-- sin reconciliar entre iteraciones. Se modelan aquí una sola vez.
CREATE TABLE event_reviews (
    event_review_id SERIAL PRIMARY KEY,
    event_id INT NOT NULL REFERENCES events(event_id),
    user_id  UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    rating   INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment  VARCHAR(255) NOT NULL,
    is_visible BOOLEAN NOT NULL DEFAULT true, -- moderación de contenido
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE event_review_replies (
    reply_id SERIAL PRIMARY KEY,
    event_review_id INT NOT NULL REFERENCES event_reviews(event_review_id),
    parent_reply_id INT REFERENCES event_review_replies(reply_id), -- anidado
    user_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    comment VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Traducciones de contenido (se conservan: son el evento/categoría en sí,
-- no una preferencia de interfaz; el catálogo `language` sí se excluye).
CREATE TABLE event_translations (
    event_id    INT NOT NULL REFERENCES events(event_id),
    language_id INT NOT NULL, -- referencia lógica: catálogo de idiomas (excluido)
    translated_name        VARCHAR(100),
    translated_description VARCHAR(255),
    source VARCHAR(50) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','auto-translated')),
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','published')),
    PRIMARY KEY (event_id, language_id)
);

CREATE TABLE category_translations (
    category_id INT NOT NULL REFERENCES categories(category_id),
    language_id INT NOT NULL, -- referencia lógica: catálogo de idiomas (excluido)
    translated_name        VARCHAR(100),
    translated_description VARCHAR(255),
    PRIMARY KEY (category_id, language_id)
);


-- ---------------------------------------------------------------------
-- DOMINIO 2 — BOLETERÍA Y ASIENTOS (Ticketing & Seating) — `ticket-service`
-- ---------------------------------------------------------------------

CREATE TABLE seat_blocks (
    seat_block_id SERIAL PRIMARY KEY,
    event_section_id INT NOT NULL, -- referencia lógica al dominio "Eventos y Venues"
    name VARCHAR(60) NOT NULL
);

CREATE TABLE seats (
    seat_id SERIAL PRIMARY KEY,
    seat_block_id    INT NOT NULL REFERENCES seat_blocks(seat_block_id),
    event_section_id INT NOT NULL, -- referencia lógica al dominio "Eventos y Venues"
    code     VARCHAR(20) NOT NULL, -- ej. A-12
    row_number INT NOT NULL,
    seat_position INT NOT NULL,
    seat_type   VARCHAR(10) NOT NULL DEFAULT 'regular' CHECK (seat_type IN ('regular','courtesy')),
    status      VARCHAR(10) NOT NULL DEFAULT 'available'
        CHECK (status IN ('available','reserved','sold','courtesy'))
);

CREATE TABLE seat_logs (
    seat_log_id SERIAL PRIMARY KEY,
    seat_id    INT NOT NULL REFERENCES seats(seat_id),
    old_status VARCHAR(10),
    new_status VARCHAR(10) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by UUID, -- referencia lógica al servicio de Identidad (excluido)
    reason VARCHAR(255)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id  UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    event_id INT NOT NULL, -- referencia lógica al dominio "Eventos y Venues"
    status   VARCHAR(15) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','processing','paid','failed','refunded')),
    currency VARCHAR(3) NOT NULL DEFAULT 'COP',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    order_id  INT NOT NULL REFERENCES orders(order_id),
    code      VARCHAR(20) NOT NULL, -- código legible
    qr_code   VARCHAR(255), -- URL o contenido del QR
    status    VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft','payment_pending','paid','cancelled','refunded','used')),
    expiration_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE seat_tickets (
    seat_id   INT NOT NULL REFERENCES seats(seat_id),
    ticket_id INT NOT NULL REFERENCES tickets(ticket_id),
    price     DECIMAL(10,2) NOT NULL, -- precio congelado al momento de la compra
    PRIMARY KEY (seat_id, ticket_id)
);

CREATE TABLE ticket_checkins (
    ticket_checkin_id SERIAL PRIMARY KEY,
    ticket_id     INT NOT NULL REFERENCES tickets(ticket_id),
    checkin_time  TIMESTAMPTZ NOT NULL DEFAULT now(),
    validated_by  UUID NOT NULL -- referencia lógica al servicio de Identidad (excluido) — quién escaneó
);

CREATE TABLE ticket_logs (
    ticket_log_id SERIAL PRIMARY KEY,
    ticket_id  INT NOT NULL REFERENCES tickets(ticket_id),
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ---------------------------------------------------------------------
-- DOMINIO 3 — PAGOS Y BILLETERA (Payments & Wallet) — `payment-service`
-- ---------------------------------------------------------------------

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id   INT NOT NULL, -- referencia lógica al dominio "Boletería y Asientos"
    gateway    VARCHAR(10) NOT NULL DEFAULT 'wompi' CHECK (gateway = 'wompi'),
    gateway_transaction_id VARCHAR(100), -- id de Wompi para conciliación
    status VARCHAR(15) NOT NULL
        CHECK (status IN ('pending','processing','paid','failed','refunded')),
    payment_method VARCHAR(10) NOT NULL CHECK (payment_method IN ('card','pse','nequi','cash')),
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payment_logs (
    payment_log_id SERIAL PRIMARY KEY,
    payment_id INT NOT NULL REFERENCES payments(payment_id),
    old_status VARCHAR(15),
    new_status VARCHAR(15) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refunds (
    refund_id SERIAL PRIMARY KEY,
    payment_id INT NOT NULL REFERENCES payments(payment_id),
    status VARCHAR(15) NOT NULL DEFAULT 'requested'
        CHECK (status IN ('requested','approved','processed','failed')),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ
);

CREATE TABLE transaction_webhooks (
    transaction_webhook_id SERIAL PRIMARY KEY,
    payment_id  INT REFERENCES payments(payment_id),
    payload     JSONB NOT NULL, -- payload completo del webhook de Wompi (idempotencia)
    received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE wallets (
    wallet_id SERIAL PRIMARY KEY,
    user_id  UUID NOT NULL UNIQUE, -- referencia lógica al servicio de Identidad (excluido)
    balance  DECIMAL(10,2) NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'COP'
);

CREATE TABLE wallet_transactions (
    wallet_transaction_id SERIAL PRIMARY KEY,
    wallet_id INT NOT NULL REFERENCES wallets(wallet_id),
    type   VARCHAR(15) NOT NULL CHECK (type IN ('refund','top-up','withdrawal','payment')),
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','completed','failed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE wallet_references (
    wallet_transaction_id INT PRIMARY KEY REFERENCES wallet_transactions(wallet_transaction_id),
    entity_type VARCHAR(10) NOT NULL CHECK (entity_type IN ('order','payment','refund')),
    entity_id   INT NOT NULL -- referencia lógica: el id de esa entidad, en su propio dominio
);


-- ---------------------------------------------------------------------
-- DOMINIO 4 — PERFIL Y NOTIFICACIONES (Profile & Notifications)
-- `profile-notification-service`
-- ---------------------------------------------------------------------

CREATE TABLE profiles (
    profile_id SERIAL PRIMARY KEY,
    user_id   UUID NOT NULL UNIQUE, -- referencia lógica al servicio de Identidad (excluido)
    city_id   INT NOT NULL REFERENCES cities(city_id),
    full_name VARCHAR(100) NOT NULL,
    photo_url VARCHAR(255) NOT NULL, -- S3/MinIO
    bio       VARCHAR(255)
);

CREATE TABLE profile_logs (
    profile_log_id SERIAL PRIMARY KEY,
    profile_id INT NOT NULL REFERENCES profiles(profile_id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE profile_translations (
    profile_id  INT NOT NULL REFERENCES profiles(profile_id),
    language_id INT NOT NULL, -- referencia lógica: catálogo de idiomas (excluido)
    translated_bio VARCHAR(255),
    PRIMARY KEY (profile_id, language_id)
);

CREATE TABLE preferences (
    preference_id SERIAL PRIMARY KEY,
    user_id       UUID NOT NULL UNIQUE, -- referencia lógica al servicio de Identidad (excluido)
    language_id   INT NOT NULL, -- referencia lógica: catálogo de idiomas (excluido)
    theme_id      INT, -- referencia lógica: catálogo de temas (excluido)
    notifications BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE activity_logs (
    activity_log_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    module  VARCHAR(50) NOT NULL,
    action  VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notification_types (
    notification_type_id SERIAL PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE, -- confirmación de compra, recordatorio, cancelación...
    name VARCHAR(100) NOT NULL
);

CREATE TABLE channels (
    channel_id SERIAL PRIMARY KEY,
    code   VARCHAR(20) NOT NULL UNIQUE, -- email | push
    config JSONB -- credenciales del canal (servidor SMTP, llaves push...)
);

CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    notification_type_id INT NOT NULL REFERENCES notification_types(notification_type_id),
    channel_id INT NOT NULL REFERENCES channels(channel_id),
    event_id   INT, -- referencia lógica al dominio "Eventos y Venues"; opcional
    subject VARCHAR(150) NOT NULL,
    body    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notification_users (
    notification_id INT NOT NULL REFERENCES notifications(notification_id),
    user_id UUID NOT NULL, -- referencia lógica al servicio de Identidad (excluido)
    email_address    VARCHAR(255) NOT NULL,
    delivered_status VARCHAR(15) NOT NULL DEFAULT 'Pending'
        CHECK (delivered_status IN ('Pending','Sent','Delivered','Failed')),
    error_message TEXT,
    read_at TIMESTAMPTZ,
    PRIMARY KEY (notification_id, user_id)
);
