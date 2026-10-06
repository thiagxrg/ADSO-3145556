# school-guardian — ⚠️ no hay proyecto real del que partir

**Antes de leer `modelo-3fn.sql` y `dominios-microservicios.md`: lo que
sigue NO es un recorte del trabajo del equipo, porque no existe trabajo del
equipo.**

`code-sena/sg-docs` tiene **un solo commit en toda su historia** — el
scaffold del instructor (2026-08-25). Verificado archivo por archivo el
2026-09-22: `01-context/overview.md`, `02-domain/domain-map.md`,
`02-domain/entities-and-rules.md`, `03-product/vision.md`,
`04-requirements/user-stories.md` y `06-data/models.md` conservan
literalmente el texto de plantilla (`[System Name]`, `### Bounded Context:
[Name — e.g.: User Management]`, `### HU-00X — [Name]`) sin un solo
reemplazo. El repo hermano `sg-db` tampoco tiene contenido: un commit
("Initial commit") con solo un `README.md`. Este hallazgo ya estaba
documentado en el informe de consistencia del 2026-09-22
(`adso-3145556-consistencia-01-06-2026-09-22/`).

## Qué se entrega en su lugar

`modelo-3fn.sql` y `dominios-microservicios.md` en esta carpeta son una
**propuesta de línea base**, construida únicamente a partir de la
descripción declarada del repositorio en GitHub —*"school route management
and monitoring"*— y del sentido común del dominio (transporte escolar:
rutas, paradas, estudiantes, acudientes, seguimiento en tiempo real,
notificaciones). **No refleja ninguna decisión real del equipo**, porque el
equipo no tomó ninguna que quedara documentada.

Sirve como punto de partida si el equipo retoma el proyecto — no como
evaluación de lo que hicieron, porque no hicieron nada que evaluar en este
repositorio.

## Los 4 dominios propuestos (de cero)

1. **Rutas y Paradas** — el recorrido físico: qué rutas existen, en qué
   orden visitan sus paradas.
2. **Estudiantes y Acudientes** — quién viaja en qué ruta y quién es su
   contacto responsable.
3. **Seguimiento en Tiempo Real** — la posición del vehículo durante un
   recorrido específico de un día concreto.
4. **Notificaciones a Acudientes** — avisar cuándo el bus se acerca o llega.

Ver el detalle de tablas en `dominios-microservicios.md`.

## Qué haría falta para que esto deje de ser una propuesta

Que el equipo llene, con datos reales de su propio diseño, al menos
`02-domain/entities-and-rules.md` y `06-data/models.md`. Sin eso, cualquier
"recorte a microservicios" —incluido este— es necesariamente una
suposición, no un análisis.
