{{ config(materialized='view') }}

select
    productid,
    onorderqty,
    maxorderqty,
    minorderqty,
    modifieddate,
    standardprice,
    averageleadtime,
    lastreceiptcost,
    lastreceiptdate,
    unitmeasurecode,
    businessentityid
from {{ source('raw', 'productvendor') }}
