{{ config(materialized='view') }}

select
    "Gender" as gender,
    "BirthDate" as birthdate,
    "Education" as education,
    "Occupation" as occupation,
    "YearlyIncome" as yearlyincome,
    "HomeOwnerFlag" as homeownerflag,
    "MaritalStatus" as maritalstatus,
    "TotalChildren" as totalchildren,
    "NumberCarsOwned" as numbercarsowned,
    "BusinessEntityID" as businessentityid,
    "TotalPurchaseYTD" as totalpurchaseytd,
    "DateFirstPurchase" as datefirstpurchase,
    "NumberChildrenAtHome" as numberchildrenathome
from {{ source('raw_sales', 'vPersonDemographics') }}
