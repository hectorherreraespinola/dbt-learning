# Bitácora — Proyecto DBT

Registro de pasos del proyecto DBT desde cero hasta producción en GitHub.

---

## Paso 0 — 2026-04-25
**Inicialización del repositorio**
- Directorio creado: `/Users/hectorherreraespinola/Learning/DBT`
- `git init` ejecutado
- Bitácora creada (`BITACORA.md`)
- Próximo paso: decidir adaptador de base de datos e instalar `dbt-core`

---

## Paso 1 — 2026-04-25
**Repositorio GitHub creado y vinculado**
- Repo público creado: `https://github.com/hectorherreraespinola/dbt-learning`
- Primer commit: `feat: init proyecto DBT con bitácora`
- Branch principal: `main` — trackeando `origin/main`
- Próximo paso: instalar dbt y elegir adaptador de base de datos

---

## Paso 2 — 2026-04-25
**Perfil Snowflake configurado en `~/.dbt/profiles.yml`**
- `dbt-core 1.10.0` y `dbt-snowflake 1.10.1` ya estaban instalados
- Se agregó el perfil `Jaffle_Shop` al archivo `~/.dbt/profiles.yml`
- Autenticación: key pair (`~/.ssh/snowflake_key.p8`)
- Cuenta Snowflake: `CCGVFMG-ZJ37257`
- Usuario: `HERRERAESPINOLA` / Role: `ACCOUNTADMIN`
- Database: `ANALYTICS` / Schema: `DEV` / Warehouse: `TRANSFORMING`
- Nota: `profiles.yml` vive en `~/.dbt/` (fuera del repo) para no exponer credenciales en GitHub
- Próximo paso: `dbt init Jaffle_Shop` para crear la estructura del proyecto

---

## Paso 3 — 2026-04-25
**Conexión a Snowflake verificada con `dbt debug`**
- Proyecto `Jaffle_Shop` ya existía desde Feb 19 — no fue necesario re-inicializar
- Error encontrado: `ImportError: InvalidCatalogIntegrationConfigError` — conflicto de versiones entre `dbt-core 1.10.0` y `dbt-snowflake 1.10.1`
- Solución: `pip install --upgrade dbt-snowflake` — actualizó `dbt-core`, `dbt-adapters` y dependencias a versiones compatibles
- `dbt debug` pasó todos los checks: perfil `Jaffle_Shop`, conexión Snowflake, key pair auth — todo OK
- Próximo paso: crear primeros modelos en `models/`

---

## Paso 4 — 2026-04-26
**Primer `dbt run` ejecutado**

### ¿Qué hace `dbt run`?
`dbt run` compila todos los modelos SQL del proyecto y los ejecuta en Snowflake en el orden correcto según sus dependencias. Por cada modelo, dbt genera y ejecuta un `CREATE TABLE` o `CREATE VIEW` en la base de datos destino.

### Modelos que corrieron
dbt ejecutó los dos modelos de ejemplo incluidos en el proyecto:

1. **`my_first_dbt_model`** — materializado como `TABLE`
   - Crea una tabla sencilla con dos filas: `id = 1` e `id = null`
   - Usa `{{ config(materialized='table') }}` para indicarle a dbt que lo cree como tabla física en Snowflake

2. **`my_second_dbt_model`** — por defecto `VIEW`
   - Usa `{{ ref('my_first_dbt_model') }}` para referenciar el modelo anterior
   - `ref()` es la función clave de dbt: establece la dependencia entre modelos y garantiza el orden de ejecución
   - Filtra solo las filas donde `id = 1`

### Conceptos clave
- **Materialización**: define cómo dbt crea el objeto en la base de datos (`table`, `view`, `incremental`, `ephemeral`)
- **`ref()`**: en lugar de escribir el nombre directo de una tabla, `ref()` resuelve la dependencia y permite que dbt construya el DAG (grafo de dependencias)
- **DAG**: dbt calcula el orden de ejecución automáticamente — nunca correrá `my_second_dbt_model` antes de que `my_first_dbt_model` esté listo

- Próximo paso: explorar el `dbt_project.yml` y crear modelos propios
