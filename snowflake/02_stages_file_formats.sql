-- 02_stages_file_formats.sql
-- Creates Azure storage integration placeholders, file format, and external stage.

USE ROLE ACCOUNTADMIN;

-- Option A: Recommended production-style integration for Azure external stages.
-- Replace the tenant id and storage account/container if different.
CREATE STORAGE INTEGRATION IF NOT EXISTS AZURE_AADDATA_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = AZURE
  ENABLED = TRUE
  AZURE_TENANT_ID = '<azure-tenant-id>'
  STORAGE_ALLOWED_LOCATIONS = (
    'azure://staaddatamfdev01.blob.core.windows.net/source-landing/'
  )
  COMMENT = 'Storage integration for AADData mutual fund source landing';

DESC STORAGE INTEGRATION AZURE_AADDATA_INT;

-- After running DESC, grant the generated Azure consent URL/app access in Azure.
-- Snowflake exam concept: storage integration avoids embedding SAS tokens in stages.

GRANT USAGE ON INTEGRATION AZURE_AADDATA_INT TO ROLE AADDATA_DATA_ENGINEER;

USE ROLE AADDATA_PLATFORM_ADMIN;
USE WAREHOUSE WH_AADDATA_DEV;
USE DATABASE MF_TRANS_DEV;
USE SCHEMA RAW;

CREATE FILE FORMAT IF NOT EXISTS CSV_WITH_HEADER_FF
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL', 'null')
  EMPTY_FIELD_AS_NULL = TRUE
  TRIM_SPACE = TRUE
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  COMMENT = 'CSV source files with header row';

CREATE STAGE IF NOT EXISTS AZURE_SOURCE_LANDING_STAGE
  URL = 'azure://staaddatamfdev01.blob.core.windows.net/source-landing/mutual-fund/'
  STORAGE_INTEGRATION = AZURE_AADDATA_INT
  FILE_FORMAT = CSV_WITH_HEADER_FF
  COMMENT = 'Azure Blob landing folder for mutual fund CSV files';

LIST @AZURE_SOURCE_LANDING_STAGE;

-- Option B for temporary personal testing only:
-- CREATE STAGE ... CREDENTIALS = (AZURE_SAS_TOKEN = '<sas-token>');
-- Do not commit SAS tokens to Git.

