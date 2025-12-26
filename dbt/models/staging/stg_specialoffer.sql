{{ config(materialized='view') }}

select
    type,
    maxqty,
    minqty,
    enddate,
    rowguid,
    category,
    startdate,
    description,
    discountpct,
    modifieddate,
    specialofferid
from {{ source('raw', 'specialoffer') }}
