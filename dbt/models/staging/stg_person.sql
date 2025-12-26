{{ config(materialized='view') }}

select
    title,
    suffix,
    rowguid,
    lastname,
    firstname,
    namestyle,
    middlename,
    persontype,
    demographics,
    modifieddate,
    emailpromotion,
    businessentityid,
    additionalcontactinfo
from {{ source('raw', 'person') }}
