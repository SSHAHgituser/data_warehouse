{{ config(materialized='view') }}

select
    enddate,
    productid,
    startdate,
    modifieddate,
    standardcost
from {{ source('raw', 'productcosthistory') }}
