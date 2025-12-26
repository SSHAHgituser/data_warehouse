{{ config(materialized='view') }}

select
    expyear,
    cardtype,
    expmonth,
    cardnumber,
    creditcardid,
    modifieddate
from {{ source('raw', 'creditcard') }}
