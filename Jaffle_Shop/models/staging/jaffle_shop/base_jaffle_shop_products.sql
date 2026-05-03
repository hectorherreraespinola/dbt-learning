with source as (
        select * from {{ source('jaffle_shop', 'products') }}
  ),
  renamed as (
      select
          

      from source
  )
  select * from renamed
    