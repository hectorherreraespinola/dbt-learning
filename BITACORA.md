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
