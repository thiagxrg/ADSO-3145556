# Informe 1 — Commits en el repositorio de documentación y en los repositorios de tu equipo

**Periodo:** del 1 al 30 de agosto de 2026 (hora Colombia, UTC-5)
**Repositorio principal de la ficha:** https://github.com/code-sena/ADSO-3145556

| Campo | Valor |
|---|---|
| Aprendiz | |
| Usuario de GitHub | |
| Ficha | ADSO-3145556 |
| Proyecto (equipo) | |
| Prefijo de los repositorios del equipo | |
| Correo(s) con el que haces commit | |
| Fecha de elaboración | |

<details>
<summary><strong>Instrucciones — léelas y borra este bloque antes de entregar</strong></summary>

**Qué reporta este informe.** Todos los commits que hiciste en el repositorio de documentación (`-docs`) y en los demás repositorios de **tu equipo**. Los commits en cualquier otro repositorio (personal, forks, otros equipos) van en el Informe 2.

**Importante: los repositorios de equipo se crearon el 25 de agosto de 2026.** Antes de esa fecha no pudiste hacer commits en ellos. Si tu trabajo de la primera y segunda semana de agosto estaba en otro repositorio, va en el Informe 2, no aquí.

**Repositorios de cada equipo** (todos en la organización `code-sena`):

| Proyecto | Prefijo | Repositorios |
|---|---|---|
| edu-air-control | `ea-control-` | api, db, docs, portal, **worker** |
| energy-monitor | `en-monitor-` | api, app, db, docs, portal |
| faceattend-edu | `fae-` | api, app, db, docs, portal |
| rent-car | `rtm-` | api, app, db, docs, portal |
| save-your-water | `sy-water-` | api, app, db, docs, **worker** |
| school-guardian | `sg-` | api, app, db, docs, portal |
| translates-sign-language | `trans-sl-` | api, app, db, docs, portal |
| vehicle-washing | `vehicle-w-` | api, app, db, docs, portal |
| woman-alert | `wal-` | api, app, db, docs, portal |
| your-event | `yev-` | api, app, db, docs, portal |

Si tu equipo usa `worker` en lugar de `app` o `portal`, cambia el nombre del bloque correspondiente (sección 3).

**Cómo obtener tus commits.** Para cada repositorio, desde una terminal **Git Bash**, dentro de tu clon del repositorio:

```bash
# Ajusta solo estas tres líneas
AUTOR="tu-correo@ejemplo.com"                 # varios correos: "uno@x.com\|otro@y.com"
DESDE="2026-08-01T00:00:00-05:00"
HASTA="2026-08-30T23:59:59-05:00"

URL=$(git remote get-url origin | sed -E 's#^git@github.com:#https://github.com/#; s#\.git$##')
git fetch --all --prune -q
git log --all --no-merges --author="$AUTOR" --since="$DESDE" --until="$HASTA" \
  --date=iso --reverse \
  --pretty=tformat:"| [%h]($URL/commit/%h) | %ad | %s |" | tee commits.md | wc -l
```

- Se imprime **el total de commits**. Las filas ya vienen en formato de tabla y quedan en el archivo `commits.md`: ábrelo, copia las filas y pégalas en la tabla del repositorio. Luego borra `commits.md`.
- `--all` incluye **todas las ramas**, no solo `main`. Un commit que esté en varias ramas se cuenta una sola vez.
- `--no-merges` deja por fuera los commits de fusión (*Merge pull request…*).
- Si el mensaje de un commit contiene el carácter `|`, reemplázalo por `/` para no romper la tabla.
- Si no tienes el repositorio clonado: `git clone https://github.com/code-sena/PREFIJO-docs`.
- Si un repositorio no tiene commits tuyos en el periodo, **déjalo en la tabla con 0**; no lo borres.

**Qué cuenta como commit tuyo.** Solo los hechos con tu cuenta. Abre un commit en GitHub: si aparece tu foto de perfil, está vinculado. Si no aparece, tu correo de `git config user.email` no está vinculado a tu cuenta: anótalo en *Observaciones*, no lo ocultes.

</details>

## 1. Resumen

| Repositorio | Enlace | Commits |
|---|---|---|
| `{PREFIJO}-docs` | https://github.com/code-sena/{PREFIJO}-docs | 0 |
| `{PREFIJO}-api` | https://github.com/code-sena/{PREFIJO}-api | 0 |
| `{PREFIJO}-app` | https://github.com/code-sena/{PREFIJO}-app | 0 |
| `{PREFIJO}-db` | https://github.com/code-sena/{PREFIJO}-db | 0 |
| `{PREFIJO}-portal` | https://github.com/code-sena/{PREFIJO}-portal | 0 |
| **Total** | | **0** |

## 2. Repositorio de documentación

- **Repositorio:** `{PREFIJO}-docs`
- **Enlace:** https://github.com/code-sena/{PREFIJO}-docs
- **Total de commits en el periodo:** 0
- **Qué hice (2 a 3 líneas):**

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| | | |

## 3. Repositorios del equipo

### 3.1 `{PREFIJO}-api`

- **Enlace:** https://github.com/code-sena/{PREFIJO}-api
- **Total de commits en el periodo:** 0
- **Qué hice (2 a 3 líneas):**

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| | | |

### 3.2 `{PREFIJO}-app`

- **Enlace:** https://github.com/code-sena/{PREFIJO}-app
- **Total de commits en el periodo:** 0
- **Qué hice (2 a 3 líneas):**

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| | | |

### 3.3 `{PREFIJO}-db`

- **Enlace:** https://github.com/code-sena/{PREFIJO}-db
- **Total de commits en el periodo:** 0
- **Qué hice (2 a 3 líneas):**

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| | | |

### 3.4 `{PREFIJO}-portal`

- **Enlace:** https://github.com/code-sena/{PREFIJO}-portal
- **Total de commits en el periodo:** 0
- **Qué hice (2 a 3 líneas):**

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| | | |

## 4. Verificación del aprendiz

- [ ] Todos los commits listados los hice con mi cuenta (aparece mi foto de perfil en GitHub).
- [ ] Incluí los commits de **todas las ramas**, no solo de `main`.
- [ ] Todos los commits caen entre el 1 y el 30 de agosto de 2026 (hora Colombia).
- [ ] Cada enlace de commit abre en GitHub.
- [ ] Los repositorios en los que no tengo commits quedaron en la tabla con 0.
- [ ] El total de cada repositorio coincide con el número de filas de su tabla.

## 5. Observaciones

<!-- Commits sin vincular a tu cuenta, ramas con trabajo sin fusionar, repositorios a los que no tuviste acceso, o cualquier otra aclaración. -->

---

*Declaro que la información de este informe es veraz y que los commits listados son de mi autoría.*

**Aprendiz:** ______________________  **Fecha:** ______________
