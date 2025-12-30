{{ config(materialized='view') }}

select
    "Name" as name,
    "Size" as size,
    "Class" as class,
    "Color" as color,
    "Style" as style,
    "Weight" as weight,
    "rowguid" as rowguid,
    "MakeFlag" as makeflag,
    "ListPrice" as listprice,
    "ProductID" as productid,
    "ProductLine" as productline,
    "SellEndDate" as sellenddate,
    "ModifiedDate" as modifieddate,
    "ReorderPoint" as reorderpoint,
    "StandardCost" as standardcost,
    "ProductNumber" as productnumber,
    "SellStartDate" as sellstartdate,
    "ProductModelID" as productmodelid,
    "DiscontinuedDate" as discontinueddate,
    "SafetyStockLevel" as safetystocklevel,
    "DaysToManufacture" as daystomanufacture,
    "FinishedGoodsFlag" as finishedgoodsflag,
    "SizeUnitMeasureCode" as sizeunitmeasurecode,
    "ProductSubcategoryID" as productsubcategoryid,
    "WeightUnitMeasureCode" as weightunitmeasurecode
from {{ source('raw_production', 'Product') }}
