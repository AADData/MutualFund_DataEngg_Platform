select
    asset_id,
    fund_id,
    asset_code,
    asset_name,
    asset_type,
    sector,
    country_code,
    market_value,
    valuation_date
from {{ source('silver', 'asset') }}

