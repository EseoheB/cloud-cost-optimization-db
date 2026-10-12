-- ============================================================================
-- 02_spend_trigger.sql
-- Keeps PROJECT.Current_Month_Spend in sync with metered usage.
-- Every new USAGE_EVENT row adds its Calculated_Cost to the project that owns
-- the resource, so budget alerts react to real consumption.
-- Run after 01_schema_and_seed.sql. Re-running 01 drops this trigger, so run
-- this file again after any reset.
-- ============================================================================

USE cloud_resource_management;

DROP TRIGGER IF EXISTS trg_usage_event_update_spend;

CREATE TRIGGER trg_usage_event_update_spend
AFTER INSERT ON USAGE_EVENT
FOR EACH ROW
    UPDATE PROJECT project
    INNER JOIN RESOURCE resource
        ON resource.FK_Project_ID = project.Project_ID
    SET project.Current_Month_Spend = project.Current_Month_Spend + NEW.Calculated_Cost
    WHERE resource.Resource_ID = NEW.FK_Resource_ID;
