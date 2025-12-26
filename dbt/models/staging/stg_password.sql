{{ config(materialized='view') }}

select
    rowguid,
    modifieddate,
    passwordhash,
    passwordsalt,
    businessentityid
from {{ source('raw', 'password') }}
