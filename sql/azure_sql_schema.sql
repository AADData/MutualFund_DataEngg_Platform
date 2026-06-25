CREATE TABLE dbo.Agent (
    agent_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    agent_code VARCHAR(30) NOT NULL UNIQUE,
    agent_name NVARCHAR(200) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    country_code CHAR(2) NOT NULL,
    active_flag BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL
);

CREATE TABLE dbo.Investor (
    investor_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    agent_id INT NOT NULL,
    investor_type VARCHAR(30) NOT NULL,
    first_name NVARCHAR(100) NULL,
    last_name NVARCHAR(100) NULL,
    country_code CHAR(2) NOT NULL,
    kyc_status VARCHAR(30) NOT NULL,
    risk_rating VARCHAR(30) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL,
    CONSTRAINT fk_investor_agent FOREIGN KEY (agent_id) REFERENCES dbo.Agent(agent_id)
);

CREATE TABLE dbo.Fund (
    fund_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    fund_code VARCHAR(30) NOT NULL UNIQUE,
    fund_name NVARCHAR(200) NOT NULL,
    asset_class VARCHAR(50) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    fund_status VARCHAR(30) NOT NULL,
    launch_date DATE NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL
);

CREATE TABLE dbo.Price (
    price_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    fund_id INT NOT NULL,
    valuation_date DATE NOT NULL,
    nav_price DECIMAL(19,6) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    price_source VARCHAR(50) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_price_fund FOREIGN KEY (fund_id) REFERENCES dbo.Fund(fund_id),
    CONSTRAINT uq_price_fund_date UNIQUE (fund_id, valuation_date),
    CONSTRAINT ck_price_nav_positive CHECK (nav_price > 0)
);

CREATE TABLE dbo.[Transaction] (
    transaction_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    investor_id INT NOT NULL,
    agent_id INT NOT NULL,
    fund_id INT NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    transaction_status VARCHAR(30) NOT NULL,
    trade_date DATE NOT NULL,
    settlement_date DATE NULL,
    units DECIMAL(28,8) NOT NULL,
    price DECIMAL(19,6) NOT NULL,
    gross_amount DECIMAL(19,4) NOT NULL,
    fee_amount DECIMAL(19,4) NOT NULL DEFAULT 0,
    net_amount DECIMAL(19,4) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2 NULL,
    CONSTRAINT fk_transaction_investor FOREIGN KEY (investor_id) REFERENCES dbo.Investor(investor_id),
    CONSTRAINT fk_transaction_agent FOREIGN KEY (agent_id) REFERENCES dbo.Agent(agent_id),
    CONSTRAINT fk_transaction_fund FOREIGN KEY (fund_id) REFERENCES dbo.Fund(fund_id),
    CONSTRAINT ck_transaction_type CHECK (transaction_type IN ('SUBSCRIPTION', 'REDEMPTION', 'SWITCH_IN', 'SWITCH_OUT', 'DIVIDEND', 'FEE', 'ADJUSTMENT')),
    CONSTRAINT ck_transaction_status CHECK (transaction_status IN ('PENDING', 'SETTLED', 'REJECTED', 'CANCELLED'))
);

CREATE TABLE dbo.Holding (
    holding_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    investor_id INT NOT NULL,
    fund_id INT NOT NULL,
    valuation_date DATE NOT NULL,
    units DECIMAL(28,8) NOT NULL,
    nav_price DECIMAL(19,6) NOT NULL,
    market_value DECIMAL(19,4) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_holding_investor FOREIGN KEY (investor_id) REFERENCES dbo.Investor(investor_id),
    CONSTRAINT fk_holding_fund FOREIGN KEY (fund_id) REFERENCES dbo.Fund(fund_id),
    CONSTRAINT uq_holding_investor_fund_date UNIQUE (investor_id, fund_id, valuation_date),
    CONSTRAINT ck_holding_units_non_negative CHECK (units >= 0),
    CONSTRAINT ck_holding_nav_positive CHECK (nav_price > 0)
);

CREATE TABLE dbo.Commission (
    commission_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    agent_id INT NOT NULL,
    fund_id INT NOT NULL,
    commission_date DATE NOT NULL,
    commission_type VARCHAR(30) NOT NULL,
    commission_rate DECIMAL(9,6) NOT NULL,
    commission_amount DECIMAL(19,4) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_commission_transaction FOREIGN KEY (transaction_id) REFERENCES dbo.[Transaction](transaction_id),
    CONSTRAINT fk_commission_agent FOREIGN KEY (agent_id) REFERENCES dbo.Agent(agent_id),
    CONSTRAINT fk_commission_fund FOREIGN KEY (fund_id) REFERENCES dbo.Fund(fund_id),
    CONSTRAINT ck_commission_rate CHECK (commission_rate >= 0 AND commission_rate <= 1),
    CONSTRAINT ck_commission_amount CHECK (commission_amount >= 0)
);

CREATE TABLE dbo.Asset (
    asset_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    fund_id INT NOT NULL,
    asset_code VARCHAR(50) NOT NULL,
    asset_name NVARCHAR(200) NOT NULL,
    asset_type VARCHAR(50) NOT NULL,
    sector VARCHAR(100) NULL,
    country_code CHAR(2) NULL,
    market_value DECIMAL(19,4) NOT NULL,
    valuation_date DATE NOT NULL,
    CONSTRAINT fk_asset_fund FOREIGN KEY (fund_id) REFERENCES dbo.Fund(fund_id)
);

CREATE INDEX ix_transaction_trade_date ON dbo.[Transaction](trade_date, fund_id, agent_id);
CREATE INDEX ix_commission_date ON dbo.Commission(commission_date, agent_id, fund_id);
CREATE INDEX ix_holding_valuation_date ON dbo.Holding(valuation_date, fund_id, investor_id);
CREATE INDEX ix_price_valuation_date ON dbo.Price(valuation_date, fund_id);

