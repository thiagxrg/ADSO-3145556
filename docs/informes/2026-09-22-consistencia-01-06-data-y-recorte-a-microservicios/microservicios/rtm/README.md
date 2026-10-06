# rent-car — propuesta de recorte a microservicios

**Qué hay en esta carpeta**

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN — sin IAM/seguridad ni auditoría transversal |
| `dominios-microservicios.md` | Los 4 dominios reales propuestos, con sus tablas, eventos y justificación |

Fuente: `code-sena/rtm-docs`, corte 2026-09-22.

## Por qué conviene este ajuste, específicamente para este proyecto

**Este es el equipo con el análisis de datos más maduro de los 10 proyectos
de la ficha — el ajuste que falta es organizacional, no de modelado.** Su
`06-data/normalization-assessment.md` documenta una revisión externa real
(un instructor evaluó `Mer.dbml`, con cambios adoptados, rechazados y hasta
uno revertido) y acertó en distinguir catálogos de negocio genuinos
(`categories`, `engine_types`) de estados que no necesitan tabla propia
(`status` como `CHECK`). No hay nada que corregir en la normalización — lo
que sí falta es que ese modelo, ya correcto, viva repartido según quién lo
necesita.

**Pagos ya está aislado por permisos — falta aislarlo por despliegue.** El
equipo ya restringió `bank_accounts` a `SUPER_ADMIN` (INV-001) porque es
información financiera sensible. Hoy esa restricción vive a nivel de
aplicación, sobre el mismo esquema que sirve reservas y flota — cualquiera
con acceso a la base de datos ve la tabla igual. Separar Pagos en su propio
servicio, con su propia base y sus propias credenciales de acceso, extiende
esa misma intención de aislamiento hasta la capa de datos.

**Telemetría tiene un patrón de escritura que no se parece a nada más del
sistema.** Mientras Flota y Pagos son operaciones puntuales (reservar,
pagar, agendar un mantenimiento), un GPS activo reporta posición de forma
continua durante todo el alquiler. Hoy esa tabla vive en el mismo esquema
que `bank_accounts` — un pico de tráfico de telemetría no debería poder
afectar el rendimiento de una consulta de facturación.

**Reserva y Alquiler se fusionan a propósito, no se dejan sueltas.** El
equipo ya documentó que `rental` es 1:1 con `reservation` — la misma
transacción de negocio en dos momentos. Convertir eso en dos microservicios
solo agregaría una llamada de red por cada recogida de vehículo, sin ganar
nada: es exactamente el error que el ejercicio busca evitar en el extremo
contrario (crear más servicios de los que el negocio pide).

## Cómo se decidió qué excluir

- **Identity & Access (7 tablas):** `person`, `user`, `role`, `permission`,
  `role_permission`, `verification_code`, `session` — seguridad, ya es su
  propio bounded context en el diseño del equipo.
- **`audit`:** no tiene bounded context propio ni siquiera en el diseño
  original — el propio `domain-map.md` aclara que "no owning team, no
  dedicated microservice" y que los 7 dominios le escriben directo. Se
  excluye por ser infraestructura transversal, no negocio.
- **No se excluyó nada por "parametrización básica":** el equipo ya hizo
  ese trabajo — sus catálogos (`categories`, `engine_types`,
  `maintenance_types`, `insurance_types`) son datos de negocio reales,
  editables por un Admin, y sus campos de estado ya son `CHECK` en vez de
  tabla. Ese criterio se conserva intacto en este archivo.
