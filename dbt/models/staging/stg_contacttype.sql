{{ config(materialized='view') }}

select
    "Name" as name,
    "ModifiedDate" as modifieddate,
    "ContactTypeID" as contacttypeid
from {{ source('raw_person', 'ContactType') }}
