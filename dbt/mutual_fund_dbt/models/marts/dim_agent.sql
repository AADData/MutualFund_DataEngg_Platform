select
    agent_id,
    agent_code,
    agent_name,
    channel,
    country_code,
    active_flag
from {{ ref('stg_agent') }}

