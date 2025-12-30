{{ config(materialized='view') }}

select
    "Bin" as bin,
    "Shelf" as shelf,
    "rowguid" as rowguid,
    "Quantity" as quantity,
    "ProductID" as productid,
    "LocationID" as locationid,
    "ModifiedDate" as modifieddate
from {{ source('raw_production', 'ProductInventory') }}
