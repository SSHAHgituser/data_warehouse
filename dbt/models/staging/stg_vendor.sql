{{ config(materialized='view') }}

select
    name,
    activeflag,
    creditrating,
    modifieddate,
    accountnumber,
    businessentityid,
    preferredvendorstatus,
    purchasingwebserviceurl
from {{ source('raw', 'vendor') }}
