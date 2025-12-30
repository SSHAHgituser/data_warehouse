{{ config(materialized='view') }}

select
    "Name" as name,
    "CultureID" as cultureid,
    "ProductID" as productid,
    "Description" as description,
    "ProductModel" as productmodel
from {{ source('raw_production', 'vProductAndDescription') }}
