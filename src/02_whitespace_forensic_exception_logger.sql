-- ============================================================================
-- Enterprise Practice : Elsamag IT Solutions
-- Author & Consultant : Samuel Chinwendu Agu
-- Client / Ecosystem  : OmniRoute Freight Systems (Logistics & Fleet Ops)
-- Target File         : /src/02_whitespace_forensic_exception_logger.sql
-- Dialect             : Google Cloud BigQuery Standard SQL
-- Objective           : Quarantine and audit corrupted records from dispatch telemetry,
--                       measuring character padding variances and ingestion sources.
-- ============================================================================

CREATE OR REPLACE TABLE `omniroute_logistics.corrupted_whitespace_quarantine` AS
SELECT
  dispatch_id,
  shipment_tracking_num_raw,
  TRIM(shipment_tracking_num_raw) AS shipment_tracking_num_remediated,
  (LENGTH(shipment_tracking_num_raw) - LENGTH(TRIM(shipment_tracking_num_raw))) AS tracking_padding_byte_delta,
  
  driver_code_raw,
  LTRIM(driver_code_raw) AS driver_code_remediated,
  (LENGTH(driver_code_raw) - LENGTH(LTRIM(driver_code_raw))) AS driver_padding_byte_delta,
  
  destination_hub_raw,
  RTRIM(destination_hub_raw) AS destination_hub_remediated,
  (LENGTH(destination_hub_raw) - LENGTH(RTRIM(destination_hub_raw))) AS destination_padding_byte_delta,
  
  CURRENT_TIMESTAMP() AS quarantined_at
FROM
  `omniroute_logistics.telemetry_dispatch_events`
WHERE
  _TABLE_SUFFIX BETWEEN '20260801' AND '20260831'
  AND (
    LENGTH(shipment_tracking_num_raw) != LENGTH(TRIM(shipment_tracking_num_raw))
    OR LENGTH(driver_code_raw) != LENGTH(LTRIM(driver_code_raw))
    OR LENGTH(destination_hub_raw) != LENGTH(RTRIM(destination_hub_raw))
  );
