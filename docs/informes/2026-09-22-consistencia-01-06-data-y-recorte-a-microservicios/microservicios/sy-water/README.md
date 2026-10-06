# save-your-water — propuesta de recorte a microservicios

**Qué hay en esta carpeta**

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN — sin IAM/seguridad ni catálogos de pura parametrización |
| `dominios-microservicios.md` | Los 4 dominios reales propuestos, con sus tablas, eventos y justificación |

Fuente: `code-sena/sy-water-docs`, corte 2026-09-22.

## Por qué conviene este ajuste, específicamente para este proyecto

**Este es el único de los 10 proyectos de la ficha que ya diseñó sus
microservicios antes de escribir una sola tabla — el ajuste aquí es
formalizar lo que ya está implícito, no inventarlo.** Cada schema de su
`06-data/models.md` trae una línea `Owner: <servicio>` — el equipo ya sabía
que Monitoreo, Metas y Facturación viven en `consumption-service`, y que
Alertas, Notificaciones y Consejos viven en `notification-service`. Este
paquete simplemente documenta esa decisión como los 4 dominios que son en la
práctica, quitando seguridad de la cuenta.

**Control de Válvula es el caso más claro de todo el conjunto de la ficha
para justificar un servicio aparte.** Es el único dominio, de los 10
proyectos auditados, que actúa sobre hardware físico en tiempo real (abrir o
cerrar una válvula de agua) con una máquina de estados que incluye
`ACK_TIMEOUT` — un timeout de confirmación de dispositivo. Eso exige un
presupuesto de latencia y de reintentos que no tiene sentido compartir con
un reporte de facturación mensual, que puede tardar segundos sin que nadie
lo note.

**`monitoring.readings` ya está señalada por el propio equipo como el cuello
de botella de escritura del sistema.** Su comentario en el modelo original
— "Highest write-volume table. Partition by recorded_at when exceeding ~50M
rows" — es, en esencia, una nota que dice "esto va a necesitar su propia
infraestructura de escalamiento en algún momento". Aislarlo en
`consumption-service` (ya lo está, en el diseño original) permite que esa
partición ocurra sin tocar el servicio de válvulas o el de lugares.

**Se excluyeron dos catálogos que el equipo mismo etiquetó como "podría
esperar".** `billing.tariff_catalog` está marcado *Entrega 4 — Could* en su
propio backlog: es una tabla de tarifas públicas de referencia, no una
decisión de negocio propia de Save Your Water. Sacarla del núcleo del
dominio dejar más claro qué es negocio real y qué es un dato de apoyo
opcional.

## Cómo se decidió qué excluir

- **Seguridad (schema `security`, 7 tablas):** `users`,
  `user_credentials`, `email_verifications`, `password_resets`,
  `refresh_tokens`, `login_attempts`, `activity_log` — ya es
  `auth-service` en el diseño del equipo (BC-01 IAM).
- **Parametrización pura:** `billing.tariff_catalog` (tarifas públicas de
  referencia, *Entrega 4 — Could*), `alerts.alert_type_config` (catálogo de
  tipos de alerta con seed data fija).
- **`BC-10 Reports & Export`** no aparece en ningún dominio: el propio
  equipo documentó que no tiene tablas propias, solo lee de `monitoring`.
