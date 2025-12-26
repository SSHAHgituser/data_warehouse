{{ config(materialized='view') }}

select
    gender,
    birthdate,
    education,
    occupation,
    yearlyincome,
    homeownerflag,
    maritalstatus,
    totalchildren,
    numbercarsowned,
    businessentityid,
    totalpurchaseytd,
    datefirstpurchase,
    numberchildrenathome
from {{ source('raw', 'vpersondemographics') }}
