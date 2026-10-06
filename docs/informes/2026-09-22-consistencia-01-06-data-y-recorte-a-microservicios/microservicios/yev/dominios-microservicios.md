# 4 dominios reales para microservicios — your-event

⚠️ **Ver README.md primero.** `yev-docs` no tiene su modelo de datos en el
archivo canónico (`06-data/models.md` es plantilla sin diligenciar). Este
recorte se reconstruyó desde `06-data/evidence/models.md` — una
instantánea con propósito y "campos clave" por tabla, no DDL completo — y
desde las inconsistencias que ese mismo documento cita hacia un repositorio
externo (`TuEvento-Docs`) no verificable desde `code-sena`.

---

## 1. Eventos y Venues — `event-service`

**Tablas:** `departments`, `cities`, `sites`, `categories`,
`category_events`, `events`, `event_layouts`, `event_media`,
`event_media_log`, `event_status_log`, `section_types`, `event_sections`,
`event_reviews`, `event_review_replies`, `event_translations`,
`category_translations`.

**Por qué se fusionan Geolocalización, Categorías y Secciones con
Eventos:** las tres describen el mismo objeto desde ángulos distintos —
dónde ocurre, cómo se clasifica, cómo se divide por precio — y ninguna
tiene sentido de negocio sin un evento al que pertenecer.

**Un hallazgo que vale la pena dejar explícito:** la evidencia describe
`event_rating` (módulo Event) y `review` (módulo Profile) con el mismo
propósito — calificar un evento. Se modelaron aquí como una sola tabla
(`event_reviews`); es una señal más de que esta carpeta es una instantánea
sin reconciliar entre iteraciones del diseño, no un documento único y
consistente.

---

## 2. Boletería y Asientos — `ticket-service`

**Tablas:** `seat_blocks`, `seats`, `seat_logs`, `orders`, `tickets`,
`seat_tickets`, `ticket_checkins`, `ticket_logs`.

**Por qué es un dominio propio:** la propia evidencia lo señala —
"crítico para el selector en tiempo real (SockJS)" — es el único dominio
con requisito de concurrencia real: dos personas no pueden comprar el
mismo asiento. Necesita su propio control de bloqueo, distinto del CRUD de
catálogo de Eventos.

---

## 3. Pagos y Billetera — `payment-service`

**Tablas:** `payments`, `payment_logs`, `refunds`,
`transaction_webhooks`, `wallets`, `wallet_transactions`,
`wallet_references`.

**Por qué es un dominio propio:** maneja dinero real a través de una
pasarela externa (Wompi) con webhooks que exigen idempotencia
(`transaction_webhooks.payload`) — un requisito de integridad que ningún
otro dominio comparte, y que típicamente exige su propio nivel de
cumplimiento y auditoría.

---

## 4. Perfil y Notificaciones — `profile-notification-service`

**Tablas:** `profiles`, `profile_logs`, `profile_translations`,
`preferences`, `activity_logs`, `notification_types`, `channels`,
`notifications`, `notification_users`.

**Por qué se fusionan:** ninguna de las dos partes tiene peso propio para
justificar un quinto servicio — el perfil es CRUD de bajo tráfico, y las
notificaciones existen para servir a los otros tres dominios (confirmar
una compra, avisar un cambio de evento), no para operar por sí solas.

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| Módulo Security (15 tablas: `user`, `role`, `auth_session`, `organizer_petition`...) | Seguridad — ya es su propio bounded context (`auth-service`) |
| `theme`, `user_theme`, `theme_customization`, `theme_log`, `language` | Personalización de interfaz — parametrización, no negocio de venta de boletos |
