{{ config(materialized='view') }}

select
    "_2012",
    "_2013",
    "_2014",
    "FullName",
    "JobTitle",
    "SalesPersonID",
    "SalesTerritory"
from {{ source('raw', 'vsalespersonsalesbyfiscalyears') }}
