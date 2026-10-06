# vehicle-washing — propuesta de recorte a microservicios

**Qué hay en esta carpeta**

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN — sin IAM/seguridad, configuración ni notificaciones |
| `dominios-microservicios.md` | Los 4 dominios reales propuestos, con sus tablas, eventos y justificación |

Fuente: `code-sena/vehicle-w-docs`, corte 2026-09-22.

## Por qué conviene este ajuste, específicamente para este proyecto

**Es el modelo más grande de los 10 proyectos de la ficha — 43 tablas
distintas en 9 esquemas — y ya vive organizado por esquema, lo cual hace
este recorte casi mecánico.** El trabajo real no fue inventar los límites:
fue decidir cuáles de esos 9 esquemas son negocio de lavado de vehículos y
cuáles son infraestructura compartida (seguridad, configuración,
notificaciones), y agrupar el resto en 4 servicios con una razón de negocio
real para existir por separado, no solo "porque ya eran carpetas
distintas".

**Pagos, Promociones y Fidelización comparten un requisito que ningún otro
dominio tiene: todo debe poder auditarse contra un libro contable.** El
propio equipo ya lo resolvió así para el saldo de puntos
(`loyalty_transaction.balance_after`) y para el descuento aplicado
(`reserve_promotion.applied_amount`, congelado, nunca recalculado). Juntar
los tres en un solo servicio significa que esa disciplina de auditoría se
implementa una vez, con un solo nivel de control de acceso más estricto,
en vez de tres veces con el riesgo de que una quede menos protegida que
las otras dos.

**Se encontró y se dejó explícito un ajuste de nomenclatura real.** El
informe de consistencia del 2026-09-22 ya había detectado que
`02-domain/entities-and-rules.md` llama `Booking` a la transacción central
de la plataforma, mientras que `06-data` la llama `reserve`. Este paquete
no renombra nada —eso es decisión del equipo—, pero lo deja anotado en el
propio SQL para que quien construya el microservicio no herede la
confusión sin saberlo.

**Se documentó una simplificación que el repo original no explicaba.**
`Rating` es una entidad con su propio agregado en `02-domain`, pero en
`06-data` es solo tres columnas sobre `service_execution`. Es una decisión
razonable —una calificación no existe sin el servicio que califica—, pero
convertirla en microservicio obliga a decidir explícitamente si sigue
siendo así o si merece su propia tabla; ambas opciones son válidas, la que
no lo es es dejarlo sin decidir.

## Cómo se decidió qué excluir

- **`security.*` (8 tablas) + `audit.audit_log`:** seguridad y auditoría
  transversal — ya es su propio bounded context.
- **`settings.establishment`, `settings.user_preference`:** configuración
  de la empresa (una sola fila, logo y NIT) y del usuario (tema/idioma) —
  no es negocio de lavado de vehículos.
- **`notification.*` (2 tablas):** Generic — reacciona a eventos de los
  otros cuatro dominios, no tiene lógica de negocio propia que justifique
  un quinto servicio.
- **Se conservó** `customer.vehicle_type` pese a su forma de catálogo: el
  propio equipo documentó que `size_factor` nunca calcula un precio real
  (siempre viene de `service_price`) — es un dato de referencia genuino,
  no una etiqueta decorativa.
