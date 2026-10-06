# woman-alert — propuesta de recorte a microservicios

**Qué hay en esta carpeta**

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN — sin IAM/seguridad ni administración/moderación |
| `dominios-microservicios.md` | Los 4 dominios reales propuestos, con sus tablas, eventos y justificación |

Fuente: `code-sena/wal-docs`, corte 2026-09-22.

## Por qué conviene este ajuste, específicamente para este proyecto

**Gestión de Alertas es, de los 10 proyectos de la ficha, el caso donde
aislar el dominio Core tiene la consecuencia más seria si no se hace.** Una
alerta de pánico que se retrasa porque el servicio compartido está
ocupado escribiendo un reporte de zona no es un problema de rendimiento
cualquiera — es exactamente el escenario que el diseño de microservicios
existe para evitar. Separar Gestión de Alertas del resto no es una mejora
de arquitectura abstracta aquí: es la diferencia entre que una alerta
salga a tiempo o no.

**Evidencia necesita infraestructura distinta a la del resto del sistema,
no solo un esquema distinto.** Guardar fotos, video y audio no es un
problema relacional — es almacenamiento de objetos con sus propias
necesidades de cifrado y retención. Mantenerlo junto a las tablas
operativas de Alertas mezcla dos tipos de infraestructura que deberían
poder evolucionar (y fallar) por separado.

**El propio análisis de normalización del equipo señala, sin querer, por
qué este recorte ayuda.** Su `normalization-assessment.md` llama
"denormalización intencional" a que `alert_id` sea nulable en
`location_log` y en `notification` — no lo es, es simplemente una relación
opcional (una ubicación o una notificación no siempre nace de una alerta
activa). El error no cambia el esquema, pero si alguien construye el
microservicio de Alertas asumiendo que esas columnas fueron un compromiso
de diseño en vez de un caso de uso normal, puede terminar añadiendo
salvaguardas donde no hacen falta. Vale la pena corregir la explicación
antes de construir sobre ella.

**Contactos y Notificaciones se fusionan porque ninguno de los dos tiene
peso propio.** Son las dos tablas más simples del sistema (CRUD sin reglas
de negocio complejas) y ambas existen solo para servir a Gestión de
Alertas y a Zonas — separarlas en dos microservicios distintos sería
crear infraestructura para dos tablas que no la necesitan.

## Cómo se decidió qué excluir

- **Identity and Accounts (11 tablas):** `role`, `user`, `account`,
  `user_profile`, `admin_profile`, `recovery_request`, `device`,
  `device_permission`, `alert_activation_setting`, `device_session`,
  `user_preference` — seguridad y configuración del dispositivo/cuenta del
  propio usuario, ya es su propio bounded context.
- **Administration and Moderation (4 tablas):** `audit_log`,
  `user_report`, `moderation_action`, `system_configuration` —
  infraestructura de back-office, no negocio de atención de emergencias.
- **No se excluyó nada de Zonas y Recursos como "parametrización":**
  `emergency_resources` es un directorio operativo real (hospitales,
  líneas de emergencia) que el sistema necesita para funcionar, no un
  catálogo decorativo.
