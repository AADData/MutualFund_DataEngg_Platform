with dates as (
    select trade_date as calendar_date from {{ ref('stg_transaction') }}
    union
    select settlement_date as calendar_date from {{ ref('stg_transaction') }} where settlement_date is not null
    union
    select valuation_date as calendar_date from {{ ref('stg_holding') }}
    union
    select valuation_date as calendar_date from {{ ref('stg_price') }}
    union
    select commission_date as calendar_date from {{ ref('stg_commission') }}
)

select
    cast(date_format(calendar_date, 'yyyyMMdd') as int) as date_key,
    calendar_date,
    year(calendar_date) as year_number,
    quarter(calendar_date) as quarter_number,
    month(calendar_date) as month_number,
    date_format(calendar_date, 'MMMM') as month_name,
    date_format(calendar_date, 'yyyy-MM') as financial_period
from dates
where calendar_date is not null

