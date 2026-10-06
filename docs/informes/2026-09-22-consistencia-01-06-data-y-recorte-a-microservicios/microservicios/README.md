# Recorte a microservicios — ADSO-3145556 (corte 2026-09-22)

Pedido: para cada uno de los 10 proyectos de la ficha, un modelo de datos
normalizado en 3FN que excluya las entidades de seguridad y las básicas de
parametrización, la identificación de 4 dominios reales para llevar ese
proyecto a microservicios, y un README por equipo explicando por qué
conviene ese ajuste.

Este README es el índice. Cada subcarpeta trae sus propios tres archivos:

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN, sin seguridad ni parametrización |
| `dominios-microservicios.md` | Los 4 dominios propuestos: tablas, eventos, justificación |
| `README.md` | Por qué ese ajuste conviene, específico al proyecto |

## Los 10 equipos

| Carpeta | Proyecto | Entidades reales | Estado |
|---|---|---:|---|
| `ea-control/` | edu-air-control | Sí | Completo |
| `en-monitor/` | energy-monitor | Sí | Completo |
| `fae/` | faceattend-edu | Sí | Completo |
| `rtm/` | rent-car | Sí | Completo |
| `sy-water/` | save-your-water | Sí | Completo |
| `sg/` | school-guardian | **No** | ⚠️ Propuesta de línea base — ver `sg/README.md` |
| `trans-sl/` | translates-sign-language | Sí | Completo |
| `vehicle-w/` | vehicle-washing | Sí | Completo |
| `wal/` | woman-alert | Sí | Completo |
| `yev/` | your-event | Parcial | ⚠️ Reconstruido desde una instantánea (`evidence/`) — ver `yev/README.md` |

## Los dos casos que no son un recorte del trabajo real del equipo

**`sg/` (school-guardian):** el repo `sg-docs` tiene un solo commit en su
historia — el scaffold del instructor. No hay entidades, tablas ni bounded
contexts reales de los que partir. Lo que hay en esta carpeta es una
propuesta de línea base construida solo desde la descripción del
repositorio en GitHub, marcada como tal en cada archivo.

**`yev/` (your-event):** los archivos canónicos (`01-context`, `02-domain`,
`06-data/models.md`) también son plantilla sin diligenciar, pero el equipo
sí dejó trabajo real en una carpeta `evidence/` fuera de la estructura
esperada, que a su vez cita un repositorio externo
(`TuEvento-Docs`) no verificable desde `code-sena`. El recorte de este
equipo se reconstruyó desde esa evidencia, con las mismas salvedades.

Ambos hallazgos ya estaban documentados en el informe de consistencia del
2026-09-22 (`../adso-3145556-consistencia-01-06-2026-09-22/`).

## Método

- Fuente: los 10 repos `{prefijo}-docs` de `code-sena`, clonados en un
  snapshot local de solo lectura (nada se escribió en GitHub), mismo corte
  que el informe de consistencia.
- Para 8 de 10 equipos, el modelo de datos se tradujo fielmente desde su
  `06-data` real (SQL Server, DBML o SQL nativo, según cada equipo) a SQL
  PostgreSQL, para que los 10 paquetes queden en un formato uniforme.
- Los 4 dominios de cada equipo se apoyaron, cuando existían, en la propia
  clasificación del equipo (bounded contexts, columna "Owner" de servicio,
  clasificación Core/Supporting/Generic) — no se inventaron límites nuevos
  donde el equipo ya los había decidido.
- **Seguridad** (usuarios, roles, permisos, sesiones, auditoría) se excluyó
  siempre por la misma razón: ya es su propio servicio en el diseño de
  cada equipo, y no aporta nada al ejercicio de identificar dominios de
  *negocio*.
- **Parametrización básica** (catálogos de valor fijo sin lógica propia:
  tipos de unidad, estados genéricos, configuración de tema/idioma) se
  excluyó equipo por equipo, verificando primero si la tabla en cuestión
  tenía o no una regla de negocio real detrás — varias tablas con forma de
  catálogo se conservaron a propósito cuando el propio equipo ya había
  explicado por qué eran datos de negocio (ver cada `README.md` para el
  detalle).

## Verificación aplicada a los 10 `modelo-3fn.sql`

Antes de entregar, cada archivo se verificó automáticamente:
paréntesis balanceados, cero referencias `REFERENCES` a una tabla definida
más adelante en el mismo archivo (que rompería una ejecución de arriba
hacia abajo), y cero nombres de tabla duplicados. Los 10 pasaron sin
excepción. Esto confirma que el SQL es sintácticamente ejecutable en el
orden en que está escrito — no reemplaza una prueba real contra un motor
PostgreSQL.

## Reproducir / extender

No se guardó ningún script: cada modelo se construyó leyendo directamente
el `06-data` real de cada repo (o, en los dos casos marcados, desde lo
único disponible) y aplicando el mismo criterio de exclusión en cada uno.
Pedir que se regenere si hace falta repetirlo para otra ficha, u otra
fecha de corte.
