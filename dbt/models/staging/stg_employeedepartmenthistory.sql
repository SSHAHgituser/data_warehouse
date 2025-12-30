{{ config(materialized='view') }}

select
    "EndDate" as enddate,
    "ShiftID" as shiftid,
    "StartDate" as startdate,
    "DepartmentID" as departmentid,
    "ModifiedDate" as modifieddate,
    "BusinessEntityID" as businessentityid
from {{ source('raw_hr', 'EmployeeDepartmentHistory') }}
