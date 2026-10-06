# 4 dominios reales para microservicios — faceattend-edu

Fuente: `code-sena/fae-docs`, corte 2026-09-22.

---

## 1. Gestión Académica — `academic-service`

**Tablas:** `schools`, `programs`, `academic_periods`, `cohorts`, `courses`,
`academic_actor_types`, `academic_actors`, `enrollments`.

**Por qué es un dominio propio:** es el dato maestro más estable del sistema
— colegios, programas, cohortes, matrícula — y todo lo demás (horario,
asistencia) referencia a un `academic_actor`, nunca al revés. Cambia por
periodo académico, no por segundo.

**Eventos que publicaría:** `ActorEnrolled`, `CohortOpened`,
`AcademicPeriodClosed`.

---

## 2. Programación de Clases — `scheduling-service`

**Tablas:** `environments`, `schedule_blocks`, `class_sessions`.

**Por qué es un dominio propio:** define *cuándo y dónde* ocurre una clase —
un problema de calendario y disponibilidad, con sus propias reglas de
conflicto (¿puede un instructor dictar dos bloques que se cruzan?) que no
tienen nada que ver con matrícula ni con asistencia.

**Eventos que publicaría:** `SessionOpened`, `SessionClosed`.

---

## 3. Asistencia y Alertas — `attendance-service`

**Tablas:** `attendance_records`, `justification_types`, `justifications`,
`supporting_documents`, `alerts`.

**Por qué es el dominio Core:** es la razón de negocio del producto — registrar
asistencia por reconocimiento facial y avisar cuando el patrón lo amerita. Una
alerta de inasistencia nace directamente de los `attendance_records`
acumulados de un `academic_actor`; separarla en un quinto servicio solo
agregaría una llamada de red por cada registro de asistencia, sin beneficio.

**Por qué necesita ser su propio servicio:** es, con 39 historias de usuario,
el dominio con más superficie funcional de los cuatro — justificaciones con
adjuntos, flujo de revisión, alertas — y el único con datos verdaderamente
sensibles de asistencia diaria que conviene poder auditar y escalar aparte.

**Eventos que publicaría:** `AttendanceRecorded`, `JustificationSubmitted`,
`JustificationReviewed`, `AlertRaised`.

**Dependencia:** consume `match_score` calculado por el dominio Biométrico
al momento de registrar la asistencia.

---

## 4. Reconocimiento Biométrico — `biometric-service`

**Persistencia:** colecciones MongoDB `facial_embeddings` /
`fingerprint_embeddings` — vectores de tamaño variable, no tablas
relacionales — más una tabla SQL, `biometric_update_cases`.

**Por qué es un dominio propio — el más obvio de los cuatro:** es el único
que necesita un motor de base de datos distinto (documentos con vectores,
no filas relacionales) y una carga de cómputo distinta (comparar un vector
contra una plantilla es una operación de CPU/GPU, no una consulta SQL). Ya
está diseñado desde el principio para vivir aparte — el propio equipo lo dice
en `06-data/domains/06-biometric.md`: *"Biometric does NOT know Person"*.

**Un ajuste que sí se propone aquí:** `biometric_update_cases` (el flujo para
re-enrolar una huella o un rostro, con solicitud y revisión) vivía archivado
en la carpeta "Configuration" del equipo, junto a pares nombre/valor
genéricos sin relación alguna. Es un caso de negocio real de este dominio, no
parametrización — se reubica aquí.

**Eventos que publicaría:** `EmbeddingEnrolled`, `UpdateCaseRequested`,
`UpdateCaseResolved`.

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| Identity + Authorization (9 tablas: `person`, `app_user`, `user_session`, `role`, `permission`...) | Seguridad — ya es su propio bounded context en el diseño del equipo |
| `academic_configuration`, `security_configuration` | Pares nombre/valor genéricos sin lógica propia |
| `alert_type` | Catálogo id+nombre sin comportamiento propio |
| `city` | Catálogo geográfico genérico referenciado por `schools` |
