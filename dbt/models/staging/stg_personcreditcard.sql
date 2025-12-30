{{ config(materialized='view') }}

select
    "CreditCardID" as creditcardid,
    "ModifiedDate" as modifieddate,
    "BusinessEntityID" as businessentityid
from {{ source('raw_sales', 'PersonCreditCard') }}
