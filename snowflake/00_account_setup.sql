-- 00_account_setup.sql
-- One-time account-level setup notes for SnowPro Core practice.
-- Run only the commands that match your Snowflake privileges.

USE ROLE ACCOUNTADMIN;

-- Optional: create a resource monitor to control trial/certification cost.
-- Adjust the credit quota to your Snowflake trial/account comfort level.
CREATE RESOURCE MONITOR IF NOT EXISTS RM_AADDATA_DEV
  WITH CREDIT_QUOTA = 20
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 50 PERCENT DO NOTIFY
    ON 80 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND;

-- Optional: assign monitor at account level.
-- ALTER ACCOUNT SET RESOURCE_MONITOR = RM_AADDATA_DEV;

-- SnowPro notes:
-- ACCOUNTADMIN is powerful and should not be used for daily development.
-- Use ACCOUNTADMIN for initial setup, then switch to least-privilege roles.

