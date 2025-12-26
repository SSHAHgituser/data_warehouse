{{ config(materialized='view') }}

select
    "Edu_GPA",
    "Edu_Level",
    "Edu_Major",
    "Edu_Minor",
    "Edu_Degree",
    "Edu_School",
    "Edu_EndDate",
    "Edu_GPAScale",
    "Edu_Loc_City",
    "Edu_Loc_State",
    "Edu_StartDate",
    jobcandidateid,
    "Edu_Loc_CountryRegion"
from {{ source('raw', 'vjobcandidateeducation') }}
