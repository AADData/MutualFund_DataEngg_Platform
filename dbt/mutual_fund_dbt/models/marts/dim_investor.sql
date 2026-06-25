select
    investor_id,
    agent_id,
    investor_type,
    country_code,
    kyc_status,
    risk_rating
from {{ ref('stg_investor') }}

