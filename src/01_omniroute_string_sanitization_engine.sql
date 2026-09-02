-- ============================================================================
-- Enterprise Practice : Elsamag IT Solutions
-- Author & Consultant : Samuel Chinwendu Agu
-- Client / Ecosystem  : OmniRoute Freight Systems (Logistics & Fleet Ops)
-- Target File         : /src/01_omniroute_string_sanitization_engine.sql
-- Dialect             : Google Cloud BigQuery Standard SQL
-- Objective           : Isolate, sanitize, and normalize raw dispatch telemetry,
--                       pruning leading, trailing, and embedded perimeter whitespace
--                       to restore 100% relational foreign key join fidelity.
-- ============================================================================

WITH raw_dispatch_stream AS (
  SELECT
    dispatch_id,
    driver_code_raw,
    shipment_tracking_num_raw,
    destination_hub_raw,
    dispatch_timestamp,
    route_status
  FROM
    `omniroute_logistics.telemetry_dispatch_events`
  WHERE
    _TABLE_SUFFIX BETWEEN '20260801' AND '20260831'
),

sanitized_dispatch_layer AS (
  SELECT
    dispatch_id,
    dispatch_timestamp,
    route_status,

    -- Enforce dual-perimeter whitespace removal on primary shipment key
    TRIM(shipment_tracking_num_raw) AS shipment_tracking_num_clean,

    -- Remove fixed-width terminal leading whitespace padding on driver badge
    LTRIM(driver_code_raw) AS driver_code_clean,

    -- Remove trailing carriage returns and padded tabs on destination hub
    RTRIM(destination_hub_raw) AS destination_hub_clean,

    -- Forensic Anomaly Diagnostic Flag
    CASE 
      WHEN LENGTH(shipment_tracking_num_raw) != LENGTH(TRIM(shipment_tracking_num_raw))
        OR LENGTH(driver_code_raw) != LENGTH(LTRIM(driver_code_raw))
        OR LENGTH(destination_hub_raw) != LENGTH(RTRIM(destination_hub_raw))
      THEN 1 
      ELSE 0 
    END AS whitespace_corruption_detected
  FROM
    raw_dispatch_stream
)

SELECT
  dispatch_id,
  shipment_tracking_num_clean,
  driver_code_clean,
  destination_hub_clean,
  whitespace_corruption_detected,
  dispatch_timestamp
FROM
  sanitized_dispatch_layer
ORDER BY
  dispatch_timestamp DESC;
