select
    transaction_id,
    investor_id,
    agent_id,
    fund_id,
    transaction_type,
    transaction_status,
    trade_date,
    settlement_date,
    units,
    price,
    gross_amount,
    fee_amount,
    net_amount,
    currency_code,
    created_at,
    updated_at
from {{ source('silver', 'transaction') }}

