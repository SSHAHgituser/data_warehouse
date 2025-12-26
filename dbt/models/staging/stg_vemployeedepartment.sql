{{ config(materialized='view') }}

select
    title,
    suffix,
    jobtitle,
    lastname,
    firstname,
    groupname,
    startdate,
    department,
    middlename,
    businessentityid
from {{ source('raw', 'vemployeedepartment') }}
