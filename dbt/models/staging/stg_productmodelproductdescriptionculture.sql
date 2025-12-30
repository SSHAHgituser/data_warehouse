{{ config(materialized='view') }}

select
    "CultureID" as cultureid,
    "ModifiedDate" as modifieddate,
    "ProductModelID" as productmodelid,
    "ProductDescriptionID" as productdescriptionid
from {{ source('raw_production', 'ProductModelProductDescriptionCulture') }}
