# 4 dominios reales para microservicios — woman-alert

Fuente: `code-sena/wal-docs`, corte 2026-09-22.

---

## 1. Gestión de Alertas — `alert-service` (Core)

**Tablas:** `alerts`, `alert_contacts`, `location_logs`, `alert_reminders`,
`frequent_locations`.

**Por qué es el dominio Core:** el propio `domain-map.md` lo marca
"Alert Management (Core Domain)" — es la razón de negocio del producto:
detectar el botón de pánico, avisar a los contactos, registrar la
ubicación mientras dure la emergencia.

**Por qué necesita ser su propio servicio:** tiene el único requisito de
disponibilidad no negociable del sistema — una alerta no puede fallar por
falta de recursos de otro dominio (evidencia, zonas). Aislarlo garantiza
que un problema en, por ejemplo, el directorio de zonas nunca retrase el
envío de una alerta real.

**Eventos que publicaría:** `AlertTriggered`, `AlertResolved`,
`ContactNotified`.

---

## 2. Zonas y Recursos de Ayuda — `zone-service`

**Tablas:** `zones`, `zone_reports`, `emergency_resources`,
`resource_calls`.

**Por qué es un dominio propio:** es un directorio geográfico
(zonas de riesgo, hospitales, líneas de emergencia) que cambia por
curaduría administrativa, no por evento de usuario — un patrón de
lectura-mucho/escritura-poco opuesto al de Gestión de Alertas.

**Eventos que publicaría:** `ZoneReported`, `ZoneReviewApproved`,
`ResourceCallLogged`.

**Dependencia:** `resource_calls.alert_id` es opcional — una llamada a un
recurso de ayuda puede o no estar asociada a una alerta activa.

---

## 3. Evidencia — `evidence-service`

**Tablas:** `evidence`.

**Por qué es un dominio propio, aunque hoy sea una sola tabla:** almacena
archivos (foto, video, audio) — un requisito de almacenamiento e
infraestructura (buckets, CDN, cifrado en reposo) completamente distinto
al de una base de datos relacional. Es también el dato más sensible del
sistema: conviene que tenga su propia política de retención y acceso,
separada de todo lo demás.

**Eventos que consumiría:** `AlertTriggered` (para asociar evidencia
nueva a la alerta correcta).

---

## 4. Contactos y Notificaciones — `contact-notification-service`

**Tablas:** `emergency_contacts`, `notifications`.

**Por qué se fusionan:** ambos son, en esencia, "avisarle algo a alguien":
un contacto de emergencia es a quién avisar por fuera de la app, una
notificación es qué se le avisa al propio usuario dentro de ella. Ninguno
de los dos tiene lógica de negocio propia más allá de CRUD — no justifican
dos servicios separados.

**Eventos que consumiría:** todos los eventos de Gestión de Alertas y de
Zonas, para generar la notificación correspondiente.

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| Identity and Accounts (11 tablas: `role`, `user`, `account`, `user_profile`, `admin_profile`, `recovery_request`, `device`, `device_permission`, `alert_activation_setting`, `device_session`, `user_preference`) | Seguridad y gestión del dispositivo/cuenta del propio usuario — ya es su propio bounded context |
| Administration and Moderation (`audit_log`, `user_report`, `moderation_action`, `system_configuration`) | Infraestructura de back-office, no negocio de atención de emergencias |
