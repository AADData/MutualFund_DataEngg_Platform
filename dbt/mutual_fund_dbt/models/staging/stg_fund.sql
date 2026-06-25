select
    fund_id,
    fund_code,
    fund_name,
    asset_class,
    currency_code,
    fund_status,
    launch_date,
    created_at,
    updated_at
from {{ source('silver', 'fund') }}

