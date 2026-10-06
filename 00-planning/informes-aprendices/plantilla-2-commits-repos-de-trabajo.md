# Informe 2 — Commits en los repositorios en los que trabajaste

**Periodo:** del 1 al 30 de agosto de 2026 (hora Colombia, UTC-5)
**Repositorio principal de la ficha:** https://github.com/code-sena/ADSO-3145556

| Campo | Valor |
|---|---|
| Aprendiz | |
| Usuario de GitHub | |
| Ficha | ADSO-3145556 |
| Proyecto (equipo) | |
| Correo(s) con el que haces commit | |
| Fecha de elaboración | |

<details>
<summary><strong>Instrucciones — léelas y borra este bloque antes de entregar</strong></summary>

**Qué reporta este informe.** Todos los commits que hiciste en **los demás repositorios en los que trabajaste**: tu repositorio personal o de perfil, tu fork de `ADSO-3145556`, repositorios de otros equipos, `design-software` y cualquier otro. **No repitas aquí** los repositorios de tu equipo (`-docs`, `-api`, `-app`, `-db`, `-portal`, `-worker`): esos van en el Informe 1.

**Tipos de repositorio** (úsalos en la columna *Tipo*): `Personal` · `Fork de la ficha` · `Otro equipo` · `design-software` · `Otro`.

**Paso 1 — descubre en qué repositorios trabajaste.** Elige una de las dos formas (reemplaza `TU_USUARIO`):

- *Desde el navegador:* abre
  `https://github.com/search?q=author%3ATU_USUARIO+author-date%3A2026-08-01..2026-08-30&type=commits`
  y mira en qué repositorios aparecen tus commits.
- *Desde la terminal* (requiere `gh`, la CLI de GitHub, con sesión iniciada):

```bash
gh search commits --author=TU_USUARIO --author-date=2026-08-01..2026-08-30 --limit 1000 \
  --json repository --jq '.[] | .repository.fullName' | sort | uniq -c
```

Te devuelve cada repositorio con el número de commits que encontró.

> **Advertencia:** la búsqueda de GitHub solo revisa la **rama por defecto** de cada repositorio. Si trabajaste en otra rama (`dev`, `docs`, `feature/…`), esos commits no aparecen. Por eso el Paso 2 es obligatorio, y además debes acordarte de los repositorios donde trabajaste solo en ramas secundarias.
> Los commits de los días 1 y 30 pueden cambiar de lado por la zona horaria: verifícalos con el Paso 2.

**Paso 2 — obtén los commits de cada repositorio.** Para cada repositorio, desde una terminal **Git Bash**, dentro de tu clon:

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

- Se imprime **el total de commits**. Las filas ya vienen en formato de tabla y quedan en `commits.md`: ábrelo, copia las filas y pégalas en la tabla del repositorio. Luego borra `commits.md`.
- `--all` incluye **todas las ramas**. Un commit que esté en varias ramas se cuenta una sola vez.
- `--no-merges` deja por fuera los commits de fusión.
- Si el mensaje de un commit contiene el carácter `|`, reemplázalo por `/` para no romper la tabla.
- El enlace de cada commit funciona con el `URL` del repositorio **desde el que clonaste**. Si clonaste un fork, el enlace apunta a tu fork, que es lo correcto.

**Repositorios privados.** Si un repositorio es privado, indica en *Visibilidad* si el usuario `ariel5253` tiene acceso. Un commit que el instructor no puede abrir no se puede verificar.

**Qué cuenta como commit tuyo.** Solo los hechos con tu cuenta. Abre un commit en GitHub: si aparece tu foto de perfil, está vinculado. Si no aparece, tu correo de `git config user.email` no está vinculado a tu cuenta: anótalo en *Observaciones*, no lo ocultes.

**Copia el bloque de la sección 2 una vez por cada repositorio.** Si en el periodo trabajaste en un solo repositorio, deja un solo bloque.

</details>

## 1. Resumen de repositorios

| # | Repositorio | Enlace | Tipo | Visibilidad | Commits |
|---|---|---|---|---|---|
| 1 | `propietario/repositorio` | https://github.com/propietario/repositorio | | Público / Privado | 0 |
| 2 | | | | | |
| | **Total** | | | | **0** |

## 2. Detalle por repositorio

### 2.1 `propietario/repositorio`

- **Enlace del repositorio:** https://github.com/propietario/repositorio
- **Tipo:** Personal / Fork de la ficha / Otro equipo / design-software / Otro
- **Visibilidad:** Público / Privado (¿`ariel5253` tiene acceso? Sí / No)
- **Total de commits en el periodo:** 0
- **Qué hice (2 a 3 líneas):**

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| | | |

### 2.2 `propietario/repositorio`

- **Enlace del repositorio:**
- **Tipo:**
- **Visibilidad:**
- **Total de commits en el periodo:** 0
- **Qué hice (2 a 3 líneas):**

| Commit ID | Fecha y hora | Mensaje |
|---|---|---|
| | | |

## 3. Verificación del aprendiz

- [ ] Todos los commits listados los hice con mi cuenta (aparece mi foto de perfil en GitHub).
- [ ] Incluí los commits de **todas las ramas** de cada repositorio, no solo de la rama por defecto.
- [ ] Todos los commits caen entre el 1 y el 30 de agosto de 2026 (hora Colombia).
- [ ] No repetí repositorios del Informe 1 (los de mi equipo).
- [ ] Cada enlace de repositorio y de commit abre en GitHub.
- [ ] El total de cada repositorio coincide con el número de filas de su tabla.
- [ ] En los repositorios privados indiqué si el instructor tiene acceso.

## 4. Observaciones

<!-- Commits sin vincular a tu cuenta, repositorios que se borraron, ramas con trabajo sin fusionar, o cualquier otra aclaración. -->

---

*Declaro que la información de este informe es veraz y que los commits listados son de mi autoría.*

**Aprendiz:** ______________________  **Fecha:** ______________
