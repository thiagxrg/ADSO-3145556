# energy-monitor — propuesta de recorte a microservicios

**Qué hay en esta carpeta**

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN — sin IAM/seguridad ni catálogos de pura parametrización |
| `dominios-microservicios.md` | Los 4 dominios reales propuestos, con sus tablas, eventos y justificación |

Fuente: `code-sena/en-monitor-docs`, corte 2026-09-22.

## Por qué conviene este ajuste, específicamente para este proyecto

**Este es el equipo que menos lo necesita para la calidad del dato — y el que
más se beneficia de la separación operativa.** Su
`06-data/normalization-assessment.md` ya es el más limpio de los 10 proyectos
de la ficha: 3FN verificada tabla por tabla, sin una sola denormalización, y
lo dice sin inflar la sección ("as of this writing, the schema has no
intentional denormalization... stated plainly rather than manufactured
content"). El problema aquí no es de modelado — es que las 25 tablas viven
hoy en un solo esquema, con un solo ciclo de despliegue, para cuatro
responsabilidades con necesidades de escala completamente distintas.

**El volumen de `measurements` es la razón concreta.** Un dispositivo IoT que
reporta cada pocos segundos genera, solo él, más filas por día que todas las
tablas de Viviendas y Dispositivos juntas en un mes. Hoy, una migración sobre
`homes` bloquea (o al menos compite por lock) con la tabla que más escritura
recibe del sistema. Separar Monitoreo le da a esa tabla su propio ritmo de
mantenimiento, sin arrastrar al resto.

**`api_key` en `devices` es un dato sensible que hoy vive en el mismo
esquema que las preferencias de un usuario.** Aislar Gestión de Dispositivos
como servicio propio permite ponerle una política de acceso más estricta a
esa tabla sin tener que replicarla para el resto del sistema.

**Recomendaciones ya está separada en el diseño — falta separarla en el
código.** El equipo ya distinguió Alertas (regla de umbral, tiempo real) de
Recomendaciones (patrón de consumo, no urgente) en su propio `domain-map.md`.
Es la separación más barata de las cuatro: hoy es una sola tabla sin lógica
compleja, así que aislarla ahora cuesta poco y evita que, cuando llegue lógica
de recomendación más sofisticada, termine mezclada con el camino crítico de
alertas en tiempo real.

## Cómo se decidió qué excluir

- **Seguridad (13 tablas):** `person`, `user`, `user_configuration`,
  `password_reset_token`, `user_session`, `security_configuration`,
  `password_policy`, `login_error_log`, `system_role`, `user_system_role`,
  `permission`, `system_role_permission`, `audit_log` — ya es su propio
  bounded context "Security" en el `domain-map.md` del equipo.
- **Parametrización pura:** `home_type`, `appliance_type` — catálogos
  id+nombre sin lógica propia.
- **Se conservó** `consumption_level` aunque tenga forma de catálogo: trae
  `min_limit`/`max_limit`, es la regla que decide cuándo se dispara una
  alerta — negocio real, no una etiqueta.
