# App - Escenarios e Inquietudes del Proceso

Este archivo se usará para documentar decisiones, dudas frecuentes y escenarios vistos durante el desarrollo del proyecto.

Contexto actual del proyecto:

- Spring Boot `4.0.3`
- Java `17`
- Base de datos `MySQL`
- Configuración actual: `spring.jpa.hibernate.ddl-auto=create-drop`

## 1. Por qué se usa `spring.jpa.hibernate.ddl-auto`

La propiedad `spring.jpa.hibernate.ddl-auto` le dice a Hibernate qué debe hacer con el esquema de la base de datos a partir de las entidades Java anotadas con JPA, por ejemplo `Role`, `Person` y `User`.

En otras palabras, esta propiedad define si Hibernate:

- no hace nada,
- valida la estructura existente,
- actualiza tablas,
- crea el esquema desde cero,
- o crea y luego elimina el esquema al cerrar la aplicación.

Es útil porque en etapas tempranas del desarrollo evita crear manualmente cada tabla mientras el modelo todavía está cambiando.

## Qué pasa en este proyecto

Actualmente el proyecto tiene esta configuración en `application.properties`:

```properties
spring.jpa.hibernate.ddl-auto=create-drop
```

Eso significa que Hibernate:

- al iniciar la aplicación intenta crear el esquema con base en las entidades,
- y al cerrar la aplicación elimina ese esquema.

Esto puede servir en ambientes de aprendizaje, pruebas o prototipos rápidos, pero tiene un riesgo importante: si la base es persistente y contiene datos importantes, esos datos pueden perderse.

En este proyecto la base configurada es MySQL:

```properties
spring.datasource.url=jdbc:mysql://127.0.0.1:3306/app
```

Por eso `create-drop` debe usarse con mucho cuidado. En MySQL normalmente conviene solo si la base es desechable o si estamos en una práctica controlada.

## Cuándo usar cada valor

### `none`

Hibernate no crea, no actualiza y no valida el esquema.

Usarlo cuando:

- la base de datos se administra con scripts SQL manuales,
- el esquema lo controla otro equipo,
- se usan herramientas de migración como Flyway o Liquibase,
- no queremos que Hibernate toque la estructura de la base.

Ejemplo de escenario:

- producción con base administrada formalmente.

### `validate`

Hibernate compara las entidades con la base de datos y falla si no coinciden, pero no modifica nada.

Usarlo cuando:

- la estructura ya existe,
- queremos detectar errores de mapeo al arrancar,
- queremos seguridad sin permitir cambios automáticos.

Ejemplo de escenario:

- ambiente de pruebas, QA o producción donde el esquema ya fue creado por scripts versionados.

### `update`

Hibernate intenta ajustar el esquema existente para que coincida con las entidades.

Usarlo cuando:

- estamos en desarrollo,
- el modelo cambia con frecuencia,
- queremos conservar datos mientras agregamos columnas o tablas simples.

Ventaja:

- suele ser cómodo para avanzar rápido.

Precaución:

- no siempre resuelve cambios complejos correctamente,
- puede dejar la base en un estado distinto al esperado,
- no reemplaza migraciones controladas en producción.

Ejemplo de escenario:

- desarrollo local donde queremos mantener datos de prueba.

### `create`

Hibernate elimina el esquema anterior y lo vuelve a crear al iniciar la aplicación.

Usarlo cuando:

- no necesitamos conservar datos,
- queremos reconstruir la base desde cero en cada arranque,
- estamos haciendo pruebas iniciales del modelo.

Ejemplo de escenario:

- un prototipo corto o una práctica donde los datos pueden borrarse sin problema.

### `create-drop`

Hibernate crea el esquema al iniciar y lo elimina al cerrar la aplicación.

Usarlo cuando:

- estamos ejecutando pruebas automáticas,
- usamos una base temporal o desechable,
- estamos en laboratorio o clase y queremos empezar limpio cada vez.

Precaución principal:

- no es recomendable para una base real con datos que deban permanecer.

Ejemplo de escenario:

- pruebas con H2 en memoria o una base temporal de desarrollo.

## Recomendación práctica

Para este proyecto, una guía simple sería:

- `create-drop`: solo para prácticas controladas o pruebas donde perder datos no importa.
- `update`: mejor opción para desarrollo local si queremos conservar registros.
- `validate`: buena opción cuando el esquema ya existe y queremos verificar consistencia.
- `none`: buena opción cuando el esquema se controla por scripts o migraciones.
- `create`: útil para reiniciar todo desde cero al arrancar, pero no para conservar información.

## Conclusión

Se usa `spring.jpa.hibernate.ddl-auto` para controlar cómo Hibernate sincroniza las entidades con la base de datos.

En este momento el proyecto usa `create-drop` porque facilita avanzar rápido mientras se definen las entidades, pero como la conexión actual apunta a MySQL, más adelante podría ser más seguro cambiar a `update` para desarrollo local o a `validate` y `none` cuando el esquema ya esté controlado de forma más estable.

## Referencias oficiales

- Spring Boot Reference Documentation: https://docs.spring.io/spring-boot/docs/2.6.4/reference/html/data.html#data.sql.jpa-and-spring-data.creating-and-dropping-jpa-databases
- Hibernate User Guide, automatic schema generation: https://docs.hibernate.org/orm/5.1/userguide/html_single/appendices/Configurations.html#configurations-hbmddl
