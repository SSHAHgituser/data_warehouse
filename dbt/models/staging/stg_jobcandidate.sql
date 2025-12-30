{{ config(materialized='view') }}

select
    "Resume" as resume,
    "ModifiedDate" as modifieddate,
    "JobCandidateID" as jobcandidateid,
    "BusinessEntityID" as businessentityid
from {{ source('raw_hr', 'JobCandidate') }}
