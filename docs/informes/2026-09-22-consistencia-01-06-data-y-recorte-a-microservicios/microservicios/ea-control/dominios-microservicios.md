# 4 dominios reales para microservicios — edu-air-control

Fuente: `code-sena/ea-control-docs` (`02-domain/domain-map.md`, `06-data/domain/*.md`),
corte 2026-09-22. Se excluyen del conteo IAM/seguridad (ya es, de hecho, su propio
servicio: `ms-security` + `ms-usuarios`) y los catálogos de parametrización pura.

---

## 1. Gestión de Espacios — `space-service`

**Responsabilidad:** campus, tipo de ambiente educativo, ambiente educativo.

**Tablas:** `campuses`, `environment_types`, `educational_environments`.

**Por qué es un dominio propio:** es el dato más estable del sistema — un campus o un
salón casi no cambia una vez creado — y lo consumen los otros tres dominios sin
necesitar saber cómo se administra. Cambia por trimestre académico, no por segundo
como el dominio de Monitoreo.

**Eventos que publicaría:** `EnvironmentCreated`, `EnvironmentDeactivated`,
`EnvironmentTypeChanged` (este último importa: le dice a Monitoreo que debe
reevaluar qué `variable_threshold` aplica).

---

## 2. Gestión de Sensores — `sensor-service`

**Responsabilidad:** inventario físico de sensores, qué variables mide cada uno,
en qué ambiente está instalado y desde cuándo.

**Tablas:** `sensors`, `variables`, `sensor_installations`, `sensor_variables`.

**Por qué es un dominio propio:** su ciclo de vida es de *inventario* (alta de
sensor, instalación, retiro), completamente distinto al ciclo de vida de
Monitoreo (ingesta continua de mediciones). Un sensor puede existir sin haber
emitido nunca una medición.

**Eventos que publicaría:** `SensorInstalled`, `SensorRemoved`, `SensorOffline`
(cuando `last_seen_at` se atrasa más de lo esperado).

**Dependencia:** consume `environment_id` de Gestión de Espacios (referencia
lógica, no FK física).

---

## 3. Monitoreo y Análisis Ambiental — `monitoring-service`

**Responsabilidad:** ingesta de mediciones, evaluación de umbrales, generación de
alertas y análisis histórico por periodo.

**Tablas:** `variable_thresholds`, `environment_measurements`,
`environmental_analyses`, `analysis_results`, `environment_alerts`.

**Por qué es un dominio propio — y por qué las alertas van aquí y no aparte:**
este es el dominio **Core** de todo el producto (así lo clasifica el propio
`domain-map.md`): es la razón de negocio de EduAirControl. Una alerta se genera
*directamente* de una medición cruzando un umbral — es la misma transacción de
negocio, no dos servicios distintos coordinándose. Separarlas obligaría a un
evento de red por cada medición que cruza un umbral, latencia que aquí no aporta
nada.

**Por qué merece ser su propio servicio y no vivir junto a Sensores:** el patrón
de carga es opuesto. Sensores es CRUD de baja frecuencia (altas/bajas de
hardware); Monitoreo es escritura de alta frecuencia (una fila por sensor por
variable por intervalo de muestreo) y lectura agregada pesada (análisis por
día/semana/mes/año). Escalar uno no debería forzar escalar el otro.

**Eventos que publicaría:** `MeasurementRecorded`, `ThresholdExceeded`,
`AlertRaised`, `AlertAcknowledged`, `AnalysisComputed`.

---

## 4. Experiencia de Usuario — `ux-service`

**Responsabilidad:** favoritos, calificaciones de ambientes, historial de
búsqueda y preferencias de interfaz por usuario.

**Tablas:** `user_preferences`, `favorites`, `classroom_ratings`, `searches`.

**Por qué es un dominio propio:** es el único dominio cuyo dato es *por usuario*
en vez de *por ambiente/sensor* — cambia el patrón de acceso (siempre se lee "lo
mío", nunca un reporte agregado de todos los usuarios) y su disponibilidad no es
crítica: si este servicio cae, Monitoreo sigue registrando mediciones sin
problema. Aislarlo evita que una funcionalidad secundaria (calificar un salón)
comparta presupuesto de rendimiento con la ingesta de mediciones.

**Dependencia:** consume `environment_id` de Gestión de Espacios y `user_id` de
IAM (ambas referencias lógicas).

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| IAM (`ms-security`, `ms-usuarios`) | Ya es su propio servicio en el diseño actual — no es parte de este ejercicio de identificar dominios *de negocio* nuevos |
| `sensor_models`, `sensor_statuses`, `measurement_units`, `alert_status` | Catálogos de valores fijos sin comportamiento propio; viven como tabla de referencia dentro del dominio que los usa, no justifican un servicio propio |
