{{ config(materialized='view') }}

select
    "Edu_GPA" as edu_gpa,
    "Edu_Level" as edu_level,
    "Edu_Major" as edu_major,
    "Edu_Minor" as edu_minor,
    "Edu_Degree" as edu_degree,
    "Edu_School" as edu_school,
    "Edu_EndDate" as edu_enddate,
    "Edu_GPAScale" as edu_gpascale,
    "Edu_Loc_City" as edu_loc_city,
    "Edu_Loc_State" as edu_loc_state,
    "Edu_StartDate" as edu_startdate,
    "JobCandidateID" as jobcandidateid,
    "Edu_Loc_CountryRegion" as edu_loc_countryregion
from {{ source('raw_hr', 'vJobCandidateEducation') }}
