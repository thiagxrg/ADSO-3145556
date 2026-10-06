# translates-sign-language — propuesta de recorte a microservicios

**Qué hay en esta carpeta**

| Archivo | Contenido |
|---|---|
| `modelo-3fn.sql` | El núcleo de negocio en 3FN — sin IAM/seguridad ni dominios secundarios/en pausa |
| `dominios-microservicios.md` | Los 4 dominios reales propuestos, con sus tablas, eventos y justificación |

Fuente: `code-sena/trans-sl-docs`, corte 2026-09-22.

## Por qué conviene este ajuste, específicamente para este proyecto

**Este es el equipo con el análisis de datos más riguroso de los 10
proyectos de la ficha — y el ajuste que le falta es exactamente el que su
propio análisis ya señaló.** Su `06-data/normalization-assessment.md`
admite algo que ningún otro equipo escribió: sus tablas de rollup
"currently contradict the domain map — DATA-03". Separar Analítica de Uso
en su propio servicio no resuelve esa inconsistencia por sí solo, pero la
hace visible en el lugar correcto: un servicio con un solo dueño, en vez de
una responsabilidad compartida y ambigua dentro de un monolito.

**El dominio Core necesita aislarse de todo lo demás, no solo de
seguridad.** Reconocimiento y Traducción es la única parte del sistema con
un requisito de latencia real (responder a una cámara en vivo). Hoy
comparte esquema con Analítica de Uso, cuyo patrón de escritura es
exactamente lo opuesto: ráfagas de eventos que un job nocturno agrega. Un
pico de tráfico de analítica no debería poder afectar el tiempo de
respuesta del reconocedor.

**Gamificación se excluye a propósito, no por descuido.** El propio equipo
ya la marcó ⏸ *"provisional"* en su `domain-map.md`, pendiente de un
requisito (RF8) que aún no está resuelto. Comprometer un microservicio a un
dominio que el equipo mismo no ha terminado de decidir sería adelantarse a
una decisión de producto que todavía está abierta.

**El aviso sobre `unique_users` viaja con el recorte, no se pierde en él.**
Es tentador pensar que separar Analítica en su propio servicio "resuelve"
el problema de que esa columna no sea aditiva — no es así. Se deja anotado
explícitamente en `dominios-microservicios.md` para que quien construya
ese servicio lo sepa desde el día uno, no lo descubra en producción.

## Cómo se decidió qué excluir

- **Identity + Authorization (10 tablas):** seguridad, ya es su propio
  bounded context.
- **`notification.*` (3 tablas):** Generic y delgado — reacciona a eventos
  de los otros tres dominios, no justifica un cuarto servicio por sí solo.
- **`gamification.*` (2 tablas):** marcado ⏸ provisional por el propio
  equipo, pendiente de RF8.
- **`audit.*` (2 tablas):** infraestructura transversal, no negocio.
- **Se conservó** `ai.ai_models` aunque tenga forma de catálogo: el propio
  equipo ya explicó por qué guardar la referencia al modelo (no copiar su
  versión) es la normalización correcta, no una excepción.
