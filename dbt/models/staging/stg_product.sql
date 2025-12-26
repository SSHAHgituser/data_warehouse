{{ config(materialized='view') }}

select
    name,
    size,
    class,
    color,
    style,
    weight,
    rowguid,
    makeflag,
    listprice,
    productid,
    productline,
    sellenddate,
    modifieddate,
    reorderpoint,
    standardcost,
    productnumber,
    sellstartdate,
    productmodelid,
    discontinueddate,
    safetystocklevel,
    daystomanufacture,
    finishedgoodsflag,
    sizeunitmeasurecode,
    productsubcategoryid,
    weightunitmeasurecode
from {{ source('raw', 'product') }}
