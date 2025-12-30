{{ config(materialized='view') }}

select
    "Rate" as rate,
    "ModifiedDate" as modifieddate,
    "PayFrequency" as payfrequency,
    "RateChangeDate" as ratechangedate,
    "BusinessEntityID" as businessentityid
from {{ source('raw_hr', 'EmployeePayHistory') }}
