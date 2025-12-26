{{ config(materialized='view') }}

select
    name,
    reasontype,
    modifieddate,
    salesreasonid
from {{ source('raw', 'salesreason') }}
