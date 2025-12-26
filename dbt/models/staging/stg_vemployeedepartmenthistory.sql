{{ config(materialized='view') }}

select
    shift,
    title,
    suffix,
    enddate,
    lastname,
    firstname,
    groupname,
    startdate,
    department,
    middlename,
    businessentityid
from {{ source('raw', 'vemployeedepartmenthistory') }}
