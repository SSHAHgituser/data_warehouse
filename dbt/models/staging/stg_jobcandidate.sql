{{ config(materialized='view') }}

select
    resume,
    modifieddate,
    jobcandidateid,
    businessentityid
from {{ source('raw', 'jobcandidate') }}
