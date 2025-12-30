{{ config(materialized='view') }}

select
    "Name" as name,
    "Brands" as brands,
    "BankName" as bankname,
    "Internet" as internet,
    "Specialty" as specialty,
    "SquareFeet" as squarefeet,
    "YearOpened" as yearopened,
    "AnnualSales" as annualsales,
    "BusinessType" as businesstype,
    "AnnualRevenue" as annualrevenue,
    "NumberEmployees" as numberemployees,
    "BusinessEntityID" as businessentityid
from {{ source('raw_sales', 'vStoreWithDemographics') }}
