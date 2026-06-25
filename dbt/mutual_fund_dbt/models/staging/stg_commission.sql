select
    commission_id,
    transaction_id,
    agent_id,
    fund_id,
    commission_date,
    commission_type,
    commission_rate,
    commission_amount,
    currency_code,
    created_at
from {{ source('silver', 'commission') }}

