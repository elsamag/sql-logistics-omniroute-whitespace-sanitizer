-- ============================================================================
-- Enterprise Practice : Elsamag IT Solutions
-- Author & Consultant : Samuel Chinwendu Agu
-- Client / Ecosystem  : OmniRoute Freight Systems (Logistics & Fleet Ops)
-- Target File         : /src/03_relational_manifest_join_validator.sql
-- Dialect             : Google Cloud BigQuery Standard SQL
-- Objective           : Validate 100% deterministic foreign key alignment between
--                       sanitized dispatch events and the master freight manifest.
-- ============================================================================

WITH clean_dispatch AS (
  SELECT
    dispatch_id,
    TRIM(shipment_tracking_num_raw) AS shipment_tracking_num,
    LTRIM(driver_code_raw) AS driver_code,
    RTRIM(destination_hub_raw) AS destination_hub,
    dispatch_timestamp
  FROM
    `omniroute_logistics.telemetry_dispatch_events`
  WHERE
    _TABLE_SUFFIX BETWEEN '20260801' AND '20260831'
),

master_manifest AS (
  SELECT
    shipment_tracking_num,
    cargo_weight_kg,
    assigned_carrier,
    promised_delivery_window
  FROM
    `omniroute_logistics.master_freight_manifest`
)

SELECT
  d.dispatch_id,
  d.shipment_tracking_num,
  d.driver_code,
  d.destination_hub,
  m.cargo_weight_kg,
  m.assigned_carrier,
  m.promised_delivery_window,
  CASE 
    WHEN m.shipment_tracking_num IS NULL THEN 'ORPHAN_UNMATCHED' 
    ELSE 'MATCHED_VERIFIED' 
  END AS reconciliation_status
FROM
  clean_dispatch d
LEFT JOIN
  master_manifest m
ON
  d.shipment_tracking_num = m.shipment_tracking_num;
