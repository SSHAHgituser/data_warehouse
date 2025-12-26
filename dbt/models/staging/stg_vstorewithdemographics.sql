{{ config(materialized='view') }}

select
    name,
    "Brands",
    "BankName",
    "Internet",
    "Specialty",
    "SquareFeet",
    "YearOpened",
    "AnnualSales",
    "BusinessType",
    "AnnualRevenue",
    "NumberEmployees",
    businessentityid
from {{ source('raw', 'vstorewithdemographics') }}
