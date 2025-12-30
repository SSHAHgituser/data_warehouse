{{ config(materialized='view') }}

select
    "Title" as title,
    "Suffix" as suffix,
    "JobTitle" as jobtitle,
    "LastName" as lastname,
    "FirstName" as firstname,
    "GroupName" as groupname,
    "StartDate" as startdate,
    "Department" as department,
    "MiddleName" as middlename,
    "BusinessEntityID" as businessentityid
from {{ source('raw_hr', 'vEmployeeDepartment') }}
