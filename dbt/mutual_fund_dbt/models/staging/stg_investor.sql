select
    investor_id,
    agent_id,
    investor_type,
    first_name,
    last_name,
    country_code,
    kyc_status,
    risk_rating,
    created_at,
    updated_at
from {{ source('silver', 'investor') }}

