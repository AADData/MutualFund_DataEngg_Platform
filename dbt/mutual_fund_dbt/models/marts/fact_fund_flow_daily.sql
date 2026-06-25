select
    trade_date,
    fund_id,
    transaction_type,
    currency_code,
    count(*) as transaction_count,
    sum(units) as units,
    sum(gross_amount) as gross_amount,
    sum(net_amount) as net_amount
from {{ ref('fact_transaction') }}
group by
    trade_date,
    fund_id,
    transaction_type,
    currency_code

