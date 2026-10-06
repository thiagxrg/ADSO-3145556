# Informe 2 — Commits en los repositorios en los que trabajaste

**Periodo:** del 11 de agosto al 30 de septiembre de 2026 (hora Colombia, UTC-5)
**Organizacion principal del equipo de trabajo** https://github.com/orgs/RentaMovil/repositories
**Aclaracion:** Cabe aclarar que ya se le hizo la invitacion al instructor para que este se una a la organizacion y pueda ver los repositorios que estan privados 

| Campo | Valor |
|---|---|
| Aprendiz | Thiago Rojas |
| Usuario de GitHub | thiagxrg |
| Ficha | ADSO-3145556 |
| Proyecto (equipo) | rent-car |
| Correo(s) con el que haces commit | thiagorojasg451@gmail.com |
| Fecha de elaboración | 2026-10-06 |

## 1. Resumen de repositorios

| # | Repositorio | Enlace | Tipo | Visibilidad | Commits |
|---|---|---|---|---|---|
| 1 | `RentaMovil/RentaMovil` | https://github.com/RentaMovil/RentaMovil | Otro | Público | 7 |
| 2 | `RentaMovil/rtm-api-gateway` | https://github.com/RentaMovil/rtm-api-gateway | Otro | Privado (¿ariel5253 tiene acceso? pendiente de verificar) | 6 |
| 3 | `RentaMovil/rtm-iam` | https://github.com/RentaMovil/rtm-iam | Otro | Privado (¿ariel5253 tiene acceso? pendiente de verificar) | 11 |
| 4 | `RentaMovil/rtm-iam-db` | https://github.com/RentaMovil/rtm-iam-db | Otro | Privado (¿ariel5253 tiene acceso? pendiente de verificar) | 9 |
| | **Total** | | | | **33** |

## 2. Detalle por repositorio

### 2.1 `RentaMovil/RentaMovil`

- **Enlace del repositorio:** https://github.com/RentaMovil/RentaMovil
- **Tipo:** Otro (repositorio real del equipo, fuera de la organización `code-sena`)
- **Visibilidad:** Público
- **Total de commits en el periodo:** 7
- **Qué hice (2 a 3 líneas):** Documenté el repositorio, trabajé en los paneles de super admin, en la gestión de tipos de seguro y sucursales, y corregí el módulo de reservas.

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| [9c35e98](https://github.com/RentaMovil/RentaMovil/commit/9c35e98) | 2026-08-11 17:08:52 -0500 | New mr |
| [946f1b1](https://github.com/RentaMovil/RentaMovil/commit/946f1b1) | 2026-08-18 16:35:19 -0500 | updated documentation |
| [ead3743](https://github.com/RentaMovil/RentaMovil/commit/ead3743) | 2026-08-18 17:16:41 -0500 | Update Mer |
| [a4f8949](https://github.com/RentaMovil/RentaMovil/commit/a4f8949) | 2026-09-17 14:14:20 -0500 | Feature/super admin panels |
| [4f71b75](https://github.com/RentaMovil/RentaMovil/commit/4f71b75) | 2026-09-22 13:03:15 -0500 | feat: insurance-type and branch management - refractor: reservation admin |
| [258d307](https://github.com/RentaMovil/RentaMovil/commit/258d307) | 2026-09-28 13:22:33 -0500 | fix: resrvations |
| [59af887](https://github.com/RentaMovil/RentaMovil/commit/59af887) | 2026-09-28 13:25:15 -0500 | fix: resrvations |

### 2.2 `RentaMovil/rtm-api-gateway`

- **Enlace del repositorio:** https://github.com/RentaMovil/rtm-api-gateway
- **Tipo:** Otro (repositorio real del equipo, fuera de la organización `code-sena`)
- **Visibilidad:** Privado (Ya se le hizo la invitacion a el isntructor cuenta `ariel5253`)
- **Total de commits en el periodo:** 6
- **Qué hice (2 a 3 líneas):** Implementé el API Gateway: ruteo, CORS y correlation id, verificación de JWT contra el JWKS de IAM, rate limiting en rutas de autenticación, y el despliegue con Docker.

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| [ea53488](https://github.com/RentaMovil/rtm-api-gateway/commit/ea53488) | 2026-09-30 19:13:53 -0500 | Initial commit |
| [59d69ae](https://github.com/RentaMovil/rtm-api-gateway/commit/59d69ae) | 2026-09-30 19:29:52 -0500 | chore: set up API gateway with routing, CORS, correlation id and health |
| [450fc0d](https://github.com/RentaMovil/rtm-api-gateway/commit/450fc0d) | 2026-09-30 19:40:31 -0500 | feat: verify JWT with iam JWKS and forward X-User-Id / X-User-Role |
| [8ebf149](https://github.com/RentaMovil/rtm-api-gateway/commit/8ebf149) | 2026-09-30 19:48:12 -0500 | feat: in-memory rate limiting (10/5min on auth routes, 100/min general) |
| [85570ae](https://github.com/RentaMovil/rtm-api-gateway/commit/85570ae) | 2026-09-30 21:19:49 -0500 | chore: Dockerfile and docker-compose for the gateway; parallel /health and /health/live |
| [d42cb85](https://github.com/RentaMovil/rtm-api-gateway/commit/d42cb85) | 2026-09-30 21:20:56 -0500 | chore: Dockerfile and docker-compose for the gateway; parallel /health and /health/live |

### 2.3 `RentaMovil/rtm-iam`

- **Enlace del repositorio:** https://github.com/RentaMovil/rtm-iam
- **Tipo:** Otro (repositorio real del equipo, fuera de la organización `code-sena`)
- **Visibilidad:** Privado (Ya se le hizo la invitacion a el isntructor cuenta `ariel5253`)
- **Total de commits en el periodo:** 11
- **Qué hice (2 a 3 líneas):** Construí el microservicio de IAM completo: registro, login con JWT RS256, sesiones y bloqueo de cuenta, rotación de refresh tokens, perfil, recuperación de contraseña, administración de usuarios con auditoría y despliegue con Docker.

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| [6e514aa](https://github.com/RentaMovil/rtm-iam/commit/6e514aa) | 2026-09-29 22:40:23 -0500 | Initial commit |
| [56487bc](https://github.com/RentaMovil/rtm-iam/commit/56487bc) | 2026-09-29 23:00:42 -0500 | chore: set up Spring Boot project with hexagonal layout and health check |
| [9b004f6](https://github.com/RentaMovil/rtm-iam/commit/9b004f6) | 2026-09-29 23:09:52 -0500 | feat: load RS256 signing keys and expose GET /jwks |
| [ac64537](https://github.com/RentaMovil/rtm-iam/commit/ac64537) | 2026-09-29 23:35:26 -0500 | refactor: rewrite service in ms-security style and add register (HU-IAM-001) |
| [b43b28f](https://github.com/RentaMovil/rtm-iam/commit/b43b28f) | 2026-09-29 23:54:01 -0500 | feat: login with JWT RS256, sessions and account lockout; register returns tokens (HU-IAM-002) |
| [b13b2cd](https://github.com/RentaMovil/rtm-iam/commit/b13b2cd) | 2026-09-30 00:00:23 -0500 | feat: refresh token rotation with reuse detection and logout |
| [4f6b5ce](https://github.com/RentaMovil/rtm-iam/commit/4f6b5ce) | 2026-09-30 00:06:40 -0500 | feat: view and update own profile, change email with password (HU-IAM-004) |
| [ad6bdcc](https://github.com/RentaMovil/rtm-iam/commit/ad6bdcc) | 2026-09-30 00:14:38 -0500 | feat: user administration with permission checks and audit (HU-IAM-005) |
| [f8cf481](https://github.com/RentaMovil/rtm-iam/commit/f8cf481) | 2026-09-30 00:26:59 -0500 | feat: password recovery with 6-digit code (HU-IAM-003); store dates in UTC |
| [d2e1580](https://github.com/RentaMovil/rtm-iam/commit/d2e1580) | 2026-09-30 19:33:19 -0500 | fix: keep Spring web error status codes (405, 404, 415) instead of 500 |
| [7ad553d](https://github.com/RentaMovil/rtm-iam/commit/7ad553d) | 2026-09-30 21:21:52 -0500 | chore: Dockerfile and docker-compose for iam |

### 2.4 `RentaMovil/rtm-iam-db`

- **Enlace del repositorio:** https://github.com/RentaMovil/rtm-iam-db
- **Tipo:** Otro (repositorio real del equipo, fuera de la organización `code-sena`)
- **Visibilidad:** Privado (Ya se le hizo la invitacion a el isntructor cuenta `ariel5253`)
- **Total de commits en el periodo:** 9
- **Qué hice (2 a 3 líneas):** Configuré las migraciones de IAM con Liquibase: tablas, roles y permisos semilla, usuario de base de datos restringido al schema de IAM, esquema compartido con tabla de auditoría y la red Docker compartida para las migraciones.

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| [0b41fdb](https://github.com/RentaMovil/rtm-iam-db/commit/0b41fdb) | 2026-09-28 14:11:32 -0500 | Initial commit |
| [7caee7b](https://github.com/RentaMovil/rtm-iam-db/commit/7caee7b) | 2026-09-28 14:38:36 -0500 | chore: set up Liquibase project for IAM migrations |
| [b05177a](https://github.com/RentaMovil/rtm-iam-db/commit/b05177a) | 2026-09-28 17:32:10 -0500 | Chore migrations folder structure |
| [23cd312](https://github.com/RentaMovil/rtm-iam-db/commit/23cd312) | 2026-09-29 19:46:50 -0500 | Feat iam tables |
| [603a2fd](https://github.com/RentaMovil/rtm-iam-db/commit/603a2fd) | 2026-09-29 20:14:43 -0500 | feat: seed iam roles, permissions and cumulative role assignments |
| [6acd6a1](https://github.com/RentaMovil/rtm-iam-db/commit/6acd6a1) | 2026-09-29 20:23:29 -0500 | chore: add iam_app database user with access limited to the iam schema |
| [2e3ec99](https://github.com/RentaMovil/rtm-iam-db/commit/2e3ec99) | 2026-09-29 20:30:58 -0500 | feat: add shared schema and audit table |
| [2e317bf](https://github.com/RentaMovil/rtm-iam-db/commit/2e317bf) | 2026-09-30 00:28:55 -0500 | docs: how to create the first SUPER_ADMIN |
| [4a80b76](https://github.com/RentaMovil/rtm-iam-db/commit/4a80b76) | 2026-09-30 21:24:39 -0500 | chore: shared docker network and migrations container |

## 3. Verificación del aprendiz

- [x] Todos los commits listados los hice con mi cuenta (aparece mi foto de perfil en GitHub).
- [x] Incluí los commits de **todas las ramas** de cada repositorio, no solo de la rama por defecto.
- [x] Todos los commits caen entre el 11 de agosto y el 30 de septiembre de 2026 (hora Colombia).
- [x] No repetí repositorios del Informe 1 (los de mi equipo en `code-sena`).
- [x] Cada enlace de repositorio y de commit abre en GitHub.
- [x] El total de cada repositorio coincide con el número de filas de su tabla.
- [ ] En los repositorios privados indiqué si el instructor tiene acceso. *(pendiente de confirmar si `ariel5253` fue agregado al org `RentaMovil`)*

## 4. Observaciones

Los repositorios reales de desarrollo del equipo quedaron en la organización propia `RentaMovil` (no en `code-sena`), por eso aparecen en este informe y no en el Informe 1. Falta verificar/otorgar acceso del instructor (`ariel5253`) a los repos privados: `rtm-api-gateway`, `rtm-iam`, `rtm-iam-db` pero ya se le hizo la invitacion`.

---


**Aprendiz:** Thiago Rojas  **Fecha:** 2026-10-06
