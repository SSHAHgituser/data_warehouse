{{ config(materialized='view') }}

select
    city,
    street,
    rowguid,
    lastname,
    firstname,
    middlename,
    postalcode,
    emailaddress,
    modifieddate,
    countryregion,
    stateprovince,
    telephonenumber,
    businessentityid,
    emailtelephonenumber,
    emailspecialinstructions,
    telephonespecialinstructions,
    homeaddressspecialinstructions
from {{ source('raw', 'vadditionalcontactinfo') }}
