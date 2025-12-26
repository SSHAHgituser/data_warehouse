{{ config(materialized='view') }}

select
    owner,
    title,
    status,
    rowguid,
    document,
    filename,
    revision,
    folderflag,
    changenumber,
    documentnode,
    modifieddate,
    fileextension,
    documentsummary
from {{ source('raw', 'document') }}
