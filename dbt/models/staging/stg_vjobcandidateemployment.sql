{{ config(materialized='view') }}

select
    "Emp_EndDate",
    "Emp_OrgName",
    "Emp_JobTitle",
    "Emp_Loc_City",
    "Emp_Loc_State",
    "Emp_StartDate",
    jobcandidateid,
    "Emp_Responsibility",
    "Emp_FunctionCategory",
    "Emp_IndustryCategory",
    "Emp_Loc_CountryRegion"
from {{ source('raw', 'vjobcandidateemployment') }}
