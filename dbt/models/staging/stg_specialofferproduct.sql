{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "ProductID" as productid,
    "ModifiedDate" as modifieddate,
    "SpecialOfferID" as specialofferid
from {{ source('raw_sales', 'SpecialOfferProduct') }}
