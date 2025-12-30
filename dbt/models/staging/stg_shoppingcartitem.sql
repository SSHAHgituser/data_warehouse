{{ config(materialized='view') }}

select
    "Quantity" as quantity,
    "ProductID" as productid,
    "DateCreated" as datecreated,
    "ModifiedDate" as modifieddate,
    "ShoppingCartID" as shoppingcartid,
    "ShoppingCartItemID" as shoppingcartitemid
from {{ source('raw_sales', 'ShoppingCartItem') }}
