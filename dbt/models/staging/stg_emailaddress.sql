{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "EmailAddress" as emailaddress,
    "ModifiedDate" as modifieddate,
    "EmailAddressID" as emailaddressid,
    "BusinessEntityID" as businessentityid
from {{ source('raw_person', 'EmailAddress') }}
