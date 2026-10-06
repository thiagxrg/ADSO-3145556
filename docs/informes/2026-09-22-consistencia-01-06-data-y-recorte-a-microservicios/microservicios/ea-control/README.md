# edu-air-control — propuesta de recorte a microservicios

**Qué hay en esta carpeta**

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN — sin IAM/seguridad ni catálogos de pura parametrización |
| `dominios-microservicios.md` | Los 4 dominios reales propuestos, con sus tablas, eventos y por qué cada uno es independiente |

Fuente: `code-sena/ea-control-docs`, corte 2026-09-22. El modelo real del equipo
ya estaba en 3FN (mencionan el principio explícitamente en
`06-data/domain/ms-environment-monitoring.md`); este paquete no corrige
normalización, **la aísla**: separa lo que ya es negocio puro de lo que es
infraestructura compartida (seguridad, catálogos).

## Por qué conviene este ajuste, específicamente para este proyecto

**El propio equipo ya detectó el problema, sin resolverlo.** Su
`domain-map.md` describe 6 bounded contexts (IAM, Monitoring, Data Analysis,
Classrooms, Sensors, UX) y hasta clasifica cuál es *Core* y cuál es
*Supporting* — el trabajo de identificar dominios ya estaba hecho en el papel.
Lo que no pasó fue llevarlo al código: hoy el modelo de datos vive repartido en
4 archivos con **dos notaciones distintas** (DBML en el archivo de Monitoreo,
SQL en los otros tres) y sin que el `01-context/overview.md` use los mismos
nombres de servicio que `02-domain/domain-map.md` (`ms-monitoreo` allá,
`ms-environment-monitoring` acá — el mismo servicio con dos nombres, ver el
informe de consistencia del 2026-09-22). Consolidar en 4 dominios con límites
explícitos —y un solo nombre por servicio— cierra esa brecha antes de que se
convierta en código real con el mismo problema.

**El patrón de carga ya justifica la separación, no es una preferencia
estética.** Sensores es inventario (altas/bajas esporádicas de hardware);
Monitoreo es escritura continua de alta frecuencia (una fila por sensor por
variable por intervalo) más lectura agregada pesada (dashboards por
día/semana/mes/año). Hoy ambos comparten el mismo esquema — cualquier
migración o pico de carga en Monitoreo obliga a tocar, o al menos revisar,
la base de datos de Sensores también. Separarlos permite escalar la ingesta de
mediciones sin arrastrar el inventario de hardware.

**El dominio Core queda protegido de lo que es prescindible.** Si el servicio
de Experiencia de Usuario (favoritos, calificaciones, búsquedas) cae, el
sistema debería seguir midiendo temperatura y CO₂ sin parpadear — es
justamente lo que dice la propia clasificación Core/Supporting del equipo.
Hoy, al vivir en el mismo modelo relacional, un despliegue con errores en UX
puede bloquear una migración que también necesitaba correr Monitoreo.

**Las alertas se quedan donde nacen, no se fuerzan a "su propio servicio".**
Es tentador partir Alertas en un quinto dominio, pero una alerta no existe sin
la medición que la dispara — es la misma transacción de negocio. Forzar esa
separación agregaría una llamada de red por cada medición que cruza un umbral,
sin ningún beneficio real de escalamiento o de equipo dueño.

## Cómo se decidió qué excluir

- **Seguridad (13 tablas de `ms-iam.md`):** ya es su propio servicio en el
  diseño actual del equipo (`ms-security` + `ms-usuarios`); no aporta nada
  nuevo tratarlo aquí.
- **Parametrización pura:** `sensor_models`, `sensor_statuses`,
  `measurement_units`, `alert_status` — catálogos de valor fijo sin
  comportamiento propio. Se conservan como columna de referencia (sin FK
  física) en el modelo, para no perder el dato.
- **Se conservó** `environment_types` aunque parezca un catálogo: decide qué
  `variable_threshold` aplica a cada ambiente — es una regla de negocio real,
  no una etiqueta.
