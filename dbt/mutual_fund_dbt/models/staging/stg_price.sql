select
    price_id,
    fund_id,
    valuation_date,
    nav_price,
    currency_code,
    price_source,
    created_at
from {{ source('silver', 'price') }}

