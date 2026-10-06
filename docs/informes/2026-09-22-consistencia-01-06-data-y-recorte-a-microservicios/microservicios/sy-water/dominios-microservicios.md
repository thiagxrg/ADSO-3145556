# 4 dominios reales para microservicios — save-your-water

Fuente: `code-sena/sy-water-docs`, corte 2026-09-22.

Este equipo ya hizo casi todo el trabajo: agrupó sus 11 bounded contexts en
6 servicios físicos, con dueño explícito por schema (`Owner:` en su propio
`06-data/models.md`). Los 4 dominios de abajo son esa misma agrupación,
quitando seguridad y fusionando los dos servicios más pequeños.

---

## 1. Lugares y Dispositivos — `place-service` + `device-service` fusionados

**Tablas:** `places.places`, `places.place_members`, `places.invitations`,
`devices.devices`, `devices.device_link_history`.

**Por qué se fusionan:** ambos son BC "Supporting" en la clasificación del
propio equipo, de baja frecuencia de escritura (alta de una vivienda, alta de
un dispositivo), y un dispositivo no tiene sentido sin un lugar al que
vincularse — están acoplados por diseño desde el primer día.

**Eventos que publicaría:** `PlaceCreated`, `MemberInvited`, `DeviceLinked`,
`DeviceUnlinked`.

---

## 2. Consumo y Facturación — `consumption-service`

**Tablas:** `monitoring.readings`, `monitoring.consumption_hourly/daily/monthly`,
`goals.consumption_goals`, `goals.goal_suggestions`, `billing.water_bills`,
`billing.tariffs`.

**Por qué ya vienen fusionados en el diseño original:** el propio equipo le
puso el mismo `Owner: consumption-service` a Monitoreo (Core), Metas
(Supporting) y Facturación (Supporting) — reconocieron que las tres viven del
mismo dato base (litros consumidos) y no se benefician de estar en servicios
separados.

**Por qué es el dominio Core:** `monitoring.readings` es, con enorme
diferencia, la tabla de mayor volumen de escritura del sistema — el propio
equipo ya lo anota en su modelo ("Highest write-volume table. Partition by
recorded_at when exceeding ~50M rows").

**Eventos que publicaría:** `ReadingRecorded`, `GoalExceeded`,
`BillGenerated`.

---

## 3. Control de Válvula — `valve-service`

**Tablas:** `valve.valve_states`, `valve.valve_commands`, `valve.valve_rules`.

**Por qué es un dominio propio — el más justificado de los cuatro:** es el
único dominio que actúa sobre el mundo físico (abrir/cerrar una válvula real)
en vez de solo leerlo. Su máquina de estados
(`PENDING_CONFIRMATION → CONFIRMED → SENT → ACK_SUCCESS | ACK_TIMEOUT`, ya
documentada por el equipo) tiene requisitos de confiabilidad y de tiempo
real que ningún otro dominio comparte — un timeout de confirmación de
dispositivo no debería competir por recursos con un reporte de facturación
mensual.

**Eventos que publicaría:** `ValveCommandIssued`, `ValveCommandAcked`,
`ValveCommandTimedOut`.

---

## 4. Alertas y Notificaciones — `notification-service`

**Tablas:** `alerts.alert_events`, `alerts.notification_preferences`,
`notifications.notification_log`, `notifications.push_subscriptions`,
`content.savings_tips`, `content.tip_favorites`.

**Por qué ya vienen fusionados en el diseño original:** mismo criterio que
Consumo y Facturación — Alertas (Core), Notificaciones (Generic) y
Consejos de ahorro (Generic) comparten el mismo `Owner: notification-service`
porque las tres son, en esencia, "avisarle algo a alguien por algún canal".

**Eventos que publicaría:** `AlertRaised`, `NotificationSent`,
`NotificationDelivered`.

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| Schema `security` completo (7 tablas) | `auth-service` — ya es su propio bounded context (BC-01 IAM) en el diseño del equipo |
| `billing.tariff_catalog` | Catálogo de tarifas públicas de referencia por país/región, marcado *Entrega 4 — Could* — parametrización, no negocio propio de la app |
| `alerts.alert_type_config` | Catálogo de tipos de alerta con seed data fija (severidad, límites) — parametrización |
| `BC-10 Reports & Export` | El propio equipo aclara que no tiene tablas propias: lee de `monitoring` |
