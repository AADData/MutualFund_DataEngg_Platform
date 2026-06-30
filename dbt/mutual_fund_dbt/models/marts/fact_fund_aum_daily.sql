with holding_aum as (
    select
        valuation_date,
        fund_id,
        currency_code,
        sum(market_value) as aum_amount
    from {{ ref('fact_investor_holding_daily') }}
    group by
        valuation_date,
        fund_id,
        currency_code
),

fund_price as (
    select
        fund_id,
        valuation_date,
        max(nav_price) as nav_price
    from {{ ref('stg_price') }}
    group by
        fund_id,
        valuation_date
),

asset_exposure as (
    select
        fund_id,
        valuation_date,
        asset_id,
        market_value as asset_market_value
    from {{ ref('stg_asset') }}
),

asset_weights as (
    select
        fund_id,
        valuation_date,
        asset_id,
        asset_market_value,
        asset_market_value / nullif(sum(asset_market_value) over (partition by fund_id, valuation_date), 0) as asset_weight
    from asset_exposure
)

select
    aum.valuation_date,
    aum.fund_id,
    asset.asset_id,
    aum.currency_code,
    aum.aum_amount * asset.asset_weight as aum_amount,
    price.nav_price,
    asset.asset_market_value,
    asset.asset_weight
from holding_aum as aum
left join fund_price as price
    on aum.fund_id = price.fund_id
    and aum.valuation_date = price.valuation_date
inner join asset_weights as asset
    on aum.fund_id = asset.fund_id
    and aum.valuation_date = asset.valuation_date
