# 4 dominios reales para microservicios — translates-sign-language

Fuente: `code-sena/trans-sl-docs`, corte 2026-09-22.

---

## 1. Reconocimiento y Traducción — `recognition-service` (Core)

**Tablas:** `ai.ai_models`, `translation.translations`,
`translation.translation_signs`.

**Por qué es el dominio Core:** el propio `domain-map.md` lo marca ⭐ CORE —
es la razón de negocio del producto: convertir una seña en texto o audio.

**Por qué `ai_models` va aquí y no se excluye como catálogo:** el propio
equipo ya distinguió esto en su `normalization-assessment.md`: *"storing the
id and joining for the version is normal form working correctly. Copying
the version string into translations would be the denormalization"* — es
decir, no es un catálogo decorativo, es la trazabilidad de qué modelo de IA
produjo cada traducción, dato crítico para poder reproducir o auditar un
resultado.

**Eventos que publicaría:** `TranslationRequested`, `TranslationCompleted`,
`ModelActivated`.

**Dependencia:** consume `sign_id` del dominio de Léxico para poblar
`translation_signs`.

---

## 2. Aprendizaje y Léxico — `lexicon-service`

**Tablas:** `lexicon.categories`, `lexicon.sign_lexicon`,
`lexicon.sign_localizations`, `lexicon.multimedia_resources`.

**Por qué es un dominio propio:** es contenido editorial (imágenes, videos,
nombres traducidos de cada seña) que un curador de contenido actualiza
manualmente — un ciclo de vida y un patrón de acceso totalmente distinto al
de Reconocimiento, que necesita responder en tiempo real a una cámara.

**Un matiz que el propio equipo ya documentó y vale la pena repetir:**
`sign_lexicon.code` (identificador estable, ej. `GREETING_HELLO`) y
`sign_localizations.name` (texto humano, "Hola"/"Hello") *parecen* el mismo
dato duplicado — no lo son. Fusionarlos sería el error, no separarlos:
agregar un idioma nuevo significaría reentrenar el reconocedor.

**Eventos que publicaría:** `SignPublished`, `SignLocalizationAdded`.

---

## 3. Analítica de Uso — `analytics-service`

**Tablas:** `usage_stats.usage_events`, `usage_stats.usage_daily_stats`,
`usage_stats.session_daily_stats`.

**Por qué es un dominio propio:** es el único de los cuatro que existe
puramente para reportar, no para operar — un fallo aquí no debería impedir
que alguien traduzca una seña. Su patrón de escritura (un evento por cada
clic/vista) y de lectura (agregados por un job nocturno) tampoco se parece a
nada de los otros tres dominios.

**Advertencia que viaja con estas tablas, no solo con el dominio:** la
columna `unique_users` de los dos rollups **no es aditiva** — sumarla entre
secciones o días cuenta dos veces al mismo usuario. Es el hallazgo más fino
que produjo el informe de consistencia del 2026-09-22 sobre esta ficha, y
sigue siendo cierto tras el recorte: cualquier microservicio que lea estas
tablas necesita conocer esta regla, no solo heredar la tabla.

**Eventos que consumiría:** todos los eventos de negocio de los otros tres
dominios (`TranslationCompleted`, `SignPublished`, etc.) para poblar
`usage_events`.

---

## 4. Perfil y Preferencias — `profile-service`

**Tablas:** `profile.user_preferences`.

**Por qué es un dominio propio, aunque hoy sea una sola tabla:** guarda
configuración de interfaz (idioma, tema, notificaciones) que no tiene
relación funcional con traducir señas — es infraestructura de UX, no de
reconocimiento. Separarlo evita que un cambio de preferencia de tema
comparta base de datos con el flujo de reconocimiento en tiempo real.

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| `identity.*` (6 tablas), `authz.*` (4 tablas) | Seguridad — ya es su propio bounded context |
| `notification.*` (3 tablas) | Generic, delgado, reacciona a eventos de los otros dominios — no justifica servicio propio |
| `gamification.*` (2 tablas) | El propio `domain-map.md` la marca ⏸ **provisional**, pendiente de RF8 — prematuro comprometer un dominio a algo que aún no se decide |
| `audit.*` (2 tablas) | Infraestructura transversal, no negocio |
