{{ config(materialized='view') }}

select
    cultureid,
    modifieddate,
    productmodelid,
    productdescriptionid
from {{ source('raw', 'productmodelproductdescriptionculture') }}
