{{ config(materialized='view') }}

select
    "Name" as name,
    "CurrencyCode" as currencycode,
    "ModifiedDate" as modifieddate
from {{ source('raw_sales', 'Currency') }}
