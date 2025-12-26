{{ config(materialized='view') }}

select
    name,
    title,
    suffix,
    lastname,
    firstname,
    middlename,
    contacttype,
    phonenumber,
    emailaddress,
    emailpromotion,
    phonenumbertype,
    businessentityid
from {{ source('raw', 'vvendorwithcontacts') }}
