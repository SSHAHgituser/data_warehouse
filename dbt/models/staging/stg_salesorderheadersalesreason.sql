{{ config(materialized='view') }}

select
    modifieddate,
    salesorderid,
    salesreasonid
from {{ source('raw', 'salesorderheadersalesreason') }}
