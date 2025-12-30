{{ config(materialized='view') }}

select
    "PhoneNumber" as phonenumber,
    "ModifiedDate" as modifieddate,
    "BusinessEntityID" as businessentityid,
    "PhoneNumberTypeID" as phonenumbertypeid
from {{ source('raw_person', 'PersonPhone') }}
