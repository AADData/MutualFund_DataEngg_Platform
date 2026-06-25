select
    agent_id,
    agent_code,
    agent_name,
    channel,
    country_code,
    active_flag,
    created_at,
    updated_at
from {{ source('silver', 'agent') }}

