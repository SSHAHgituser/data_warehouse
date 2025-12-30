{{ config(materialized='view') }}

select
    "Name" as name,
    "ModifiedDate" as modifieddate,
    "PhoneNumberTypeID" as phonenumbertypeid
from {{ source('raw_person', 'PhoneNumberType') }}
