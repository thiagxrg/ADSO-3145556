# Informe de consistencia 01→06-data — ADSO-3145556

**Fecha de corte:** 2026-09-22 · **Ficha:** ADSO-3145556 · **Org GitHub:** `code-sena`
**Alcance:** los 10 repos `{prefijo}-docs` (uno por proyecto/subteam), secciones
`01-context`, `02-domain`, `03-product`, `04-requirements` frenteadas contra `06-data`.

---

## 1. Método

Cada repo fue clonado en un snapshot local de solo lectura (no se escribió nada en GitHub).
Para cada equipo se extrajo, por nombre y no solo por conteo:

- **Entidades** declaradas en `02-domain/entities-and-rules.md` (o su equivalente de
  plantilla propia) y **Value Objects**.
- **Bounded Contexts** declarados en `02-domain/domain-map.md`.
- **Microservicios** nombrados en `01-context/overview.md` y en `02-domain/domain-map.md`.
- **Tablas** en `06-data` — ya sea `CREATE TABLE` (SQL), notación DBML (`Table x { ... }`,
  usada por `ea-control` y `trans-sl`), o encabezados `### Table: `.
- **Historias de usuario** (HU) en `04-requirements`.
- El propio `06-data/normalization-assessment.md` cuando el equipo lo escribió (5 de 10 lo
  hicieron), leído íntegro y contrastado contra `models.md`.
- **Actividad real**: commits al repo `-docs` excluyendo el commit inicial de scaffold
  (`feat: apply microservices-governance-framework scaffold`, autor `ariel5253`), que es la
  plantilla del framework, no aporte del equipo — mismo criterio que
  `ficha-3145556-punta-a-punta-2026-09-15`.

**Límite del método:** la extracción de nombres es automática (regex sobre Markdown/SQL/DBML);
los 10 casos límite que produjo se verificaron a mano leyendo el archivo fuente antes de
reportarlos como hallazgo. Donde el método daba una señal ambigua (ver `vehicle-w`, `Rating`)
se dice explícitamente que es una lectura, no un hecho binario.

---

## 2. Semáforo ejecutivo

| Equipo | Commits reales¹ | Entidades 02-domain | Tablas 06-data² | Bounded Contexts | HU | Normalización declarada | Estado |
|---|---:|---:|---:|---:|---:|---|---|
| **edu-air-control** | 76 | 7 | 38 | 6 | 18 | 1NF mencionada en prosa; sin veredicto explícito | 🟡 Rico pero con núcleo de negocio en modelo DBML separado del resto |
| **energy-monitor** | 92 | 25 | 25 | 6 | 11 | **3NF, sin excepciones** (assessment propio, el más limpio) | 🟢 Ejemplar |
| **faceattend-edu** | 11 | 29 | 30 | 8 | 39 | Sin assessment propio | 🟢 Modelo rico, poco commiteado |
| **rent-car** | 35 | 25 | 26 | 7 | 32 | **3NF + 2 denormalizaciones documentadas** (con revisión de instructor registrada) | 🟢 Ejemplar |
| **save-your-water** | 32 | 16 | 31 | 11 | 59 | 3NF con 4 denormalizaciones documentadas (D1–D4), sin assessment.md dedicado | 🟢 Sólido |
| **school-guardian** | **0** | 0 (plantilla) | 0 (plantilla) | 0 (plantilla) | 0 real | — | 🔴 **Vacío. Un solo commit en toda la vida del repo: el scaffold.** |
| **translates-sign-language** | 10 | 16 | 29 | 8 | 53 | **3NF + BCNF, 4 denormalizaciones**, la más rigurosa (se autocritica) | 🟢 Ejemplar |
| **vehicle-washing** | 37 | 10 | 43 | 9 | 21 | 3NF, denormalizaciones bien razonadas | 🟢 Sólido, con 2 términos que no cruzan a 06-data |
| **woman-alert** | 21 | 27 | 27 | 7 | 16 | 3NF tabla por tabla (mecánico; confunde FK nulable con denormalización) | 🟡 Completo pero superficial en el razonamiento |
| **your-event** | 10 | 0 (plantilla) | 2–3 (plantilla) | 0 (plantilla) | 30³ | — | 🔴 **06-data es plantilla sin diligenciar; el modelo real vive fuera de este repo** |

¹ Excluye el commit único de scaffold del instructor.
² Nombres distintos de tabla (una tabla citada en dos esquemas/archivos cuenta una vez).
³ Las 30 HU de `your-event` no están en `04-requirements/user-stories.md` (plantilla vacía)
sino en `04-requirements/evidence/user-stories.md`, una instantánea aparte — ver §4.10.

**2 de 10 equipos (20 %) no tienen un modelo de datos real en el repo oficial.** Los otros 8
sí, con calidad muy despareja: desde autocrítica de nivel de posgrado (`trans-sl`) hasta un
repo que nadie tocó después del scaffold (`sg`).

---

## 3. Consistencia 01 → 02 → 06: patrón transversal antes del detalle por equipo

Antes de ir equipo por equipo, dos patrones aparecen en más de un proyecto y conviene
nombrarlos una sola vez:

### 3.1 Los microservicios casi nunca se nombran en `01-context`

De los 10 equipos, **solo `edu-air-control` nombra microservicios explícitamente en
`01-context/overview.md`** (tabla "Main architecture"). Los otros 9 dejan esa decisión
completamente a `02-domain/domain-map.md`, sin una tabla equivalente en `01-context`. Esto no
es necesariamente un error — el framework no exige que `01-context` baje a ese nivel de
detalle — pero sí es una asimetría real entre proyectos: en 9 de 10, si alguien solo lee
`01-context` no sabe cuántos servicios hay ni cómo se llaman.

### 3.2 Donde sí se nombran dos veces, los nombres no coinciden

`edu-air-control` es el único caso verificable, y falla:

| Servicio (según `01-context/overview.md`) | Servicio equivalente en `02-domain/domain-map.md` |
|---|---|
| `ms-usuarios` | `ms-security` **y** `ms-usuarios` (el context map separa IAM en dos) |
| `ms-aulas` | `ms-classroom-management` |
| `ms-sensores` | `ms-sensor-management` |
| `ms-monitoreo` | `ms-environment-monitoring` (y `ms-alert`, que `01-context` no menciona en absoluto) |

Cuatro de seis servicios de `01-context` reciben un nombre distinto en `02-domain`, mezclando
español (`ms-aulas`, `ms-sensores`, `ms-monitoreo`) con inglés (`ms-classroom-management`,
`ms-sensor-management`, `ms-environment-monitoring`) para referirse exactamente al mismo
servicio. Y `ms-alert`, que sí existe como bounded context y sí tiene tabla en `06-data`
(`alert_status`, `environment_alert`), no aparece nombrado en `01-context` en absoluto.

### 3.3 Deriva de nombres entre `02-domain` y `06-data` (no solo dentro de un mismo documento)

En `vehicle-washing`, el entity `Booking` de `02-domain/entities-and-rules.md` —descrito
literalmente como *"the central transaction of the whole platform"*— nunca aparece como
`booking` en `06-data`. Se llama `reserve` / `reserve.reserve_service`. Es el mismo patrón
de §3.2 pero cruzando de dominio a datos en vez de dentro de `01-context`: el vocabulario que
el propio framework llama *Ubiquitous Language* no es, en la práctica, único.

---

## 4. Detalle por equipo

### 4.1 edu-air-control (`ea-control-docs`) — 76 commits reales

**7 entidades** (`User`, `EducationalEnvironment`, `EnvironmentData`,
`EnvironmentalDataAnalysis`, `Sensor`, `Variable`, `VariableThreshold`) sobre **6 bounded
contexts** (IAM, Monitoring, Data Analysis, Classrooms, Sensors, UX).

`06-data` tiene **38 tablas**, pero repartidas de forma desigual: el núcleo de negocio
(`environment_measurement`, `environmental_analysis`, `analysis_result`, `sensor_installation`,
`variable_threshold`…) está descrito en **notación DBML** dentro de
`06-data/domain/ms-environment-monitoring.md`, mientras que IAM/Alert/Classroom/UX usan
`CREATE TABLE` SQL explícito en archivos separados. Ambas notaciones son válidas, pero el
propio repo no las trata igual: solo las tablas SQL tienen sección de "Data dictionary" y
"Modeling decisions" a su lado.

**Normalización:** no hay `normalization-assessment.md`. La única mención explícita de forma
normal es una frase suelta en `ms-environment-monitoring.md`: *"[serían] atributos separados
en la misma fila de la tabla, porque eso violaría el principio de 1NF"* — es decir, se razona
en el momento pero no se documenta como decisión, a diferencia de los 5 equipos que sí tienen
el archivo dedicado.

**Consistencia 01→02:** ver §3.2 — la única inconsistencia de nombres de microservicio
verificable de los 10 equipos, precisamente porque es el único que se atreve a nombrarlos dos
veces.

**Trazabilidad 04→06:** de las 7 entidades, la matriz de trazabilidad de requisitos solo cita
por nombre a `User`, `Sensor` y `Variable`. `EnvironmentData` y `EnvironmentalDataAnalysis`
—el corazón del producto— no aparecen citadas ahí, aunque sí tienen HU dedicadas en prosa.

### 4.2 energy-monitor (`en-monitor-docs`) — 92 commits reales

**25 entidades**, **25 tablas**, correspondencia 1:1 casi perfecta entre ambas listas (ninguna
entidad de dominio se queda sin tabla evidente — el único caso de los 10 equipos con calce
completo). 6 bounded contexts, 11 HU (`HU1`–`HU10`, funcionales y no funcionales, más una
referencia cruzada).

**Normalización — la más limpia de las 10.** Su `normalization-assessment.md` no reclama una
tabla de denormalizaciones para parecer completo: dice explícitamente *"as of this writing, the
schema has no intentional denormalization — every table is in 3NF. This is stated plainly
rather than manufactured content to fill the section"*. Verifica 1NF, 2NF y 3NF con ejemplos
reales de su propio esquema (`user_system_role` como tabla puente en vez de una columna
`roles` con lista separada por comas; `home_type_id` en vez de repetir el nombre del tipo en
cada `home`). Incluso distingue con precisión una decisión que **parece** denormalización y no
lo es (la FK cross-context de `alert.home_id` no reforzada a nivel de motor) de una que sí
sería denormalización si se hiciera (cachear `home_name` en `alert`) — y deja escrito qué
requeriría documentar si algún día se hace.

**Consistencia:** sin microservicios nombrados en `01-context` (§3.1), por lo que no hay nada
que cruzar contra `02-domain` ahí. Entidad↔tabla: perfecta.

### 4.3 faceattend-edu (`fae-docs`) — 11 commits reales

**29 entidades** — el segundo modelo más grande del conjunto — organizadas en **8 contextos**
numerados (`## 1. Identity` … `## 8. Configuration`; el repo no usa el encabezado estándar
`### Bounded Context:`, sino su propia convención "Entity Map by Context"). 30 tablas en
`06-data`, con calce casi total: solo `Facial_Embedding` y `Fingerprint_Embedding` (contexto
Biométrico) no tienen tabla evidente por nombre — señal a confirmar a mano, ya que datos
biométricos a veces se modelan fuera del RDBMS relacional por diseño, no por omisión.

**Sin `normalization-assessment.md` propio.** Con 39 HU y un modelo de 29 entidades sin
documento de normalización dedicado, es el equipo con más superficie de datos sin ese control
de calidad — aunque el propio `06-data/models.md` sigue plantilla sin diligenciar según el
detector automático (ver nota⁴), lo cual contradice el volumen real de contenido que sí tiene
en los archivos por dominio (`domains/01-identity.md` … `08-configuration.md`): el archivo
`models.md` central es efectivamente un resumen no completado, mientras el detalle real vive
en los archivos hijos.

⁴ Once commits para 30 tablas + 39 HU es un ritmo de "pocos commits grandes", coherente con lo
que se ve en `trans-sl` (§4.7): puede ser trabajo hecho fuera de git y subido de una vez, no
necesariamente menor esfuerzo real.

### 4.4 rent-car (`rtm-docs`) — 35 commits reales

**25 entidades**, **26 tablas**, calce perfecto. **7 bounded contexts**, 32 HU.

**Normalización — el único de los 10 que documenta una revisión externa real.** Su
`normalization-assessment.md` narra un proceso: *"an instructor's normalization pass over
`Mer.dbml` proposed several changes: some were adopted, some were rejected with a documented
reason, one was adopted then reverted"*. Ejemplos concretos:
- **1NF corregida:** `branch.schedules` (un varchar libre tipo `"Mon-Fri 8am-6pm"`) se separó
  en `branch_operating_hour` (una fila por día).
- **3NF corregida:** `category_id`/`engine_type_id` se movieron de `vehicle` a `vehicle_model`
  porque son propiedades del modelo, no de la unidad física.
- **Rechazada con razón:** convertir cada `status` en tabla catálogo — rechazado porque esos
  estados son máquinas de estado que controla el código, no datos editables por un Admin.
- **Denormalización intencional documentada:** 4 FKs nulables en `notification`
  (`reservation_id`/`invoice_id`/`payment_id`/`maintenance_id`) en vez de una FK polimórfica,
  porque SQL Server no puede validar integridad referencial de una FK polimórfica.

Es, junto con `trans-sl`, el ejemplo de que "documentar denormalización" no es llenar una
tabla — es explicar qué se consideró y por qué se descartó.

### 4.5 save-your-water (`sy-water-docs`) — 32 commits reales

**16 entidades** sobre **11 bounded contexts** (`BC-01` a `BC-11`, con `BC-10` marcado
explícitamente como "no tiene tablas, lee de `monitoring`" — consistencia interna correcta:
si un contexto no tiene tablas, el propio documento lo dice, no lo deja implícito). **31
tablas**, calce entidad↔tabla completo (los "sin tabla evidente" que reporta el detector
automático son falsos positivos: la entidad se llama `Goal *(Entrega 2)*` y la tabla
`goals.consumption_goals` — el sufijo de entrega rompe el emparejamiento automático por texto,
no hay hueco real).

**No tiene `normalization-assessment.md` dedicado**, pero sí una tabla de 4 denormalizaciones
documentadas al inicio de `models.md` (`D1`–`D4`), con motivo declarado para cada una (ej.
`D1`: `place_id` duplicado en `monitoring.readings` "para evitar JOIN a devices en cada
consulta de lectura"). Es un assessment real, solo que integrado en `models.md` en vez de en
archivo propio — no debería contarse como ausencia de análisis, solo como ausencia del archivo
esperado por convención.

### 4.6 school-guardian (`sg-docs`) — 0 commits reales

**Este es el hallazgo más severo del informe.** El repo tiene **un solo commit en toda su
historia**, y es el scaffold del instructor (`ariel5253`, 2026-08-25). El equipo
(`Juan-Chala-123`) no ha hecho ni un commit desde entonces.

Verificado archivo por archivo, no solo por conteo: `01-context/overview.md`,
`01-context/glossary.md`, `02-domain/domain-map.md`, `02-domain/entities-and-rules.md`,
`03-product/vision.md`, `04-requirements/user-stories.md` y `06-data/models.md` conservan
literalmente el texto de plantilla —`[System Name]`, `[Role 1]`, `### Bounded Context: [Name —
e.g.: User Management]`, `### HU-00X — [Name]`— sin un solo reemplazo. Las "HU-001" y "HU-002"
que cita `traceability-matrix.md` son los ejemplos ilustrativos de la propia plantilla, no
historias reales del proyecto.

El repo hermano `sg-db` tampoco tiene contenido: un commit ("Initial commit") con solo un
`README.md`.

**No hay nada que frentear.** No hay entidades, no hay tablas, no hay bounded contexts reales
contra los cuales medir consistencia — la ficha "0 RAP calificados" que ya se había detectado
en el reporte de juicios de esta ficha tiene aquí su correlato exacto en el repo de este
proyecto.

### 4.7 translates-sign-language (`trans-sl-docs`) — 10 commits reales

**16 entidades** sobre **8 bounded contexts**, con el detalle más cuidado de anotación de
versión de los 10 repos (marca qué es nuevo en v1.1, qué se movió de contexto en v1.2, qué
está "on hold" ⏸ pendiente de un RF). **57 referencias de tabla brutas → 29 tablas distintas**
(la duplicación viene de tener tanto un `.dbml` completo como archivos `domains/*.md` con el
mismo esquema — es el único repo con ambas representaciones a la vez).

**Normalización — el análisis más riguroso de los 10, con autocrítica real.** Reclama 1NF,
2NF, 3NF **y BCNF**, y documenta 4 denormalizaciones con el mismo nivel de detalle que
`rent-car`, pero va un paso más allá en dos puntos que ningún otro equipo hace:

1. **Señala su propia inconsistencia:** *"`usage_daily_stats`, `session_daily_stats`... they
   also currently contradict the domain map — DATA-03"*, con enlace a un archivo
   `open-items.md` donde queda registrado el pendiente. Es el único equipo de los 10 que deja
   escrito, dentro del propio `06-data`, un hueco de consistencia consigo mismo en vez de
   dejarlo para que lo encuentre un tercero.
2. **Encuentra un bug real de agregación:** la columna `unique_users` de sus tablas de rollup
   no es sumable entre secciones/días sin contar dos veces al mismo usuario, y lo documenta
   como *"a plausible, wrong number that nobody notices"*, con dos salidas posibles (recalcular
   desde el evento crudo, o usar un sketch HLL mergeable).

**Consistencia 01→04:** las HU citan por nombre a `Category`, `PasswordPolicy`,
`NotificationType`/`Notification`, `Sign`/`SignLocalization`, `Translation`, `User` — buena
cobertura de trazabilidad para un modelo de 16 entidades.

### 4.8 vehicle-washing (`vehicle-w-docs`) — 37 commits reales

**10 entidades** de alto nivel en `02-domain` que se despliegan en **43 tablas distintas** en
`06-data` (9 bounded contexts, 8 esquemas SQL Server) — la relación entidad:tabla más alta de
los 10 equipos (≈1:4), coherente con un dominio transaccional (reservas, pagos, lealtad) donde
cada entidad de negocio se apoya en varias tablas de catálogo/estado.

**Normalización sólida**, con el mismo estilo de razonamiento por trade-off que `rent-car`:
explica por qué `catalog.service` no tiene columna `price` (depende del par
servicio+tipo-de-vehículo, no del servicio solo), por qué `execution.operator` no duplica
`person_id` aunque sea alcanzable en un solo salto (evitar una segunda ruta a la misma
verdad), y documenta 4 denormalizaciones intencionales con su mecanismo de honestidad (ej. el
saldo de puntos de lealtad se cachea, pero cada movimiento guarda `balance_after` para poder
reconciliar).

**Dos términos que no cruzan limpio a `06-data`** (ver también §3.3):
- **`Booking` (dominio) = `reserve` (datos).** Mismo concepto, nombre distinto documento a
  documento.
- **`Rating` es una entidad propia en `02-domain`** (con su propio agregado e invariante
  "como máximo una calificación por booking completado"), **pero en `06-data` no existe una
  tabla `rating`**: se modela como tres columnas (`quality_rating`, `quality_comment`,
  `rated_at`) sobre `execution.service_execution`. Es una decisión defendible — una
  calificación no tiene existencia propia fuera del servicio que califica— pero es una
  simplificación real entre el modelo táctico (que la trata como Entity/Aggregate) y el modelo
  físico (que la trata como atributo), y no está señalada como decisión en ningún documento de
  los que se leyeron.

### 4.9 woman-alert (`wal-docs`) — 21 commits reales

**27 entidades**, **27 tablas**, calce perfecto — el modelo más grande en número de entidades
de los 10 equipos. 7 bounded contexts, 16 HU.

**Normalización — completa pero mecánica.** Su `normalization-assessment.md` (338 líneas) pasa
tabla por tabla afirmando 3NF con la misma fórmula repetida ("Primary key: `id`... All
attributes depend on `id`... Correctly normalized") en las 12 tablas revisadas, sin el nivel de
razonamiento de trade-off que sí tienen `rent-car`, `vehicle-washing` o `trans-sl`.

Hay un **error conceptual que vale la pena señalar porque se repite tres veces**: el documento
llama "denormalización intencional" a tener una **FK nulable** (`alert_id` nulable en
`location_log` y en `notification`, para permitir el caso sin alerta activa). Una FK nulable no
es una denormalización — es simplemente una relación opcional, y no implica ningún dato
duplicado ni dependencia transitiva. Es una confusión de terminología, no un problema real del
esquema: el esquema subyacente que describe está probablemente bien, pero la justificación
técnica que da para ello es incorrecta tal como está escrita.

### 4.10 your-event (`yev-docs`) — 10 commits reales

**El otro caso severo, distinto al de `school-guardian`.** El detector automático confirma que
`01-context/overview.md`, `01-context/scope.md`, `02-domain/domain-events.md`,
`02-domain/entities-and-rules.md` y `06-data/models.md` —los archivos canónicos que definen
esta plantilla— **siguen siendo la plantilla sin diligenciar** (mismo patrón de corchetes
`[EntityName]`, `[Name — e.g.: User Management]` que en `sg-docs`).

Pero a diferencia de `school-guardian`, sí hay contenido real: vive en una carpeta paralela
`.../evidence/` (`01-context/evidence/`, `02-domain/evidence/`, `03-product/evidence/`,
`04-requirements/evidence/`, `06-data/evidence/`) que el equipo agregó por su cuenta, fuera de
la estructura que el framework espera. Las 30 HU reales de este informe salen de
`04-requirements/evidence/user-stories.md`, no del archivo canónico.

**El detalle que rompe la trazabilidad por completo:** `06-data/evidence/models.md` declara
explícitamente que su fuente primaria son scripts SQL, un diagrama ER y un diccionario de
datos Excel que viven en **`TuEvento-Docs/05_Diseno_Software/...`** — un repositorio que **no
es `yev-docs`** y no está enlazado ni referenciado desde ningún punto verificable de este repo
como parte de la org `code-sena`. En la práctica, el modelo de datos real de `your-event` no es
auditable desde el repositorio que la ficha usa como fuente de verdad para este ejercicio.

---

## 5. Ranking de normalización (solo los 8 equipos con modelo real)

| # | Equipo | Veredicto | Por qué en ese lugar |
|---|---|---|---|
| 1 | **translates-sign-language** | 3NF+BCNF, autocrítico | Único que documenta su propia inconsistencia (DATA-03) y encuentra un bug real de agregación no pedido |
| 2 | **rent-car** | 3NF razonado | Única revisión externa (instructor) documentada con adopciones y rechazos explícitos |
| 3 | **energy-monitor** | 3NF sin excepciones | El más limpio: cero denormalización y lo dice sin necesidad de inflar la sección |
| 4 | **vehicle-washing** | 3NF razonado | Mismo nivel de trade-off que rent-car, con 2 términos sueltos de vocabulario (§4.8) |
| 5 | **save-your-water** | 3NF, 4 denormalizaciones | Buen análisis, pero integrado en `models.md` y no en documento propio |
| 6 | **woman-alert** | 3NF declarado, mecánico | Completo en cobertura, débil en el razonamiento; confunde FK nulable con denormalización |
| 7 | **edu-air-control** | Sin veredicto explícito | 1NF mencionada al pasar, sin documento dedicado, pese a tener 76 commits |
| 8 | **faceattend-edu** | Sin veredicto | Modelo grande (29 entidades) sin ningún control de normalización documentado |
| — | **school-guardian** | No aplica | No hay modelo |
| — | **your-event** | No aplica | El modelo declarado no vive en este repo |

---

## 6. Conclusiones transversales

1. **La actividad de commits no predice la calidad del análisis de datos.** `trans-sl` (10
   commits) y `rent-car` (35) están en el top del ranking de normalización; `edu-air-control`
   (76 commits) y `faceattend-edu` (11) no tienen veredicto de normalización pese a tener
   modelos grandes. Volumen de commits mide actividad, no cuidado.
2. **El patrón de "plantilla sin diligenciar" tiene dos variantes distintas** y conviene no
   tratarlas igual: `school-guardian` es inactividad total (0 commits reales); `your-event` sí
   trabajó, pero fuera de la estructura esperada y con la fuente de verdad en un repositorio
   externo no verificable desde aquí.
3. **La inconsistencia de nombres entre secciones es real pero puntual**, no generalizada: solo
   se pudo verificar donde el equipo se atrevió a nombrar la misma cosa dos veces
   (`edu-air-control` en `01`↔`02`; `vehicle-washing` en `02`↔`06`). La mayoría de equipos evita
   el problema no nombrando microservicios en `01-context` en absoluto (§3.1) — lo cual es su
   propio tipo de brecha de consistencia, solo que invisible al cruce automático.
4. **Los 5 equipos con `normalization-assessment.md` propio son, sin excepción, los que además
   tienen la trazabilidad entidad↔tabla más limpia** (`en-monitor`, `rtm`, `sy-water`,
   `vehicle-w`, `wal` — junto con `trans-sl` que también lo tiene). Escribir el documento de
   normalización parece forzar, como efecto colateral, una revisión del modelo que atrapa
   huecos de nomenclatura antes de que lleguen a este informe.

---

## Correlación con el reporte de juicios de la ficha

`school-guardian` (0 commits reales) es consistente con lo que ya mostraba el reporte de
juicios evaluativos de ADSO-3145556: es la misma ficha donde ya se había detectado que el
tablero, las HU y el ambiente no existen como dato real
(`ficha-3145556-punta-a-punta-2026-09-15`). Este informe confirma, desde el lado de los
repositorios de proyecto en vez de desde Sofía, la misma conclusión para ese equipo puntual.
