{{ config(materialized='view') }}

select
    creditcardid,
    modifieddate,
    businessentityid
from {{ source('raw', 'personcreditcard') }}
