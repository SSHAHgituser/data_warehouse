{{ config(materialized='view') }}

select
    "ExpYear" as expyear,
    "CardType" as cardtype,
    "ExpMonth" as expmonth,
    "CardNumber" as cardnumber,
    "CreditCardID" as creditcardid,
    "ModifiedDate" as modifieddate
from {{ source('raw_sales', 'CreditCard') }}
