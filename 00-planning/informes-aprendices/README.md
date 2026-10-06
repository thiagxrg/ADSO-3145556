# Informes de commits de los aprendices — agosto de 2026

Cada aprendiz entrega **dos informes** de lo que hizo en GitHub entre el **1 y el 30 de agosto de 2026** (hora Colombia, UTC-5).

| # | Plantilla | Qué reporta |
|---|---|---|
| 1 | [`plantilla-1-commits-equipo.md`](plantilla-1-commits-equipo.md) | Commits en el repositorio de documentación (`-docs`) y en los demás repositorios de **tu equipo** |
| 2 | [`plantilla-2-commits-repos-de-trabajo.md`](plantilla-2-commits-repos-de-trabajo.md) | Commits en **todos los demás repositorios** en los que trabajaste (personal, fork de la ficha, otros equipos, etc.) |

En los dos informes el orden es el mismo: **primero el enlace del repositorio y después todos los commits** que hiciste en él, cada uno con su ID.

Los repositorios de equipo se crearon el **25 de agosto de 2026**. Por eso el Informe 1 solo puede tener commits desde esa fecha, y el trabajo de las primeras semanas de agosto suele estar en el Informe 2.

## Reglas de conteo

- **Periodo:** desde el 2026-08-01 00:00:00 hasta el 2026-08-30 23:59:59, hora Colombia (UTC-5). Un commit fuera de ese intervalo no cuenta.
- **Todas las ramas**, no solo `main`.
- Un commit que esté en varias ramas **se cuenta una sola vez** (se identifica por su ID).
- **Sin commits de fusión** (*Merge pull request…*, *Merge branch…*).
- Solo cuentan commits hechos **con tu cuenta**. Si un commit no aparece con tu foto de perfil en GitHub, anótalo en *Observaciones*.
- Un repositorio sin commits tuyos en el periodo se deja en la tabla con **0**.
- El enlace de cada commit debe abrir en GitHub. Si el repositorio es privado, el instructor debe tener acceso.

## Cómo entregar

1. En **tu fork** de [`ADSO-3145556`](https://github.com/code-sena/ADSO-3145556), copia las plantillas a [`agosto-2026/`](agosto-2026/) y renómbralas:
   - `{tu-usuario}-1-equipo.md`
   - `{tu-usuario}-2-repos.md`
2. Llénalas, **borra el bloque de instrucciones** y haz commit en tu fork.

> **Tu fork es público**, porque el repositorio principal lo es. En los informes pon únicamente el ID, la fecha y el mensaje de cada commit; **no pegues código ni contenido** de los repositorios privados.

## Para el instructor

Los forks se sincronizan con `pull-forks.ps1` y los informes quedan en `forks-ADSO-3145556/{usuario}-ADSO-3145556/00-planning/informes-aprendices/agosto-2026/`.
