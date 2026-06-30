select
    asset_id,
    fund_id,
    asset_code,
    asset_name,
    asset_type,
    sector,
    country_code
from {{ ref('stg_asset') }}

