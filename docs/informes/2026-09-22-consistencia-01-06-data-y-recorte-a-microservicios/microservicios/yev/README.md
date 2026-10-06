# your-event — ⚠️ reconstruido desde una instantánea, no desde el modelo oficial

**Antes de leer `modelo-3fn.sql` y `dominios-microservicios.md`: esto no es
un recorte directo del modelo de datos del equipo, porque el modelo de
datos del equipo no vive en `yev-docs`.**

Verificado el 2026-09-22: `06-data/models.md` —el archivo que el framework
espera como fuente de verdad— sigue siendo la plantilla sin diligenciar
(`[table_name]`, `[field1]`...), igual que `01-context/overview.md`,
`01-context/scope.md`, `02-domain/domain-events.md` y
`02-domain/entities-and-rules.md`. Este hallazgo ya estaba documentado en
el informe de consistencia del 2026-09-22
(`adso-3145556-consistencia-01-06-2026-09-22/`).

## De dónde sale entonces este recorte

De `06-data/evidence/models.md`, una carpeta que el equipo agregó por su
cuenta, fuera de la estructura que el framework espera. Es real y
sustancial —13 módulos, más de 60 tablas con su propósito y sus columnas
clave— pero es una **instantánea resumida, no DDL completo**: describe cada
tabla en prosa con sus campos más importantes, no con `CREATE TABLE`
completo. `modelo-3fn.sql` reconstruye una estructura relacional plausible
a partir de esa descripción; los tipos y columnas que no estaban
explícitos en la evidencia se completaron con criterio razonable y quedan
marcados como tales en los comentarios del propio SQL.

**El propio documento de evidencia admite que la fuente real está en otro
lugar:** cita expresamente un diagrama ER, un diccionario de datos y
scripts SQL dentro de `TuEvento-Docs/05_Diseno_Software/` — un repositorio
que no es `yev-docs` y no es verificable desde la organización
`code-sena`. Cualquier decisión de este paquete debería confirmarse contra
esa fuente antes de construir sobre ella.

## Un hallazgo que se encontró al reconstruir el modelo

La evidencia describe `event_rating` (módulo Event, "calificaciones de
asistentes al evento") y `review` (módulo Profile, "calificaciones... de
usuarios a eventos") como dos tablas separadas con el mismo propósito. Se
modelaron aquí como una sola (`event_reviews`) — es una señal más de que
esta carpeta mezcla iteraciones del diseño sin reconciliar entre sí.

## Por qué conviene este ajuste, si el equipo retoma el proyecto desde aquí

**Boletería y Asientos es el único dominio de los cuatro con un problema
real de concurrencia** — vender el mismo asiento dos veces es el tipo de
error que un monolito compartido facilita y un servicio con su propio
control de bloqueo evita. La propia evidencia ya lo señala como crítico
para "el selector en tiempo real (SockJS)".

**Pagos y Billetera necesita aislarse por la misma razón que en cualquier
sistema que mueve dinero real:** los webhooks de la pasarela (Wompi)
exigen idempotencia (`transaction_webhooks.payload`), y ese nivel de
cuidado no debería compartir base de datos con el catálogo de eventos.

## Cómo se decidió qué excluir

- **Módulo Security (15 tablas):** `user`, `role`, `permission`,
  `auth_session`, `refresh_token`, `organizer_petition`,
  `account_lockout`... — ya es su propio servicio (`auth-service`) según
  la propia evidencia.
- **Personalización de interfaz:** `theme`, `user_theme`,
  `theme_customization`, `theme_log`, `language` — preferencia de usuario,
  no negocio de venta de boletos. Las tablas de traducción de **contenido**
  (`event_translations`, `category_translations`, `profile_translations`)
  sí se conservaron: no son parametrización, son el evento mismo en otro
  idioma.

## Qué haría falta para que esto deje de ser una reconstrucción

Que el equipo llene `02-domain/entities-and-rules.md` y `06-data/models.md`
con su propio diseño real, o que traiga el contenido de `TuEvento-Docs` a
un lugar verificable dentro de `code-sena`. Mientras la fuente de verdad
viva fuera de `yev-docs`, cualquier análisis hecho desde aquí —incluido
este— es una reconstrucción, no una auditoría.
