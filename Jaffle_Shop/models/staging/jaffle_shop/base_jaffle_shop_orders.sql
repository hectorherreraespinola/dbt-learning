with source as (
        select * from {{ source('jaffle_shop', 'orders') }}
  ),
  renamed as (
      select
          {{ adapter.quote("ID") }},
        {{ adapter.quote("USER_ID") }},
        {{ adapter.quote("ORDER_DATE") }},
        {{ adapter.quote("STATUS") }},
        {{ adapter.quote("_ETL_LOADED_AT") }}

      from source
  )
  select * from renamed
    