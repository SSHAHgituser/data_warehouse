{{ config(materialized='view') }}

select
    rate,
    modifieddate,
    payfrequency,
    ratechangedate,
    businessentityid
from {{ source('raw', 'employeepayhistory') }}
