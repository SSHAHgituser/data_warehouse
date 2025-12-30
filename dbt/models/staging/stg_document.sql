{{ config(materialized='view') }}

select
    "Owner" as "owner",
    "Title" as title,
    "Status" as status,
    "rowguid" as rowguid,
    "Document" as document,
    "FileName" as filename,
    "Revision" as revision,
    "FolderFlag" as folderflag,
    "ChangeNumber" as changenumber,
    "DocumentNode" as documentnode,
    "ModifiedDate" as modifieddate,
    "DocumentLevel" as documentlevel,
    "FileExtension" as fileextension,
    "DocumentSummary" as documentsummary
from {{ source('raw_production', 'Document') }}
