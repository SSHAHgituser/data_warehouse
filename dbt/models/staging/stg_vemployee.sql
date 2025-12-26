{{ config(materialized='view') }}

select
    city,
    title,
    suffix,
    jobtitle,
    lastname,
    firstname,
    middlename,
    postalcode,
    phonenumber,
    addressline1,
    addressline2,
    emailaddress,
    emailpromotion,
    phonenumbertype,
    businessentityid,
    countryregionname,
    stateprovincename,
    additionalcontactinfo
from {{ source('raw', 'vemployee') }}
