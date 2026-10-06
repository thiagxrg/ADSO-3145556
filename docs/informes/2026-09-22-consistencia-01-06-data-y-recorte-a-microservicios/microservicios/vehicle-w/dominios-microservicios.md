# 4 dominios reales para microservicios — vehicle-washing

Fuente: `code-sena/vehicle-w-docs`, corte 2026-09-22.

---

## 1. Clientes y Vehículos — `customer-service`

**Tablas:** `customer.vehicle_type`, `customer.customer`,
`customer.customer_vehicle`.

**Por qué es un dominio propio:** es el dato de CRM más estable — un
cliente y sus vehículos casi no cambian entre visitas — y todo lo demás
(reservar, ejecutar, cobrar) parte de aquí. El propio equipo ya evitó
duplicar nombre/teléfono desde `security.person`, la misma disciplina que
justifica separar este dominio del resto.

**Eventos que publicaría:** `CustomerRegistered`, `VehicleAdded`.

---

## 2. Catálogo y Reservas — `booking-service`

**Tablas:** `catalog.service_category`, `catalog.service`,
`catalog.service_price`, `reserve.business_hour`,
`reserve.business_hour_exception`, `reserve.service_bay`,
`reserve.reserve_status`, `reserve.cancellation_reason`, `reserve.reserve`,
`reserve.reserve_service`.

**Por qué se fusiona Catálogo con Reserva:** una reserva no existe sin un
precio vigente que congelar (`reserve_service.service_price_id`) — son la
misma transacción de negocio vista desde dos ángulos, igual que en otros
proyectos de la ficha donde Reserva y Ejecución se fusionaron por la misma
razón.

**Nota de nomenclatura (ver también el informe de consistencia del
2026-09-22):** esta tabla se llama `reserve` en el modelo de datos, pero
`02-domain/entities-and-rules.md` la describe como la entidad `Booking` —
mismo concepto de negocio, dos nombres distintos según el documento que se
lea. Al construir el microservicio conviene elegir un solo nombre y
usarlo en ambos lados.

**Eventos que publicaría:** `ReserveCreated`, `ReserveConfirmed`,
`ReserveCancelled`.

---

## 3. Operación y Ejecución — `operations-service`

**Tablas:** `execution.execution_status`, `execution.operator`,
`execution.operator_availability`, `execution.operator_absence`,
`execution.service_execution`.

**Por qué es un dominio propio:** administra el día a día del taller —
disponibilidad de operarios, asignación a cada ítem de una reserva,
seguimiento del servicio en curso — con un ritmo de cambio (varias veces
por hora, mientras el taller opera) muy distinto al de Catálogo, que
cambia por temporada.

**Un ajuste que vale la pena documentar, no solo aplicar:** `02-domain`
define `Rating` como una entidad propia con su propio agregado; en
`06-data` no hay tabla `rating` — la calificación vive como tres columnas
(`quality_rating`, `quality_comment`, `rated_at`) sobre
`service_execution`. Es defendible (una calificación no existe sin el
servicio que califica) pero conviene que quede escrito como decisión, no
como una discrepancia sin explicar entre el modelo de dominio y el modelo
físico.

**Eventos que publicaría:** `ServiceStarted`, `ServiceCompleted`,
`ServiceRated`.

---

## 4. Pagos, Promociones y Fidelización — `payment-service`

**Tablas:** `payment.payment_method_type`, `payment.payment_account`,
`payment.payment_status`, `payment.payment`, `payment.payment_receipt`,
`promotion.discount_type`, `promotion.promotion`,
`promotion.promotion_service`, `promotion.promotion_customer`,
`promotion.reserve_promotion`, `customer.loyalty_movement_type`,
`customer.loyalty_transaction`.

**Por qué se fusionan Pagos, Promociones y Fidelización:** las tres mueven
el mismo tipo de dato — dinero o su equivalente en puntos — y comparten el
mismo requisito no negociable: **todo tiene que ser auditable**.
`loyalty_transaction.balance_after` convierte el saldo cacheado en un
libro contable; `reserve_promotion.applied_amount` congela el descuento
tal como se aplicó, aunque la promoción cambie después. Es la misma
disciplina aplicada tres veces, y las tres necesitan el mismo nivel de
control de acceso que el resto del sistema no necesita.

**Eventos que publicaría:** `PaymentSubmitted`, `PaymentApproved`,
`PaymentRejected`, `PromotionApplied`, `LoyaltyPointsEarned`.

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| `security.*` (8 tablas), `audit.audit_log` | Seguridad y auditoría transversal — ya es su propio bounded context |
| `settings.establishment`, `settings.user_preference` | Configuración de la empresa y del usuario, no negocio de lavado de vehículos |
| `notification.*` (2 tablas) | Generic, reacciona a eventos de los otros dominios — no justifica un quinto servicio |
