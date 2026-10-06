# 4 dominios reales para microservicios — energy-monitor

Fuente: `code-sena/en-monitor-docs`, corte 2026-09-22.

---

## 1. Gestión de Viviendas — `home-service`

**Tablas:** `homes`, `home_thresholds`, `user_homes`.

**Por qué es un dominio propio:** una vivienda y su relación con los usuarios
(quién es `OWNER`, quién es `MEMBER`, quién la marcó `favorite`) es
administración de baja frecuencia — se crea una vez, casi no cambia — y es el
dato "maestro" del que cuelgan Dispositivos y Monitoreo.

**Eventos que publicaría:** `HomeCreated`, `ThresholdUpdated`, `MemberAdded`.

---

## 2. Gestión de Dispositivos — `device-service`

**Tablas:** `devices`, `device_status_logs`, `device_homes`.

**Por qué es un dominio propio:** ciclo de vida de inventario IoT (alta,
vínculo a una vivienda, seguimiento de conectividad `ONLINE`/`OFFLINE`),
distinto del ciclo de vida de Monitoreo. El `api_key` de cada dispositivo es
además un dato sensible que conviene aislar en su propio servicio con su
propia política de acceso.

**Eventos que publicaría:** `DeviceLinked`, `DeviceWentOffline`,
`DeviceReconnected`.

---

## 3. Monitoreo y Alertas — `monitoring-service`

**Tablas:** `measurements`, `consumption_levels`, `alerts`.

**Por qué es el dominio Core, y por qué las alertas van aquí:** es la razón de
negocio del producto — sin medición no hay nada que monitorear. Una alerta se
genera al comparar una medición contra el umbral de `consumption_levels`: es
la misma operación de negocio, no dos servicios coordinándose por red. El
propio equipo ya lo modeló así (`alerts.consumption_level_id` es una FK
directa, no un evento).

**Por qué necesita ser su propio servicio:** `measurements` es, por lejos, la
tabla de mayor volumen de escritura de todo el sistema (una fila por
dispositivo por intervalo de muestreo). Ese patrón de escritura no tiene nada
que ver con el de Viviendas o Dispositivos, que son CRUD ocasional.

**Eventos que publicaría:** `MeasurementRecorded`, `ThresholdExceeded`,
`AlertRaised`, `AlertResolved`.

---

## 4. Recomendaciones — `recommendation-service`

**Tablas:** `recommendations`.

**Por qué es un dominio propio, aunque hoy sea una sola tabla:** el propio
equipo ya lo separó como bounded context distinto de Alertas en su
`domain-map.md`, y con razón — una recomendación (ej. "reduce el consumo del
refrigerador entre 2pm y 5pm") no es una regla de umbral, es un análisis de
patrón de consumo. Es el candidato natural para incorporar lógica más
sofisticada (reglas, luego quizá un modelo) sin arrastrar eso al servicio que
tiene que responder en tiempo real a cada medición.

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| IAM/seguridad (13 tablas) | Ya cubre su propio bounded context "Security" en el diseño del equipo |
| `home_type`, `appliance_type` | Catálogos id+nombre sin comportamiento propio |
