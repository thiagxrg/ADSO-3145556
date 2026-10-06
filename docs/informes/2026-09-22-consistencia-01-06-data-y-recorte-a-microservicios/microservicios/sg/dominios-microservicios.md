# 4 dominios propuestos (línea base, no derivada del equipo) — school-guardian

⚠️ **Ver README.md primero.** No existe documentación real del equipo en
`sg-docs` (1 solo commit, el scaffold). Esta es una propuesta de línea base
construida solo desde la descripción del repositorio
("school route management and monitoring"), para que el ejercicio de la
ficha tenga los 10 paquetes solicitados.

---

## 1. Rutas y Paradas — `route-service`

**Tablas propuestas:** `routes`, `stops`, `route_stops` (secuencia de
paradas por ruta, con hora estimada de paso).

**Por qué sería un dominio propio:** es el dato más estable — una ruta
escolar cambia por periodo académico, no por día — y todo lo demás
(estudiantes asignados, seguimiento en vivo) depende de que exista una ruta
con sus paradas.

---

## 2. Estudiantes y Acudientes — `student-service`

**Tablas propuestas:** `students`, `guardians`, `student_route_assignments`.

**Por qué sería un dominio propio:** es información de menores, con
requisitos de privacidad distintos al resto del sistema — conviene que
tenga su propia base con controles de acceso más estrictos, separada del
GPS en tiempo real.

---

## 3. Seguimiento en Tiempo Real — `tracking-service`

**Tablas propuestas:** `buses`, `trip_instances` (el recorrido concreto de
una ruta en una fecha), `gps_positions`.

**Por qué sería el dominio Core:** es la razón de negocio del producto —
saber dónde está el bus ahora. Necesitaría escritura de muy alta frecuencia
(una posición GPS cada pocos segundos por bus activo), un patrón de carga
que no tiene nada que ver con administrar rutas o estudiantes.

---

## 4. Notificaciones a Acudientes — `notification-service`

**Tablas propuestas:** `notifications`, `notification_preferences`.

**Por qué sería un dominio propio:** reacciona a eventos de Seguimiento
(bus a N minutos de una parada) pero su disponibilidad no debería ser
crítica — si este servicio falla, el sistema debe seguir rastreando el bus
sin problema.

---

## Lo que se excluiría (mismo criterio que el resto de la ficha)

| Excluido | Por qué |
|---|---|
| Identidad y acceso (usuarios, roles, sesiones) | Seguridad — su propio servicio, no negocio de transporte escolar |
| Catálogos de parametrización pura (tipo de vehículo, tipo de parada, etc.) | Sin lógica de negocio propia |
