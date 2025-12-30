{{ config(materialized='view') }}

select
    "CurrencyCode" as currencycode,
    "ModifiedDate" as modifieddate,
    "CountryRegionCode" as countryregioncode
from {{ source('raw_sales', 'CountryRegionCurrency') }}
