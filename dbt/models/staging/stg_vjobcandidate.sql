{{ config(materialized='view') }}

select
    "EMail",
    "Skills",
    "WebSite",
    "Addr_Type",
    "Name_Last",
    "Name_First",
    "Name_Middle",
    "Name_Prefix",
    "Name_Suffix",
    modifieddate,
    "Addr_Loc_City",
    "Addr_Loc_State",
    jobcandidateid,
    "Addr_PostalCode",
    businessentityid,
    "Addr_Loc_CountryRegion"
from {{ source('raw', 'vjobcandidate') }}
