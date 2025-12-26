{{ config(materialized='view') }}

select
    productid,
    documentnode,
    modifieddate
from {{ source('raw', 'productdocument') }}
