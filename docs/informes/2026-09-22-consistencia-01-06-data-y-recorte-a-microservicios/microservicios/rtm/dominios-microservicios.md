# 4 dominios reales para microservicios — rent-car

Fuente: `code-sena/rtm-docs`, corte 2026-09-22.

---

## 1. Flota y Mantenimiento — `fleet-service`

**Tablas:** `branches`, `branch_operating_hours`, `brands`, `categories`,
`engine_types`, `vehicle_models`, `vehicles`, `maintenance_types`,
`vehicle_maintenances`.

**Por qué es un dominio propio:** es el catálogo maestro — qué existe, dónde
está, en qué condición — y cambia por operación administrativa (dar de alta
un vehículo, agendar mantenimiento), no por transacción de cliente. Es
también el dominio con más tablas de catálogo real (`brands`, `categories`,
`engine_types`), editables por un Admin, según ya lo documentó el equipo.

**Eventos que publicaría:** `VehicleStatusChanged`, `MaintenanceScheduled`,
`MaintenanceCompleted`.

---

## 2. Reserva y Alquiler — `booking-service`

**Tablas:** `insurance_types`, `reservations`, `rentals`, `notifications`.

**Por qué se fusionan Reserva, Ejecución del Alquiler y Notificación en un
solo dominio:** el propio equipo ya documentó que `rental` es 1:1 con
`reservation` — "se ejecuta exactamente una vez" — no son dos transacciones
de negocio distintas, son dos momentos de la misma: reservar, luego recoger
y devolver. Partirlas en dos servicios obligaría a coordinar por red cada vez
que una reserva confirmada pasa a alquiler activo, con cero beneficio de
escalamiento independiente. `notifications` se agrega aquí porque reacciona
directamente a los eventos de este dominio (`RESERVATION_CREATED`, etc.) y
es demasiado delgada (una sola tabla, sin lógica propia) para justificar un
quinto servicio.

**Por qué merece ser su propio dominio:** es el corazón transaccional del
negocio — el estado de una reserva (`PENDING_PAYMENT` → `PENDING_REVIEW` →
`CONFIRMED`...) es una máquina de estados real con reglas de tiempo (INV-013,
INV-015) que necesita su propio ciclo de vida, separado del catálogo de
flota que casi no cambia.

**Eventos que publicaría:** `ReservationCreated`, `ReservationConfirmed`,
`VehiclePickedUp`, `VehicleReturned`.

**Dependencia:** consume `vehicle_id`/`branch_id` de Flota (lectura), y
dispara `Payment`/`Invoice` en el dominio de Pagos.

---

## 3. Pagos y Facturación — `payment-service`

**Tablas:** `bank_accounts`, `payments`, `invoices`.

**Por qué es un dominio propio:** maneja el dato más sensible del sistema
(cuentas bancarias de la empresa, comprobantes de transferencia) y su propio
flujo de revisión manual por un Admin — completamente distinto al flujo de
reserva. El propio equipo ya restringió `bank_accounts` a `SUPER_ADMIN`
únicamente (INV-001 de `BankAccount`), reforzando que es un límite de
autorización real, no solo una tabla más.

**Eventos que publicaría:** `PaymentSubmitted`, `PaymentApproved`,
`PaymentRejected`, `InvoiceGenerated`.

**Dependencia:** consume `reservation_id`/`total_amount` de Reserva y
Alquiler (referencia lógica, sin FK física).

---

## 4. Telemetría y GPS — `telemetry-service`

**Tablas:** `gps_devices`, `locations`.

**Por qué es un dominio propio:** es, con diferencia, el de mayor volumen de
escritura del sistema — cada dispositivo GPS reporta posición constantemente
durante todo un alquiler activo, mientras que Flota y Pagos son CRUD de baja
frecuencia. Es también el único candidato real a usar un motor distinto
(series de tiempo) si el volumen lo justifica más adelante.

**Eventos que publicaría:** `LocationReported`.

**Dependencia:** `rentals.gps_id` es la única referencia cruzada — un
alquiler activo usa un dispositivo de este dominio.

---

## Lo que queda fuera de los 4 (a propósito)

| Excluido | Por qué no es uno de los 4 |
|---|---|
| Identity & Access (`person`, `user`, `role`, `permission`, `role_permission`, `verification_code`, `session`) | Seguridad — ya es su propio bounded context en el diseño del equipo |
| `audit` | Cross-cutting sin bounded context propio en el diseño original — todos escriben ahí, nadie lo posee |

**Nada se excluyó por "parametrización básica":** a diferencia de otros
proyectos de la ficha, este equipo ya evaluó explícitamente qué merecía ser
catálogo (`categories`, `engine_types`, `maintenance_types`,
`insurance_types` — sí) y qué no (`status` en `vehicles`/`reservations`/
`payments` — CHECK, no tabla, porque lo controla el código y no un Admin).
Ese criterio ya estaba bien puesto y se respeta tal cual.
