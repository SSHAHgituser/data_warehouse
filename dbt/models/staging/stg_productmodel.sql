{{ config(materialized='view') }}

select
    "Name" as name,
    "rowguid" as rowguid,
    "Instructions" as instructions,
    "ModifiedDate" as modifieddate,
    "ProductModelID" as productmodelid,
    "CatalogDescription" as catalogdescription
from {{ source('raw_production', 'ProductModel') }}
