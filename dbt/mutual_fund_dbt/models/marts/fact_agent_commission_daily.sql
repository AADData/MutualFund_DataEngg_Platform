select
    commission_date,
    agent_id,
    fund_id,
    commission_type,
    currency_code,
    count(*) as commission_count,
    sum(commission_amount) as commission_amount
from {{ ref('stg_commission') }}
group by
    commission_date,
    agent_id,
    fund_id,
    commission_type,
    currency_code

