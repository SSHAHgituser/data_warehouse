{{ config(materialized='view') }}

select
    productid,
    actualcost,
    locationid,
    plannedcost,
    workorderid,
    modifieddate,
    actualenddate,
    actualstartdate,
    scheduledenddate,
    actualresourcehrs,
    operationsequence,
    scheduledstartdate
from {{ source('raw', 'workorderrouting') }}
