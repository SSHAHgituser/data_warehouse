{{ config(materialized='view') }}

select
    city,
    title,
    suffix,
    lastname,
    firstname,
    middlename,
    postalcode,
    addresstype,
    phonenumber,
    addressline1,
    addressline2,
    demographics,
    emailaddress,
    emailpromotion,
    phonenumbertype,
    businessentityid,
    countryregionname,
    stateprovincename
from {{ source('raw', 'vindividualcustomer') }}
