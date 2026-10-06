# Consistencia 01→06-data — ADSO-3145556 (corte 2026-09-22)

Pedido: informe de consistencia entre `01-context`, `02-domain`, `03-product`,
`04-requirements` frenteado contra `06-data`, y nivel de normalización + número de entidades
por equipo, para los 10 proyectos de la ficha.

Informe: `informe-consistencia.md`.

## Resultado en una línea por equipo

| Equipo | Entidades | Tablas | Normalización | Estado |
|---|---:|---:|---|---|
| edu-air-control | 7 | 38 | 1NF mencionada, sin veredicto | 🟡 |
| energy-monitor | 25 | 25 | **3NF sin excepciones** | 🟢 |
| faceattend-edu | 29 | 30 | Sin assessment | 🟢 |
| rent-car | 25 | 26 | **3NF + revisión de instructor documentada** | 🟢 |
| save-your-water | 16 | 31 | 3NF, 4 denormalizaciones (en `models.md`) | 🟢 |
| school-guardian | 0 | 0 | — | 🔴 **0 commits reales, solo el scaffold** |
| translates-sign-language | 16 | 29 | **3NF+BCNF, autocrítico** (el más riguroso) | 🟢 |
| vehicle-washing | 10 | 43 | 3NF razonado | 🟢 |
| woman-alert | 27 | 27 | 3NF, mecánico | 🟡 |
| your-event | 0 | 0 | — | 🔴 **modelo real fuera de este repo** |

## Cómo se obtuvieron los datos

Los 10 repos `{prefijo}-docs` de `code-sena` se clonaron en un snapshot local de solo lectura
(nada se escribió en GitHub). Para cada uno se extrajo por nombre —no solo por conteo—:
entidades de `02-domain/entities-and-rules.md`, bounded contexts de `domain-map.md`,
microservicios citados en `01-context` y `02-domain`, tablas de `06-data` (SQL, DBML o
encabezado `Table:`, según lo que usara cada equipo), HU de `04-requirements`, y el propio
`06-data/normalization-assessment.md` cuando existía (5 de 10 equipos lo escribieron: 
`en-monitor`, `rtm`, `trans-sl`, `vehicle-w`, `wal`).

Actividad real = commits al repo excluyendo el commit único de scaffold del instructor
(`feat: apply microservices-governance-framework scaffold`) — mismo criterio ya validado en
`../adso-3145556-punta-a-punta-2026-09-15/`.

## Los dos hallazgos que más pesan

- **school-guardian tiene un solo commit en la vida del repo** (el scaffold). Coherente con lo
  que ya mostraba el reporte de juicios de esta ficha (ver
  [[ficha-3145556-punta-a-punta-2026-09-15]]): no hay tablero, HU ni ambiente reales para este
  equipo, y ahora tampoco hay modelo de datos.
- **your-event sí trabajó, pero fuera de la estructura esperada**: los archivos canónicos
  (`01-context/overview.md`, `02-domain/entities-and-rules.md`, `06-data/models.md`) siguen
  siendo la plantilla sin diligenciar. El contenido real vive en una carpeta `evidence/` que el
  equipo agregó por su cuenta, y `06-data/evidence/models.md` declara que su fuente primaria es
  un repositorio distinto (`TuEvento-Docs`) no verificable desde `code-sena`.

## Reproducir / extender

El script de extracción (~230 líneas, Python, sin dependencias) vivió en el scratchpad de la
sesión que generó este informe — no se guardó en ningún repo. Automatiza: detección de
archivos de plantilla sin diligenciar, extracción de entidades/tablas por varios formatos
(SQL/DBML/tabla resumen), y cruce entidad↔tabla por nombre normalizado. Pedir que se regenere
si hace falta repetirlo para otra ficha o extenderlo (ej. agregar `03-product`↔`04-requirements`
a un nivel más fino de detalle, o correrlo contra un corte de fecha distinto).

## Limitaciones a tener en cuenta

- La detección de "archivo sin diligenciar" es heurística (≥2 placeholders de plantilla tipo
  `[EntityName]`). Se verificó a mano en los dos casos donde importaba (`sg-docs`, `yev-docs`)
  antes de reportarlo como hallazgo — no es solo el conteo automático.
- El cruce entidad↔tabla por nombre produce falsos negativos cuando el nombre de la entidad
  lleva anotaciones (`Goal *(Entrega 2)*`, `Service (WashService)`): se revisaron a mano los
  casos reportados como "sin tabla evidente" antes de incluirlos en el informe; los que
  resultaron ser ruido del regex no se reportan como hallazgo (ver `save-your-water` en el
  informe completo).
- No se aplicó la rúbrica de evaluación 0-100 de [[sena-rubrica-evaluacion-docs]] — este
  informe es de consistencia y normalización, no de nota. Tampoco se corrió corte de
  fecha/hora estricto: refleja el estado de cada repo en `main` al 2026-09-22.
