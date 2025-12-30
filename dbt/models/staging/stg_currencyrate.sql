{{ config(materialized='view') }}

select
    "AverageRate" as averagerate,
    "EndOfDayRate" as endofdayrate,
    "ModifiedDate" as modifieddate,
    "CurrencyRateID" as currencyrateid,
    "ToCurrencyCode" as tocurrencycode,
    "CurrencyRateDate" as currencyratedate,
    "FromCurrencyCode" as fromcurrencycode
from {{ source('raw_sales', 'CurrencyRate') }}
