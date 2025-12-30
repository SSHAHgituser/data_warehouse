{{ config(materialized='view') }}

select
    "Name" as name,
    "GroupName" as groupname,
    "DepartmentID" as departmentid,
    "ModifiedDate" as modifieddate
from {{ source('raw_hr', 'Department') }}
