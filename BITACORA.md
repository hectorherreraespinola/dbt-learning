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

---

## Paso 5 — 2026-04-26
**Materializaciones: `view` vs `table`**

### `view` (Vista)
Una vista **no almacena datos**. Es solo una consulta SQL guardada. Cada vez que alguien la consulta, Snowflake ejecuta el SQL en ese momento.

```sql
{{ config(materialized='view') }}  -- o simplemente no poner nada, es el default
```

**Cuándo usarla:**
- Modelos de staging (limpieza y renombramiento de columnas de fuentes raw)
- Modelos que se consultan poco o que no son costosos de calcular
- Cuando los datos fuente cambian constantemente y necesitas siempre los más frescos
- Capas intermedias que solo usa dbt internamente

**Desventaja:** si la consulta es compleja o la tabla fuente es grande, cada query recalcula todo desde cero — puede ser lento y costoso en Snowflake.

---

### `table` (Tabla física)
Una tabla **sí almacena datos**. dbt ejecuta el SQL y guarda el resultado como una tabla real en Snowflake. En cada `dbt run` la tabla se elimina y se recrea completa.

```sql
{{ config(materialized='table') }}
```

**Cuándo usarla:**
- Modelos que se consultan frecuentemente (dashboards, reportes)
- Transformaciones costosas que no quieres recalcular en cada consulta
- Modelos finales de la capa de marts (los que consume el negocio)

**Desventaja:** ocupa storage en Snowflake y cada `dbt run` la reconstruye completa — costoso si la tabla es muy grande.

---

### Regla general en un proyecto dbt

| Capa | Materialización recomendada |
|---|---|
| `staging` (limpieza de raw) | `view` |
| `intermediate` (lógica intermedia) | `view` o `ephemeral` |
| `marts` (producto final) | `table` |

> Existe una tercera opción importante: `incremental` — solo agrega filas nuevas en lugar de recrear toda la tabla. Se verá en pasos posteriores.

- Próximo paso: restructurar modelos con capas staging → marts

---

## Paso 6 — 2026-04-26
**Modelos actualizados y nuevo modelo `customers.sql`**

### Cambio 1 — `my_first_dbt_model.sql`: `table` → `view`
```sql
-- antes
{{ config(materialized='table') }}

-- después
{{ config(materialized='view') }}
```
**Por qué:** este modelo es solo un ejemplo con datos ficticios (`select 1 as id`). No tiene sentido gastar storage en Snowflake para datos que no son reales. Como `view` se recalcula al vuelo sin ocupar espacio.

---

### Cambio 2 — nuevo modelo `customers.sql` con referencias a staging
En lugar de leer tablas raw directamente, `customers.sql` usa `ref()` apuntando a modelos de staging:
```sql
SELECT * FROM {{ ref('stg_jaffle_shop__customer') }}
SELECT * FROM {{ ref('stg_jaffle_shop__orders') }}
```
**Por qué es importante:**
- **Nunca se referencia el raw directo** en modelos de marts — siempre se pasa por staging primero
- `ref()` le dice a dbt que `customers` depende de `stg_jaffle_shop__customer` y `stg_jaffle_shop__orders`, así dbt los construye en el orden correcto
- Si el nombre de la tabla raw cambia, solo se actualiza el staging — `customers.sql` no se toca

### Lógica del modelo `customers.sql`
Combina clientes con sus órdenes en 4 CTEs:
1. `customers` — trae todos los clientes del staging
2. `orders` — trae todas las órdenes del staging
3. `customer_orders` — agrega por cliente: primera orden, última orden, total de órdenes
4. `final` — hace un `LEFT JOIN` para que los clientes sin órdenes aparezcan con `number_of_orders = 0` (usando `COALESCE`)

- Próximo paso: crear los modelos de staging `stg_jaffle_shop__customer` y `stg_jaffle_shop__orders`

---

## Paso 7 — 2026-04-26
**Extensiones VS Code y conexión a Snowflake**

### Extensiones recomendadas para dbt + Snowflake
- **dbt Power User** (`innoverio`) — preview de modelos y CTEs, linaje visual, autocompletar `ref()`. Usa cómputo de Snowflake al ejecutar queries
  - Marketplace: https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user
- **Snowflake** (oficial) — cliente SQL directo contra Snowflake, útil para explorar datos raw
  - Marketplace: https://marketplace.visualstudio.com/items?itemName=snowflake.snowflake-vsc

### Cómputo de Snowflake
- Todo comando dbt (`run`, `debug`, `test`) y preview de modelos consume créditos del warehouse `TRANSFORMING`
- El gasto es mínimo en desarrollo si el warehouse tiene **auto-suspend** activado
- Verificar y configurar auto-suspend:
  ```sql
  SHOW WAREHOUSES LIKE 'TRANSFORMING';
  ALTER WAREHOUSE TRANSFORMING SET AUTO_SUSPEND = 60; -- apaga a los 60 seg de inactividad
  ```

### Formas de conectarse a Snowflake
| Método | URL / Comando | Cuándo usarlo |
|---|---|---|
| **Snowsight** (web) | https://app.snowflake.com | Queries rápidos, admin, revisar resultados |
| **Extensión VS Code** | Snowflake oficial en marketplace | Desarrollo diario sin salir del editor |
| **SnowSQL** (CLI) | `snowsql -a CCGVFMG-ZJ37257 -u HERRERAESPINOLA` | Automatización, scripts |

- Próximo paso: verificar auto-suspend del warehouse y estructurar capas del proyecto

---

## Paso 8 — 2026-04-26
**Comandos de selección: upstream y downstream**

En dbt el símbolo `+` controla hacia dónde viajas en el DAG (grafo de dependencias) desde el modelo seleccionado.

### Referencia del proyecto actual
```
stg_jaffle_shop__customer ─┐
                            ├──► customers
stg_jaffle_shop__orders   ─┘
```

---

### Correr solo un modelo
```bash
dbt run --select customers
```
Ejecuta únicamente `customers`. Si sus dependencias (`stg_jaffle_shop__customer`, `stg_jaffle_shop__orders`) no existen en Snowflake, el run falla.

**Cuándo usarlo:** cuando ya tienes todo el upstream construido y solo quieres recargar ese modelo.

---

### Upstream — `+` antes del modelo
```bash
dbt run --select +customers
```
Ejecuta `customers` **y todos sus ancestros** (modelos de los que depende), en orden correcto:
1. `stg_jaffle_shop__customer`
2. `stg_jaffle_shop__orders`
3. `customers`

**Cuándo usarlo:** cuando cambias la lógica de `customers` y quieres asegurarte de que todo lo que necesita esté fresco antes de correrlo.

---

### Downstream — `+` después del modelo
```bash
dbt run --select customers+
```
Ejecuta `customers` **y todos los modelos que dependen de él** (sus descendientes).

**Cuándo usarlo:** cuando cambias `customers` y quieres propagar el cambio a todos los modelos que lo consumen (reportes, marts, etc.).

---

### Upstream y downstream — `+` en ambos lados
```bash
dbt run --select +customers+
```
Ejecuta **todo el árbol completo**: ancestros + modelo + descendientes.

**Cuándo usarlo:** cuando haces un cambio estructural en un modelo del medio del DAG y quieres reconstruir todo lo relacionado.

---

### Otros selectores útiles

| Comando | Qué hace |
|---|---|
| `dbt run --select staging.*` | Todos los modelos dentro de la carpeta `staging/` |
| `dbt run --select +customers --exclude stg_jaffle_shop__orders` | Upstream de customers, excluyendo un modelo específico |
| `dbt run --select 1+customers` | Solo 1 nivel de upstream (no toda la cadena) |
| `dbt run --select customers+1` | Solo 1 nivel de downstream |
| `dbt run --select tag:daily` | Todos los modelos con el tag `daily` |

---

### Regla general
- Desarrollando un modelo nuevo → `dbt run --select +mi_modelo`
- Corrigiendo un bug en staging → `dbt run --select stg_modelo+`
- Full refresh del proyecto → `dbt run` (sin select, corre todo)

- Próximo paso: crear carpetas `staging/` y `marts/` para organizar el proyecto

---

## Paso 9 — 2026-04-26
**Convenciones de capas: staging y marts**

Un proyecto dbt bien estructurado separa los modelos en capas con responsabilidades claras. Cada capa tiene su propia carpeta dentro de `models/`.

```
models/
├── staging/          ← limpieza de datos raw
│   └── jaffle_shop/
│       ├── stg_jaffle_shop__customers.sql
│       └── stg_jaffle_shop__orders.sql
└── marts/            ← producto final para el negocio
    └── core/
        └── customers.sql
```

---

### `staging/` — Capa de limpieza
**Propósito:** tomar los datos raw exactamente como llegan de la fuente y limpiarlos. Un modelo de staging por cada tabla fuente.

**Reglas:**
- Nombre: `stg_<fuente>__<entidad>.sql` (doble guión bajo separa fuente de entidad)
- Materialización: siempre `view` — no almacena datos, solo transforma
- Solo hace limpieza básica: renombrar columnas, castear tipos, estandarizar valores
- **Nunca** hace joins ni agrega lógica de negocio
- Referencia directamente las tablas raw con `source()`

```sql
-- stg_jaffle_shop__customers.sql
select
    id          as customer_id,
    first_name,
    last_name
from {{ source('jaffle_shop', 'customers') }}
```

---

### `marts/` — Capa de negocio
**Propósito:** modelos listos para consumir por el negocio — dashboards, reportes, análisis. Aquí vive la lógica de negocio real.

**Reglas:**
- Nombre descriptivo sin prefijo: `customers.sql`, `orders.sql`, `revenue.sql`
- Materialización: `table` — se consultan frecuentemente y deben ser rápidos
- Hace joins, agregaciones y aplica lógica de negocio
- **Nunca** referencia tablas raw — solo modelos de `staging/` vía `ref()`
- Se organizan por dominio: `marts/core/`, `marts/finance/`, `marts/marketing/`

```sql
-- marts/core/customers.sql
select
    customers.customer_id,
    customers.first_name,
    customer_orders.number_of_orders
from {{ ref('stg_jaffle_shop__customers') }}
left join customer_orders using (customer_id)
```

---

### Resumen de convenciones

| | `staging/` | `marts/` |
|---|---|---|
| **Qué hace** | Limpia datos raw | Lógica de negocio |
| **Fuente** | Tablas raw (`source()`) | Modelos staging (`ref()`) |
| **Joins** | No | Sí |
| **Materialización** | `view` | `table` |
| **Naming** | `stg_fuente__entidad` | nombre del concepto de negocio |
| **Quién lo consume** | Otros modelos dbt | Dashboards, analistas, BI tools |

- Próximo paso: mover los modelos actuales a sus carpetas correspondientes y correr `dbt run`

---

## Paso 10 — 2026-04-26
**Restructuración del proyecto y actualización de `dbt_project.yml`**

### Cambios realizados

**1. Reorganización de carpetas**
```
antes:
models/
├── stg_jaffle_shop__customer.sql
├── stg_jaffle_shop__orders.sql
└── customers.sql

después:
models/
├── staging/
│   └── jaffle_shop/
│       ├── stg_jaffle_shop__customer.sql
│       └── stg_jaffle_shop__orders.sql
└── marts/
    └── dim_customers.sql
```

**2. Rename: `customers.sql` → `dim_customers.sql`**
Se agregó el prefijo `dim_` para indicar que es una tabla de dimensión (concepto de modelado dimensional). Las dimensiones describen entidades del negocio (quiénes, qué, dónde) en contraposición a las métricas (facts).

**3. `dbt_project.yml` — materialización global por carpeta**

En lugar de definir `{{ config(materialized=...) }}` en cada modelo, se configura una vez para toda la carpeta:

```yaml
models:
  Jaffle_Shop:
    staging:
      +materialized: view   # todos los modelos en staging/ → view
    marts:
      +materialized: table  # todos los modelos en marts/ → table
```

El `+` antes de `materialized` indica que la configuración aplica en cascada a todos los modelos dentro de esa carpeta y sus subcarpetas.

> **Bug corregido:** `marts` estaba mal indentado en el YAML, quedando anidado bajo `staging` en lugar de estar al mismo nivel. Esto causaría que los marts heredaran la materialización `view` en lugar de `table`.

### Por qué estructurar así
- **Un solo lugar de configuración** — cambiar la materialización de todos los stagings es editar una línea en `dbt_project.yml`, no 10 archivos
- **Convención clara** — cualquier modelo nuevo en `staging/` automáticamente hereda `view` sin configuración extra
- **Subcarpeta `jaffle_shop/`** dentro de staging permite separar múltiples fuentes de datos en el futuro (`staging/stripe/`, `staging/salesforce/`, etc.)

- Próximo paso: correr `dbt run` con la nueva estructura y verificar en Snowflake
