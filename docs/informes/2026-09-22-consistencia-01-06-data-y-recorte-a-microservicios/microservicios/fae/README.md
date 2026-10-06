# faceattend-edu — propuesta de recorte a microservicios

**Qué hay en esta carpeta**

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN — sin IAM/seguridad ni catálogos de pura parametrización |
| `dominios-microservicios.md` | Los 4 dominios reales propuestos, con sus tablas, eventos y justificación |

Fuente: `code-sena/fae-docs`, corte 2026-09-22.

## Por qué conviene este ajuste, específicamente para este proyecto

**El motor de base de datos ya obliga a esta separación — el resto del
modelo debería seguir el mismo criterio.** El equipo ya decidió que Biométrico
vive en MongoDB porque el dato (vectores de tamaño variable) no cabe bien en
una fila relacional. Esa misma lógica —"sepárese cuando el patrón de acceso o
el motor lo piden, no solo cuando el negocio lo pide"— es la que justifica
separar también Asistencia (escritura constante durante cada sesión de
clase) de Gestión Académica (CRUD administrativo, cambia por periodo).

**Es el modelo más grande de los 10 proyectos de la ficha (29 entidades) sin
un documento de normalización propio.** Con ese volumen, cualquier cambio de
esquema en un dominio de bajo riesgo (ej. agregar un campo a `courses`) hoy
implica correr una migración sobre el mismo esquema que también sirve
`attendance_records` — el dato más sensible y de más movimiento del sistema.
Separar en 4 servicios acota el radio de cada migración a un dominio a la
vez.

**Se corrigió una clasificación real, no solo el recorte.**
`biometric_update_cases` —el flujo de re-enrolar una huella o un rostro, con
solicitud y revisión— estaba archivado junto a configuración genérica de
nombre/valor. Es lógica de negocio real del dominio Biométrico, y quedarse
ahí la deja invisible para cualquiera que busque entender ese flujo. Moverla
es gratis ahora; sale más caro después de que el código dependa de esa
ubicación.

**Asistencia queda protegida de que un cambio en Programación de Clases la
tumbe.** Hoy, si `schedule_blocks` necesita una migración de esquema, el
mismo despliegue puede afectar la tabla que registra si un estudiante llegó
o no a clase. Separando los dos dominios, un ajuste al horario nunca
interrumpe el registro de asistencia que ya está en curso.

## Cómo se decidió qué excluir

- **Identity + Authorization (9 tablas):** `city`, `person`, `app_user`,
  `user_session`, `password_policy`, `role`, `permission`,
  `role_permission`, `user_role` — seguridad, ya es su propio bounded
  context en el diseño del equipo.
- **Parametrización pura:** `academic_configuration`,
  `security_configuration` (pares nombre/valor genéricos), `alert_type`
  (catálogo id+nombre).
- **Se conservaron** `academic_actor_types` y `justification_types` aunque
  parezcan catálogos: el primero decide quién puede ser instructor de un
  bloque; el segundo decide si una justificación exige un documento adjunto
  — ambas son reglas de negocio, no etiquetas.
