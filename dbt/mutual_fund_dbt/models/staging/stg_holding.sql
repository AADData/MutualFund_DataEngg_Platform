select
    holding_id,
    investor_id,
    fund_id,
    valuation_date,
    units,
    nav_price,
    market_value,
    currency_code,
    created_at
from {{ source('silver', 'holding') }}

