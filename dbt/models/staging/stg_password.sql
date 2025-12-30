{{ config(materialized='view') }}

select
    "rowguid" as rowguid,
    "ModifiedDate" as modifieddate,
    "PasswordHash" as passwordhash,
    "PasswordSalt" as passwordsalt,
    "BusinessEntityID" as businessentityid
from {{ source('raw_person', 'Password') }}
