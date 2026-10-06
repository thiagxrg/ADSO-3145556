# Informe 1 — Commits en el repositorio de documentación y en los repositorios de tu equipo

**Periodo:** del 11 de agosto al 30 de septiembre de 2026 (hora Colombia, UTC-5)
**Repositorio principal de la ficha:** https://github.com/code-sena/ADSO-3145556

| Campo | Valor |
|---|---|
| Aprendiz | Thiago Rojas |
| Usuario de GitHub | thiagxrg |
| Ficha | ADSO-3145556 |
| Proyecto (equipo) | rent-car |
| Prefijo de los repositorios del equipo | rtm- |
| Correo(s) con el que haces commit | thiagorojasg451@gmail.com |
| Fecha de elaboración | 2026-10-06 |

## 1. Resumen

| Repositorio | Enlace | Commits |
|---|---|---|
| `rtm-docs` | https://github.com/code-sena/rtm-docs | 32 |
| `rtm-api` | https://github.com/code-sena/rtm-api | No se tocaron, pendiente|
| `rtm-app` | https://github.com/code-sena/rtm-app | No se tocaron, pendiente|
| `rtm-db` | https://github.com/code-sena/rtm-db | No se tocaron, pendiente|
| `rtm-portal` | https://github.com/code-sena/rtm-portal | No se tocaron, pendiente|
| **Total** | | **32** |

## 2. Repositorio de documentación

- **Repositorio:** `rtm-docs`
- **Enlace:** https://github.com/code-sena/rtm-docs
- **Total de commits en el periodo:** 32
- **Qué hice (2 a 3 líneas):** Construí la gobernanza y el dominio del proyecto (requisitos, modelo de datos, vehículos y notificaciones), diseñé el mapa de navegación y describí todas las pantallas (mockups). Después documenté la estrategia de migración por servicio (ADR-009), el catálogo de permisos, el contrato de IAM y la recuperación de contraseña con convención de fechas en UTC.

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| [4b6c856](https://github.com/code-sena/rtm-docs/commit/4b6c856) | 2026-09-03 13:41:25 -0500 | Building governance |
| [9e5f9df](https://github.com/code-sena/rtm-docs/commit/9e5f9df) | 2026-09-08 08:37:47 -0500 | Building domain |
| [62aafa6](https://github.com/code-sena/rtm-docs/commit/62aafa6) | 2026-09-08 10:24:51 -0500 | Building requirements and traduction of domain |
| [c62feb7](https://github.com/code-sena/rtm-docs/commit/c62feb7) | 2026-09-08 13:53:04 -0500 | We build the model and update routes |
| [5987326](https://github.com/code-sena/rtm-docs/commit/5987326) | 2026-09-09 17:12:07 -0500 | Reconstruction of the data model |
| [3017b96](https://github.com/code-sena/rtm-docs/commit/3017b96) | 2026-09-10 13:32:26 -0500 | Reconstruction of vehicle and notifications in data model |
| [6f2d810](https://github.com/code-sena/rtm-docs/commit/6f2d810) | 2026-09-12 11:17:09 -0500 | Refractoring docs |
| [be5309c](https://github.com/code-sena/rtm-docs/commit/be5309c) | 2026-09-12 11:24:32 -0500 | Fix Product |
| [940d4c5](https://github.com/code-sena/rtm-docs/commit/940d4c5) | 2026-09-12 11:32:17 -0500 | Feat new epic and hu |
| [216660d](https://github.com/code-sena/rtm-docs/commit/216660d) | 2026-09-15 09:09:55 -0500 | The navigation map was created, and all screens were described |
| [98d8d9a](https://github.com/code-sena/rtm-docs/commit/98d8d9a) | 2026-09-15 09:13:06 -0500 | The navigation map was created, and all screens were described-English |
| [1794e3e](https://github.com/code-sena/rtm-docs/commit/1794e3e) | 2026-09-15 15:39:52 -0500 | The audit rework |
| [d72ceeb](https://github.com/code-sena/rtm-docs/commit/d72ceeb) | 2026-09-15 15:45:15 -0500 | The audit rework |
| [b62c977](https://github.com/code-sena/rtm-docs/commit/b62c977) | 2026-09-15 16:33:42 -0500 | add screen edit-vehicle |
| [c823544](https://github.com/code-sena/rtm-docs/commit/c823544) | 2026-09-15 16:52:31 -0500 | add screen branch-management |
| [1e0669e](https://github.com/code-sena/rtm-docs/commit/1e0669e) | 2026-09-15 17:03:20 -0500 | add screen reservation-detail |
| [d99a87a](https://github.com/code-sena/rtm-docs/commit/d99a87a) | 2026-09-15 17:10:13 -0500 | add screen reservation-panel and insurance-types |
| [2c924da](https://github.com/code-sena/rtm-docs/commit/2c924da) | 2026-09-15 17:18:02 -0500 | add screen vehicle-tracking |
| [7f07005](https://github.com/code-sena/rtm-docs/commit/7f07005) | 2026-09-15 17:20:28 -0500 | add screen user-role-management |
| [46ce942](https://github.com/code-sena/rtm-docs/commit/46ce942) | 2026-09-15 17:24:40 -0500 | add screen bank-accounts |
| [4be2a67](https://github.com/code-sena/rtm-docs/commit/4be2a67) | 2026-09-15 17:26:04 -0500 | Docs/mockup part 3 |
| [2722452](https://github.com/code-sena/rtm-docs/commit/2722452) | 2026-09-16 13:33:33 -0500 | add screen reservations-wisard and notifications |
| [ebe6841](https://github.com/code-sena/rtm-docs/commit/ebe6841) | 2026-09-16 13:37:54 -0500 | add screen fleet-panel and register-vehicle |
| [d3cea26](https://github.com/code-sena/rtm-docs/commit/d3cea26) | 2026-09-16 14:42:24 -0500 | Docs-mockup02 |
| [6c5152c](https://github.com/code-sena/rtm-docs/commit/6c5152c) | 2026-09-28 13:27:59 -0500 | refractor: the 7 domains - 5 domains |
| [a246e87](https://github.com/code-sena/rtm-docs/commit/a246e87) | 2026-09-28 15:53:58 -0500 | fix: migration strategy |
| [a07264d](https://github.com/code-sena/rtm-docs/commit/a07264d) | 2026-09-28 17:19:08 -0500 | docs: add schema per service and migration repo conventions (ADR-009) |
| [29d812f](https://github.com/code-sena/rtm-docs/commit/29d812f) | 2026-09-29 19:48:03 -0500 | docs: document migration folder layout and unique person email |
| [1ecf19a](https://github.com/code-sena/rtm-docs/commit/1ecf19a) | 2026-09-29 19:49:00 -0500 | docs: document migration folder layout and unique person email |
| [e38d969](https://github.com/code-sena/rtm-docs/commit/e38d969) | 2026-09-29 23:52:39 -0500 | docs: permission catalog, Spring Boot 4 setup, iam contract fixes |
| [bf19022](https://github.com/code-sena/rtm-docs/commit/bf19022) | 2026-09-30 00:15:31 -0500 | docs: iam contract user admin permissions and responses |
| [d4436d5](https://github.com/code-sena/rtm-docs/commit/d4436d5) | 2026-09-30 00:29:51 -0500 | docs: password recovery endpoints and UTC dates convention |

## 3. Repositorios del equipo

*(No se tocaron, pendiente `rtm-api`, `rtm-app`, `rtm-db`, `rtm-portal`)*

## 4. Verificación del aprendiz

- [x] Todos los commits listados los hice con mi cuenta (aparece mi foto de perfil en GitHub).
- [x] Incluí los commits de **todas las ramas**, no solo de `main`.
- [x] Todos los commits caen entre el 11 de agosto y el 30 de septiembre de 2026 (hora Colombia).
- [x] Cada enlace de commit abre en GitHub. 
- [ ] Los repositorios en los que no tengo commits quedaron en la tabla con 0. *(pendiente: faltan api/app/db/portal)*
- [x] El total de cada repositorio coincide con el número de filas de su tabla (sección 2).

## 5. Observaciones

Sección 3 (repositorios de equipo: api, app, db, portal) No se tocaron pq lo hiicmos en una organizacion propia

---


**Aprendiz:** Thiago Rojas  **Fecha:** 2026-10-06
