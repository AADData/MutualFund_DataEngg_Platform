select
    valuation_date,
    investor_id,
    fund_id,
    currency_code,
    sum(units) as holding_units,
    max(nav_price) as nav_price,
    sum(market_value) as market_value
from {{ ref('stg_holding') }}
group by
    valuation_date,
    investor_id,
    fund_id,
    currency_code

