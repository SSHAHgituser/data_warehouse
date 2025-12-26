{{ config(materialized='view') }}

select
    averagerate,
    endofdayrate,
    modifieddate,
    currencyrateid,
    tocurrencycode,
    currencyratedate,
    fromcurrencycode
from {{ source('raw', 'currencyrate') }}
