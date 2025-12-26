{{ config(materialized='view') }}

select
    duedate,
    enddate,
    orderqty,
    productid,
    startdate,
    scrappedqty,
    workorderid,
    modifieddate,
    scrapreasonid
from {{ source('raw', 'workorder') }}
