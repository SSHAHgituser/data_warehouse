{{ config(materialized='view') }}

select
    "Shift" as shift,
    "Title" as title,
    "Suffix" as suffix,
    "EndDate" as enddate,
    "LastName" as lastname,
    "FirstName" as firstname,
    "GroupName" as groupname,
    "StartDate" as startdate,
    "Department" as department,
    "MiddleName" as middlename,
    "BusinessEntityID" as businessentityid
from {{ source('raw_hr', 'vEmployeeDepartmentHistory') }}
