{{ config(materialized='view') }}

select
    "Emp_EndDate" as emp_enddate,
    "Emp_OrgName" as emp_orgname,
    "Emp_JobTitle" as emp_jobtitle,
    "Emp_Loc_City" as emp_loc_city,
    "Emp_Loc_State" as emp_loc_state,
    "Emp_StartDate" as emp_startdate,
    "JobCandidateID" as jobcandidateid,
    "Emp_Responsibility" as emp_responsibility,
    "Emp_FunctionCategory" as emp_functioncategory,
    "Emp_IndustryCategory" as emp_industrycategory,
    "Emp_Loc_CountryRegion" as emp_loc_countryregion
from {{ source('raw_hr', 'vJobCandidateEmployment') }}
