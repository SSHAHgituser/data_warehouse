{{ config(materialized='view') }}

select
    city,
    title,
    suffix,
    jobtitle,
    lastname,
    salesytd,
    firstname,
    middlename,
    postalcode,
    salesquota,
    phonenumber,
    addressline1,
    addressline2,
    emailaddress,
    saleslastyear,
    territoryname,
    emailpromotion,
    territorygroup,
    phonenumbertype,
    businessentityid,
    countryregionname,
    stateprovincename
from {{ source('raw', 'vsalesperson') }}
