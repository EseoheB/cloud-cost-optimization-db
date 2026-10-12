/* ============================================================================
   03_use_case_walkthrough.sql
   Cloud Resource Management and Cost Optimization System
   Author: Rabiat Blessing Ibrahim

   A five-step user journey: project setup, resource provisioning with tags,
   cost monitoring, budget alerts, and resource optimization.

   Run once on a fresh load (01 then 02). Each run inserts a new project,
   so running it repeatedly creates duplicate E-Commerce Platform projects.
   ============================================================================*/

USE cloud_resource_management;

/* ============================================================================
   STEP 1: PROJECT SETUP AND USER ACCESS
   ============================================================================
   Business Context: Finance manager creates project with budget and grants access
   Tables Joined: 4 (PROJECT, CUSTOMER_ACCOUNT, USER_ACCOUNT, PROJECT_USER_ACCESS)
*/

/* Create new project with $50,000 budget */
INSERT INTO PROJECT 
    (FK_Account_ID, FK_Project_Owner_User_ID, Project_Name, 
     Budget_Allocation, Environment_Type)
VALUES 
    (1, 2, 'E-Commerce Platform', 50000.00, 'Production');

/* Save the new project ID */
SET @project_id = LAST_INSERT_ID();

/* Grant Sarah owner access (using new project ID) */
INSERT INTO PROJECT_USER_ACCESS 
    (FK_Project_ID, FK_User_ID, Access_Level)
VALUES 
    (@project_id, 2, 'owner');

/* Verify project setup */
SELECT 
    customer.Company_Name,
    project.Project_Name,
    user.Full_Name AS Owner,
    CONCAT('$', FORMAT(project.Budget_Allocation, 2)) AS Budget,
    access.Access_Level
FROM PROJECT project
JOIN CUSTOMER_ACCOUNT customer 
    ON project.FK_Account_ID = customer.Account_ID
JOIN USER_ACCOUNT user 
    ON project.FK_Project_Owner_User_ID = user.User_ID
JOIN PROJECT_USER_ACCESS access 
    ON project.Project_ID = access.FK_Project_ID
WHERE project.Project_ID = @project_id;


/* ============================================================================
   STEP 2: RESOURCE PROVISIONING WITH TAGS
   ============================================================================
   Business Context: Cloud engineer deploys database and applies required tags
   Tables Joined: 6 (RESOURCE, RESOURCE_TYPE, REGION, RESOURCE_TAG, TAG_KEY, PROJECT)
*/

/* Deploy production database */
INSERT INTO RESOURCE 
    (FK_Project_ID, FK_Region_ID, FK_Resource_Type_Code,
     Resource_Name, Current_Status)
VALUES 
    (@project_id, 1, 'RDS_MYSQL', 'ecommerce-db-prod', 'active');

/* Save resource ID for tagging */
SET @resource_id = LAST_INSERT_ID();

/* Apply required tags */
INSERT INTO RESOURCE_TAG (FK_Resource_ID, FK_Tag_Key_ID, Tag_Value) VALUES
    (@resource_id, 1, 'Production'),
    (@resource_id, 2, 'Sarah Johnson'),
    (@resource_id, 3, 'CC-001-A');

/* View resources with compliance check */
SELECT 
    resource.Resource_Name,
    resource_type.Resource_Type_Name,
    region.Region_Name,
    resource.Current_Status,
    GROUP_CONCAT(
        CONCAT(tag_key.Tag_Key_Name, '=', resource_tag.Tag_Value)
    ) AS Tags,
    CASE 
        WHEN COUNT(CASE WHEN tag_key.Is_Required THEN 1 END) >= 3
        THEN 'Compliant' 
        ELSE 'Missing Tags' 
    END AS Compliance
FROM RESOURCE resource
JOIN RESOURCE_TYPE resource_type 
    ON resource.FK_Resource_Type_Code = resource_type.Resource_Type_Code
JOIN REGION region 
    ON resource.FK_Region_ID = region.Region_ID
LEFT JOIN RESOURCE_TAG resource_tag 
    ON resource.Resource_ID = resource_tag.FK_Resource_ID
LEFT JOIN TAG_KEY tag_key 
    ON resource_tag.FK_Tag_Key_ID = tag_key.Tag_Key_ID
WHERE resource.FK_Project_ID = @project_id
GROUP BY resource.Resource_ID, resource.Resource_Name, 
         resource_type.Resource_Type_Name, region.Region_Name, 
         resource.Current_Status;


/* ============================================================================
   STEP 3: COST MONITORING
   ============================================================================
   Business Context: System records usage events and calculates costs
   Tables Joined: 5 (PROJECT, RESOURCE, RESOURCE_TYPE, USAGE_EVENT, PRICING_TIER)
*/

/* System records usage (automated process).
   24 hours of RDS MySQL at the us-east-1 on-demand rate of $0.115/hour = $2.76.
   The trigger from 02_spend_trigger.sql adds this cost to the project's spend. */
INSERT INTO USAGE_EVENT 
    (FK_Resource_ID, FK_Pricing_Tier_ID, 
     Quantity_Consumed, Calculated_Cost)
VALUES 
    (@resource_id, 6, 24.0, 2.760);

/* Review project costs */
SELECT 
    project.Project_Name,
    resource.Resource_Name,
    resource_type.Resource_Category,
    COUNT(usage_event.Event_ID) AS Events,
    CONCAT('$', FORMAT(SUM(usage_event.Calculated_Cost), 2)) AS Cost,
    CONCAT('$', FORMAT(AVG(pricing_tier.Rate_Per_Unit), 6)) AS Rate
FROM RESOURCE resource
JOIN PROJECT project 
    ON resource.FK_Project_ID = project.Project_ID
JOIN RESOURCE_TYPE resource_type 
    ON resource.FK_Resource_Type_Code = resource_type.Resource_Type_Code
JOIN USAGE_EVENT usage_event 
    ON resource.Resource_ID = usage_event.FK_Resource_ID
JOIN PRICING_TIER pricing_tier 
    ON usage_event.FK_Pricing_Tier_ID = pricing_tier.Pricing_Tier_ID
WHERE project.Project_ID = @project_id
GROUP BY project.Project_Name, resource.Resource_Name, 
         resource_type.Resource_Category
ORDER BY SUM(usage_event.Calculated_Cost) DESC;


/* ============================================================================
   STEP 4: BUDGET ALERT CONFIGURATION
   ============================================================================
   Business Context: Finance manager sets up 80% budget alert
   Tables Joined: 5 (ALERT_RULE, PROJECT, ALERT_RECIPIENT, USER_ACCOUNT, NOTIFICATION_CHANNEL)
*/

/* Create budget alert */
INSERT INTO ALERT_RULE 
    (FK_Project_ID, Alert_Name, Threshold_Type, Threshold_Value)
VALUES 
    (@project_id, 'Budget 80% Alert', 'budget_percentage', 80.00);

/* Save alert ID */
SET @alert_id = LAST_INSERT_ID();

/* Add notification recipients */
INSERT INTO ALERT_RECIPIENT (FK_Alert_ID, FK_User_ID, FK_Channel_ID) VALUES
    (@alert_id, 2, 1),
    (@alert_id, 3, 1);

/* Monitor alert status */
SELECT 
    project.Project_Name,
    alert_rule.Alert_Name,
    CONCAT('$', FORMAT(project.Budget_Allocation, 2)) AS Budget,
    CONCAT('$', FORMAT(project.Current_Month_Spend, 2)) AS Spend,
    CONCAT(
        FORMAT((project.Current_Month_Spend / project.Budget_Allocation) * 100, 1), 
        '%'
    ) AS Budget_Used,
    CASE 
        WHEN (project.Current_Month_Spend / project.Budget_Allocation * 100) >= alert_rule.Threshold_Value
        THEN 'TRIGGERED' 
        ELSE 'HEALTHY' 
    END AS Status,
    GROUP_CONCAT(user.Full_Name) AS Recipients
FROM ALERT_RULE alert_rule
JOIN PROJECT project 
    ON alert_rule.FK_Project_ID = project.Project_ID
JOIN ALERT_RECIPIENT alert_recipient 
    ON alert_rule.Alert_ID = alert_recipient.FK_Alert_ID
JOIN USER_ACCOUNT user 
    ON alert_recipient.FK_User_ID = user.User_ID
WHERE project.Project_ID = @project_id
GROUP BY project.Project_Name, alert_rule.Alert_Name, 
         project.Budget_Allocation, project.Current_Month_Spend, 
         alert_rule.Threshold_Value;


/* ============================================================================
   STEP 5: RESOURCE OPTIMIZATION
   ============================================================================
   Business Context: Cloud engineer stops unused resource and calculates savings
   Tables Joined: 4 (RESOURCE, RESOURCE_TYPE, PROJECT, USAGE_EVENT)
*/

/* First, check what resources exist for this project */
SELECT Resource_ID, Resource_Name, Current_Status 
FROM RESOURCE 
WHERE FK_Project_ID = @project_id;

/* Stop the resource we just created in Step 2 */
UPDATE RESOURCE 
SET Current_Status = 'stopped', 
    Termination_Date = NOW()
WHERE Resource_ID = @resource_id
  AND Current_Status = 'active';

/* Calculate savings report.
   Estimated monthly savings = average daily cost while running x 30.
   GREATEST(..., 1) treats a resource stopped on its first day as one day of
   run time, so the estimate is never NULL. */
SELECT 
    resource.Resource_Name,
    resource.Current_Status,
    DATE_FORMAT(resource.Creation_Date, '%Y-%m-%d') AS Created,
    DATE_FORMAT(resource.Termination_Date, '%Y-%m-%d') AS Stopped,
    DATEDIFF(resource.Termination_Date, resource.Creation_Date) AS Days_Active,
    CONCAT('$', FORMAT(SUM(usage_event.Calculated_Cost), 2)) AS Lifetime_Cost,
    CONCAT('$', FORMAT(
        SUM(usage_event.Calculated_Cost) /
        GREATEST(DATEDIFF(resource.Termination_Date, resource.Creation_Date), 1) * 30,
        2
    )) AS Est_Monthly_Savings
FROM RESOURCE resource
JOIN RESOURCE_TYPE resource_type 
    ON resource.FK_Resource_Type_Code = resource_type.Resource_Type_Code
LEFT JOIN USAGE_EVENT usage_event 
    ON resource.Resource_ID = usage_event.FK_Resource_ID
WHERE resource.Resource_ID = @resource_id
  AND resource.Current_Status = 'stopped'
GROUP BY resource.Resource_ID, resource.Resource_Name, 
         resource.Current_Status, resource.Creation_Date, 
         resource.Termination_Date;


/* ============================================================================
   END OF USE CASE WALKTHROUGH
   ============================================================================*/