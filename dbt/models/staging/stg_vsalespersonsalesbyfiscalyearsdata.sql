{{ config(materialized='view') }}

select
    fullname,
    jobtitle,
    fiscalyear,
    salestotal,
    salespersonid,
    salesterritory
from {{ source('raw', 'vsalespersonsalesbyfiscalyearsdata') }}
